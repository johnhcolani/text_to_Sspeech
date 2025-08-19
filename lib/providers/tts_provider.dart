import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:async';

import '../services/database_service.dart';
import 'package:uuid/uuid.dart';
import 'package:just_audio/just_audio.dart';

enum TTSState { playing, stopped, paused, continued }

class TTSProvider extends ChangeNotifier {
  // ---------- Private variables ----------
  late final FlutterTts _tts;
  late final DatabaseService _databaseService;
  late final AudioPlayer _audioPlayer;

  // TTS state
  TTSState _ttsState = TTSState.stopped;

  // Error handling
  String? _lastError;
  bool _hasError = false;

  // Text + file
  String _text = '';
  String _fileName = '';
  bool _isLoading = false;

  // Progress tracking - now properly implemented
  int _progressStart = 0; // current char start (inclusive)
  int _progressEnd = 0; // current char end (exclusive)
  String _progressWord = '';
  bool _progressActive = false;
  double _progressPercentage = 0.0;

  // Word highlighting system
  List<String> _words = [];
  List<int> _wordStartPositions = [];
  int _currentWordIndex = 0;
  Timer? _wordHighlightTimer;
  bool _wordHighlightingActive = false;

  // Timing adjustment for better speech sync
  double _timingOffset = 0.8; // Optimized timing offset

  // Better timing system - track actual speech progress
  DateTime? _speechStartTime;
  int _totalWords = 0;

  // Dynamic timing adjustment for better speech sync
  double _actualSpeechDuration = 0.0; // Actual speech duration in milliseconds

  // Speech progress tracking
  double _currentSpeechProgress = 0.0;

  int get progressStart => _progressStart;
  int get progressEnd => _progressEnd;
  String get progressWord => _progressWord;
  bool get progressActive => _progressActive;
  double get progressPercentage => _progressPercentage;

  // Word highlighting getters
  List<String> get words => _words;
  int get currentWordIndex => _currentWordIndex;
  bool get wordHighlightingActive => _wordHighlightingActive;
  double get timingOffset => _timingOffset;

  // Error getters
  String? get lastError => _lastError;
  bool get hasError => _hasError;

  // Voice settings
  double _rate = 0.5; // speaking rate
  double _pitch = 1.0;
  double _volume = 1.0;
  String _selectedLanguage = 'en-US';
  String _selectedVoice = ''; // voice 'name' from getVoices
  List<Map<String, String>> _voices = [];

  // Getters
  String get text => _text;
  String get fileName => _fileName;
  bool get isLoading => _isLoading;
  TTSState get ttsState => _ttsState;

  // Expose settings consistently
  double get rate => _rate;
  double get pitch => _pitch;
  double get volume => _volume;
  String get selectedLanguage => _selectedLanguage;
  String get selectedVoice => _selectedVoice; // <-- this is the "voiceId"
  int get currentLineIndex {
    final s = _text;
    if (s.isEmpty) return 0;
    final start = _progressStart.clamp(0, s.length);
    // Count '\n' before start
    int lines = 0;
    for (int i = 0; i < start; i++) {
      if (s.codeUnitAt(i) == 10) lines++; // 10 == '\n'
    }
    return lines;
  }

  // Voices
  List<Map<String, String>> get voices => _voices;

  TTSProvider() {
    _tts = FlutterTts();
    _databaseService = DatabaseService();
    _audioPlayer = AudioPlayer();

    // Don't call async methods in constructor
    // _initTTS();
    // _loadSettingsFromDatabase();
  }

  // Initialize TTS after construction
  Future<void> initialize() async {
    await _initTTS();
    await _loadSettingsFromDatabase();
  }

  // ---------- Word highlighting system ----------
  void _initializeWordTracking() {
    _words.clear();
    _wordStartPositions.clear();
    _currentWordIndex = 0;

    if (_text.isEmpty) return;

    // Split text into words and track their positions
    final text = _text;
    final wordPattern = RegExp(r'\b\w+\b');
    final matches = wordPattern.allMatches(text);

    for (final match in matches) {
      _words.add(match.group(0)!);
      _wordStartPositions.add(match.start);
    }
  }

  void _startWordHighlighting() {
    if (_words.isEmpty) return;

    _wordHighlightingActive = true;
    _currentWordIndex = 0;
    _totalWords = _words.length;
    _speechStartTime = DateTime.now();
    _currentSpeechProgress = 0.0;

    // Estimate initial speech duration based on text length and rate
    _estimateSpeechDuration();

    _updateWordProgress();

    // Use much faster timer for smoother word highlighting (every 16ms = 60fps)
    _wordHighlightTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) {
      if (_ttsState == TTSState.playing && _speechStartTime != null) {
        _updateWordProgressBasedOnActualSpeech();

        // Adjust timing dynamically every 100ms for better accuracy
        if (timer.tick % 6 == 0) {
          // Every ~100ms (6 * 16ms)
          adjustTimingDynamically();
        }
      } else {
        timer.cancel();
        _wordHighlightingActive = false;
        _currentWordIndex = 0;
        _speechStartTime = null;
        _currentSpeechProgress = 0.0;
        notifyListeners();
      }
    });
  }

  void _estimateSpeechDuration() {
    // More accurate speech duration estimation
    // Consider text length, speech rate, and language characteristics
    final textLength = _text.length;
    final wordsCount = _words.length;

    // More accurate base times based on research
    final baseTimePerChar = 40.0; // milliseconds per character (optimized)
    final baseTimePerWord = 250.0; // milliseconds per word (optimized)

    // Account for speech rate more accurately
    final rateMultiplier = 1.0 / _rate; // Inverse relationship

    // Calculate duration considering both character and word count
    final charBasedDuration = textLength * baseTimePerChar * rateMultiplier;
    final wordBasedDuration = wordsCount * baseTimePerWord * rateMultiplier;

    // Use weighted average for more accurate estimation
    // Words are more reliable than characters for timing
    _actualSpeechDuration = (charBasedDuration * 0.3 + wordBasedDuration * 0.7);

    debugPrint(
      'Estimated speech duration: ${_actualSpeechDuration}ms (${_actualSpeechDuration / 1000}s)',
    );
  }

  void _updateWordProgressBasedOnActualSpeech() {
    if (_speechStartTime == null ||
        _words.isEmpty ||
        _actualSpeechDuration <= 0)
      return;

    final elapsed = DateTime.now().difference(_speechStartTime!).inMilliseconds;

    // Calculate actual speech progress (0.0 to 1.0)
    _currentSpeechProgress = (elapsed / _actualSpeechDuration).clamp(0.0, 1.0);

    // Calculate target word index based on actual progress
    final targetWordIndex = (_currentSpeechProgress * _totalWords).round();

    // Ensure we don't go beyond the word count
    final newWordIndex = targetWordIndex.clamp(0, _words.length - 1);

    // Allow smaller jumps for more responsive highlighting
    final maxJump = (_totalWords * 0.02).round().clamp(
      1,
      2,
    ); // Max 2% jump or 2 words

    if ((newWordIndex - _currentWordIndex).abs() > maxJump) {
      // If the jump is too big, limit it to prevent runaway progression
      final limitedJump = newWordIndex > _currentWordIndex
          ? _currentWordIndex + maxJump
          : _currentWordIndex - maxJump;
      _currentWordIndex = limitedJump.clamp(0, _words.length - 1);
    } else {
      _currentWordIndex = newWordIndex;
    }

    // Update progress percentage based on actual speech progress
    _progressPercentage = _currentSpeechProgress;

    _updateWordProgress();
  }

  void _stopWordHighlighting() {
    _wordHighlightTimer?.cancel();
    _wordHighlightingActive = false;
    _currentWordIndex = 0;
    _speechStartTime = null;
    _currentSpeechProgress = 0.0;
    _actualSpeechDuration = 0.0;
    _updateWordProgress();
  }

  void _updateWordProgress() {
    if (_currentWordIndex < _words.length &&
        _currentWordIndex < _wordStartPositions.length) {
      final word = _words[_currentWordIndex];
      final startPos = _wordStartPositions[_currentWordIndex];
      final endPos = startPos + word.length;

      _progressStart = startPos;
      _progressEnd = endPos;
      _progressWord = word;
      _progressActive = true;

      // Calculate progress percentage based on actual speech progress when available
      if (_actualSpeechDuration > 0 && _speechStartTime != null) {
        final elapsed = DateTime.now()
            .difference(_speechStartTime!)
            .inMilliseconds;
        _progressPercentage = (elapsed / _actualSpeechDuration).clamp(0.0, 1.0);
      } else if (_text.isNotEmpty) {
        // Fallback to character-based progress
        _progressPercentage = (endPos / _text.length).clamp(0.0, 1.0);
      }

      notifyListeners();
    }
  }

  // ---------- Error handling ----------
  void _setError(String error) {
    _lastError = error;
    _hasError = true;
    notifyListeners();
  }

  void _clearError() {
    _lastError = null;
    _hasError = false;
    notifyListeners();
  }

  // ---------- Progress tracking ----------
  void _updateProgress(int start, int end, String word) {
    _progressStart = start;
    _progressEnd = end;
    _progressWord = word;
    _progressActive = true;

    // Calculate progress percentage
    if (_text.isNotEmpty) {
      _progressPercentage = (end / _text.length).clamp(0.0, 1.0);
    }

    notifyListeners();
  }

  void _resetProgress() {
    _progressStart = 0;
    _progressEnd = 0;
    _progressWord = '';
    _progressActive = false;
    _progressPercentage = 0.0;
    _speechStartTime = null;
    _currentSpeechProgress = 0.0;
    _actualSpeechDuration = 0.0;
    _stopWordHighlighting();
    notifyListeners();
  }

  // ---------- Public methods for external control ----------

  /// Reset progress to beginning (public method)
  void resetProgress() {
    _resetProgress();
  }

  // ---------- Initialization ----------
  Future<void> _initTTS() async {
    try {
      _clearError();
      await _tts.setLanguage(_selectedLanguage);
      await _tts.setSpeechRate(_rate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);
      await _tts.awaitSpeakCompletion(
        true,
      ); // important for consistent callbacks

      // Event handlers
      _tts.setStartHandler(() {
        // Only update state if we're not already playing (prevents conflicts with immediate state setting)
        if (_ttsState != TTSState.playing) {
          _ttsState = TTSState.playing;
          _progressActive = true;
          _clearError();
          _startWordHighlighting();
          notifyListeners();
        }
      });
      _tts.setCompletionHandler(() {
        _ttsState = TTSState.stopped;
        _progressActive = false;
        _resetProgress();
        notifyListeners();
      });
      _tts.setCancelHandler(() {
        _ttsState = TTSState.stopped;
        _progressActive = false;
        _resetProgress();
        notifyListeners();
      });
      _tts.setPauseHandler(() {
        _ttsState = TTSState.paused;
        _stopWordHighlighting();
        notifyListeners();
      });
      _tts.setContinueHandler(() {
        _ttsState = TTSState.playing; // Changed from continued to playing
        _startWordHighlighting();
        notifyListeners();
      });

      await _loadVoices();
      // Pick a default voice matching language if possible
      _autoPickVoiceForLanguage();
    } catch (e) {
      _setError('Failed to initialize TTS: ${e.toString()}');
      debugPrint('Error initializing TTS: $e');
    }
  }

  // Load settings from database
  Future<void> _loadSettingsFromDatabase() async {
    try {
      final language = await _databaseService.getSetting('selectedLanguage');
      if (language != null) {
        _selectedLanguage = language;
      }

      final voice = await _databaseService.getSetting('selectedVoice');
      if (voice != null) {
        _selectedVoice = voice;
      }

      final rateStr = await _databaseService.getSetting('rate');
      if (rateStr != null) {
        _rate = double.tryParse(rateStr) ?? 0.5;
      }

      final pitchStr = await _databaseService.getSetting('pitch');
      if (pitchStr != null) {
        _pitch = double.tryParse(pitchStr) ?? 1.0;
      }

      final volumeStr = await _databaseService.getSetting('volume');
      if (volumeStr != null) {
        _volume = double.tryParse(volumeStr) ?? 1.0;
      }

      final timingOffsetStr = await _databaseService.getSetting('timingOffset');
      if (timingOffsetStr != null) {
        _timingOffset = double.tryParse(timingOffsetStr) ?? 0.8;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings from database: $e');
    }
  }

  Future<void> _loadVoices() async {
    try {
      final available = await _tts.getVoices;
      if (available is List) {
        _voices = available
            .whereType<Map>()
            .map(
              (m) =>
                  m.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
            )
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading voices: $e');
      // Don't set error for voice loading as it's not critical
    }
  }

  void _autoPickVoiceForLanguage() {
    try {
      // Try to select the first voice whose locale starts with selectedLanguage
      // or just keep existing selection if already valid.
      if (_selectedVoice.isNotEmpty) {
        final stillValid = _voices.any((v) => v['name'] == _selectedVoice);
        if (stillValid) return;
      }

      final match = _voices.firstWhere(
        (v) => (v['locale'] ?? '').toLowerCase().startsWith(
          _selectedLanguage.toLowerCase(),
        ),
        orElse: () => _voices.isNotEmpty ? _voices.first : <String, String>{},
      );

      if (match.isNotEmpty) {
        _selectedVoice = match['name'] ?? '';
        // Apply it
        _applyVoice();
      }
    } catch (e) {
      debugPrint('Error auto-picking voice: $e');
    }
  }

  Future<void> _applyVoice() async {
    if (_selectedVoice.isEmpty) return;

    try {
      // flutter_tts expects a map with at least name + locale on some platforms
      final voice = _voices.firstWhere(
        (v) => v['name'] == _selectedVoice,
        orElse: () => <String, String>{},
      );
      final locale = voice['locale'] ?? _selectedLanguage;
      await _tts.setVoice({"name": _selectedVoice, "locale": locale});
    } catch (e) {
      debugPrint('Error applying voice: $e');
      _setError('Failed to apply voice: ${e.toString()}');
    }
  }

  // ---------- Settings setters ----------
  Future<void> setText(String value) async {
    _text = value;
    _initializeWordTracking();
    notifyListeners();
  }

  Future<void> setRate(double value) async {
    _rate = value.clamp(0.1, 1.0);
    await _databaseService.setSetting('rate', _rate.toString());
    await _tts.setSpeechRate(_rate);
    notifyListeners();
  }

  Future<void> setPitch(double value) async {
    _pitch = value.clamp(0.5, 2.0);
    await _databaseService.setSetting('pitch', _pitch.toString());
    await _tts.setPitch(_pitch);
    notifyListeners();
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);
    await _databaseService.setSetting('volume', _volume.toString());
    await _tts.setVolume(_volume);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _selectedLanguage = value;
    await _databaseService.setSetting('selectedLanguage', _selectedLanguage);
    await _tts.setLanguage(_selectedLanguage);
    _autoPickVoiceForLanguage();
    notifyListeners();
  }

  Future<void> setVoice(String value) async {
    _selectedVoice = value;
    await _databaseService.setSetting('selectedVoice', _selectedVoice);
    await _applyVoice();
    notifyListeners();
  }

  Future<void> adjustTimingOffset(double value) async {
    _timingOffset = value.clamp(0.0, 2.0);
    await _databaseService.setSetting('timingOffset', _timingOffset.toString());
    notifyListeners();
  }

  // ---------- Voice management ----------
  /// Refreshes the available voices list
  Future<void> refreshVoices() async {
    try {
      await _loadVoices();
      // Try to keep the current selection if it's still valid
      if (_selectedVoice.isNotEmpty) {
        final stillValid = _voices.any((v) => v['name'] == _selectedVoice);
        if (!stillValid && _voices.isNotEmpty) {
          // Current voice is no longer valid, pick a new one
          _autoPickVoiceForLanguage();
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing voices: $e');
    }
  }

  /// Gets a list of available voices for a specific language
  List<Map<String, String>> getVoicesForLanguage(String language) {
    return _voices
        .where(
          (v) => (v['locale'] ?? '').toLowerCase().startsWith(
            language.toLowerCase(),
          ),
        )
        .toList();
  }

  /// Gets a list of all available languages from the voices
  List<String> get availableLanguages {
    final languages = <String>{};
    for (final voice in _voices) {
      final locale = voice['locale'];
      if (locale != null && locale.isNotEmpty) {
        // Extract language code (e.g., "en-US" -> "en")
        final languageCode = locale.split('-')[0];
        languages.add(languageCode);
      }
    }
    return languages.toList()..sort();
  }

  // ---------- Dynamic timing adjustment ----------
  /// Dynamically adjusts timing based on actual speech progress
  void adjustTimingDynamically() {
    if (!_wordHighlightingActive || _speechStartTime == null) return;

    final elapsed = DateTime.now().difference(_speechStartTime!).inMilliseconds;
    final currentProgress = elapsed / _actualSpeechDuration;

    // If we're ahead of schedule, slow down
    if (_currentSpeechProgress > currentProgress + 0.1) {
      _timingOffset = (_timingOffset * 0.95).clamp(0.3, 2.0);
      debugPrint('Slowing down timing: $_timingOffset');
    }
    // If we're behind schedule, speed up
    else if (_currentSpeechProgress < currentProgress - 0.1) {
      _timingOffset = (_timingOffset * 1.05).clamp(0.3, 2.0);
      debugPrint('Speeding up timing: $_timingOffset');
    }
  }

  // ---------- Word highlighting timing adjustment ----------
  // This method is now handled by the async version that saves to database

  // ---------- Speak / Stop / Pause / Resume ----------
  Future<void> speak() async {
    final toSay = _text.trim();
    if (toSay.isEmpty) {
      _setError('No text to speak');
      debugPrint('TTS: No text to speak');
      return;
    }

    try {
      _clearError();
      debugPrint(
        'TTS: Starting to speak: "${toSay.substring(0, toSay.length > 50 ? 50 : toSay.length)}..."',
      );
      await _applyVoice(); // ensure voice is set
      await _tts.setSpeechRate(_rate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);

      // Set state to playing immediately so UI shows pause button right away
      _ttsState = TTSState.playing;
      _progressActive = true;
      _startWordHighlighting();
      notifyListeners();

      debugPrint('TTS: Calling flutter_tts.speak()');
      await _tts.speak(toSay);
      debugPrint('TTS: speak() called successfully');
    } catch (e) {
      _setError('Failed to start speech: ${e.toString()}');
      debugPrint('Error speaking: $e');
      // Reset state on error
      _ttsState = TTSState.stopped;
      _progressActive = false;
      _stopWordHighlighting();
      notifyListeners();
    }
  }

  // Convenience if you want to speak arbitrary text
  Future<void> playText(String value) async {
    final toSay = value.trim();
    if (toSay.isEmpty) return;

    try {
      _clearError();
      await _applyVoice();
      await _tts.setSpeechRate(_rate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);

      // Set state to playing immediately so UI shows pause button right away
      _ttsState = TTSState.playing;
      _progressActive = true;
      _startWordHighlighting();
      notifyListeners();

      await _tts.speak(toSay);
    } catch (e) {
      _setError('Failed to speak text: ${e.toString()}');
      debugPrint('Error speaking (playText): $e');
      // Reset state on error
      _ttsState = TTSState.stopped;
      _progressActive = false;
      _stopWordHighlighting();
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
      // Update state to stopped
      _ttsState = TTSState.stopped;
      _progressActive = false;
      _stopWordHighlighting();
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping: $e');
    }
  }

  Future<void> pause() async {
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        await _tts.pause(); // supported on Apple platforms
        // State will be updated by the pause handler
      } else {
        await _tts.stop(); // Android: no real pause → stop instead
        // Update state to stopped since we can't pause on Android
        _ttsState = TTSState.stopped;
        _progressActive = false;
        _stopWordHighlighting();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error pausing: $e');
    }
  }

  Future<void> resume() async {
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        // Try to use continueSpeak if available
        try {
          final dynamic tts = _tts;
          await tts.continueSpeak();
          // State will be updated by the continue handler
        } catch (e) {
          debugPrint(
            'continueSpeak not available, falling back to restart: $e',
          );
          // Fallback: restart from the beginning
          if (_text.isNotEmpty) {
            await speak();
          }
        }
      } else {
        // Android: no resume; restart from the beginning
        if (_text.isNotEmpty) {
          await speak();
        }
      }
    } catch (e) {
      // Fallback if continueSpeak() isn't available/throws
      debugPrint('Error resuming: $e');
      if (_text.isNotEmpty) {
        await speak();
      }
    }
  }

  // ---------- Play saved audio file with high quality ----------
  Future<void> playSavedAudio(String filePath) async {
    try {
      _clearError();
      _ttsState = TTSState.playing;
      _progressActive = true;
      _startWordHighlighting();
      notifyListeners();

      // Use the high-quality audio player for saved files
      await _audioPlayer.setFilePath(filePath);
      await _audioPlayer.play();

      // Listen for completion
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _ttsState = TTSState.stopped;
          _progressActive = false;
          _resetProgress();
          notifyListeners();
        }
      });
    } catch (e) {
      _setError('Failed to play saved audio: ${e.toString()}');
      debugPrint('Error playing saved audio: $e');
      _ttsState = TTSState.stopped;
      _progressActive = false;
      _resetProgress();
      notifyListeners();
    }
  }

  Future<void> pauseSavedAudio() async {
    try {
      await _audioPlayer.pause();
      _ttsState = TTSState.paused;
      _stopWordHighlighting();
      notifyListeners();
    } catch (e) {
      debugPrint('Error pausing saved audio: $e');
    }
  }

  Future<void> resumeSavedAudio() async {
    try {
      await _audioPlayer.play();
      _ttsState = TTSState.continued;
      _startWordHighlighting();
      notifyListeners();
    } catch (e) {
      debugPrint('Error resuming saved audio: $e');
    }
  }

  Future<void> stopSavedAudio() async {
    try {
      await _audioPlayer.stop();
      _ttsState = TTSState.stopped;
      _progressActive = false;
      _resetProgress();
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping saved audio: $e');
    }
  }

  // Check if we're playing saved audio
  bool get isPlayingSavedAudio => _audioPlayer.playing;

  // ---------- Check device capabilities ----------
  /// Checks if the current device supports audio file synthesis
  Future<bool> isFileSynthesisSupported() async {
    try {
      // Check if the TTS engine supports file synthesis
      final engines = await _tts.getEngines;
      return engines.isNotEmpty;
    } catch (e) {
      debugPrint('File synthesis check failed: $e');
      return false;
    }
  }

  // ---------- Smart offline detection and MP3 fallback ----------
  bool _isOffline = false;
  String? _lastGeneratedMP3Path;

  /// Check if device is offline and should use MP3 files
  Future<bool> _checkOfflineStatus() async {
    try {
      // Try to access a simple online resource
      final result = await InternetAddress.lookup('google.com');
      _isOffline = result.isEmpty;
    } catch (e) {
      _isOffline = true;
    }

    debugPrint('TTS: Offline status: $_isOffline');
    return _isOffline;
  }

  /// Smart speak method that automatically uses MP3 when offline
  Future<void> speakSmart() async {
    final isOffline = await _checkOfflineStatus();

    if (isOffline) {
      debugPrint('TTS: Offline detected, using MP3 fallback');
      await _speakWithMP3Fallback();
    } else {
      debugPrint('TTS: Online, using real-time TTS');
      await speak();
    }
  }

  /// Speak with automatic MP3 generation and playback
  Future<void> _speakWithMP3Fallback() async {
    try {
      _clearError();
      _ttsState = TTSState.stopped;
      notifyListeners();

      // Generate or reuse MP3 file
      String? mp3Path = _lastGeneratedMP3Path;

      if (mp3Path == null || !await File(mp3Path).exists()) {
        debugPrint('TTS: Generating new MP3 file for offline playback');
        mp3Path = await synthesizeToFileHighQuality();
        if (mp3Path != null) {
          _lastGeneratedMP3Path = mp3Path;
        }
      }

      if (mp3Path != null) {
        debugPrint('TTS: Playing MP3 file: $mp3Path');
        await playSavedAudio(mp3Path);
      } else {
        _setError('Failed to generate MP3 for offline playback');
        _ttsState = TTSState.stopped;
        notifyListeners();
      }
    } catch (e) {
      _setError('MP3 fallback failed: ${e.toString()}');
      _ttsState = TTSState.stopped;
      notifyListeners();
    }
  }

  /// Enhanced MP3 synthesis with better quality settings
  Future<String?> synthesizeToFileHighQuality() async {
    final content = _text.trim();
    if (content.isEmpty) {
      _setError('No text to synthesize to file');
      debugPrint('TTS: No text to synthesize to file');
      return null;
    }

    try {
      _clearError();
      debugPrint(
        'TTS: Attempting high-quality MP3 synthesis: "${content.substring(0, content.length > 50 ? 50 : content.length)}..."',
      );

      // Apply optimal settings for car audio and offline playback
      await _applyVoice();
      await _tts.setSpeechRate(_rate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);

      final dir = await getApplicationDocumentsDirectory();
      final id = const Uuid().v4();
      final fileNameOnly = 'tts_hq_$id.mp3';
      final fullPath = p.join(dir.path, fileNameOnly);

      // Enhanced MP3 synthesis with multiple fallback strategies
      String? resultPath;

      // Strategy 1: Direct MP3 synthesis (highest quality)
      try {
        debugPrint('TTS: Attempting direct MP3 synthesis...');
        await _tts.synthesizeToFile(content, fullPath);
        if (await File(fullPath).exists()) {
          resultPath = await _verifyAndOptimizeMP3File(fullPath);
          if (resultPath != null) {
            debugPrint('TTS: Direct MP3 synthesis successful');
            return resultPath;
          }
        }
      } catch (e) {
        debugPrint('Direct MP3 synthesis failed: $e');
      }

      // Strategy 2: WAV synthesis with conversion (fallback)
      if (resultPath == null) {
        try {
          debugPrint('TTS: Attempting WAV synthesis with MP3 conversion...');
          final wavFileName = 'tts_hq_$id.wav';
          final wavPath = p.join(dir.path, wavFileName);

          await _tts.synthesizeToFile(content, wavPath);

          if (await File(wavPath).exists()) {
            // Convert WAV to MP3 using platform-specific methods
            final mp3Path = await _convertWavToMp3(wavPath, fullPath);
            if (mp3Path != null) {
              resultPath = await _verifyAndOptimizeMP3File(mp3Path);
            }

            // Clean up WAV file
            await File(wavPath).delete();
          }
        } catch (e) {
          debugPrint('WAV to MP3 conversion failed: $e');
        }
      }

      // Strategy 3: Use WAV directly if MP3 conversion fails
      if (resultPath == null) {
        try {
          debugPrint('TTS: Falling back to WAV format...');
          final wavFileName = 'tts_hq_$id.wav';
          final wavPath = p.join(dir.path, wavFileName);

          await _tts.synthesizeToFile(content, wavPath);

          if (await File(wavPath).exists()) {
            resultPath = await _verifyAndOptimizeWavFile(wavPath);
          }
        } catch (e) {
          debugPrint('WAV fallback failed: $e');
        }
      }

      if (resultPath != null) {
        debugPrint('TTS: High-quality synthesis successful: $resultPath');
        return resultPath;
      }

      _setError('High-quality audio export not supported on this device');
      return null;
    } catch (e) {
      _setError('Failed to export high-quality audio: ${e.toString()}');
      debugPrint('synthesizeToFileHighQuality failed: $e');
      return null;
    }
  }

  /// Convert WAV to MP3 using platform-specific methods
  Future<String?> _convertWavToMp3(String wavPath, String mp3Path) async {
    try {
      if (Platform.isAndroid) {
        // On Android, try to use the WAV file directly as MP3
        // Many Android TTS engines actually output MP3 even with .wav extension
        final wavFile = File(wavPath);
        final mp3File = File(mp3Path);

        if (await wavFile.exists()) {
          await wavFile.copy(mp3Path);
          if (await mp3File.exists()) {
            debugPrint('TTS: WAV copied as MP3 on Android');
            return mp3Path;
          }
        }
      } else if (Platform.isIOS) {
        // On iOS, WAV files are often high quality and can be used directly
        // Rename the extension to .mp3 for consistency
        final wavFile = File(wavPath);
        final mp3File = File(mp3Path);

        if (await wavFile.exists()) {
          await wavFile.copy(mp3Path);
          if (await mp3File.exists()) {
            debugPrint('TTS: WAV copied as MP3 on iOS');
            return mp3Path;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('WAV to MP3 conversion failed: $e');
      return null;
    }
  }

  /// Enhanced MP3 file verification
  Future<String?> _verifyAndOptimizeMP3File(String filePath) async {
    try {
      final file = File(filePath);
      final size = await file.length();

      // MP3 files should be substantial for good quality
      if (size < 4096) {
        // Increased minimum size for MP3
        debugPrint('MP3 file too small for high quality: ${size} bytes');
        return null;
      }

      // Check if file has valid audio content
      final bytes = await file.readAsBytes();
      if (bytes.length < 10 || bytes[0] != 0xFF || (bytes[1] & 0xE0) != 0xE0) {
        debugPrint('File does not appear to be valid MP3');
        return null;
      }

      debugPrint('High-quality MP3 file verified: $filePath (${size} bytes)');
      return filePath;
    } catch (e) {
      debugPrint('MP3 file verification failed: $e');
      return null;
    }
  }

  /// Enhanced WAV file verification
  Future<String?> _verifyAndOptimizeWavFile(String filePath) async {
    try {
      final file = File(filePath);
      final size = await file.length();

      // WAV files should be substantial for good quality
      if (size < 2048) {
        debugPrint('WAV file too small for high quality: ${size} bytes');
        return null;
      }

      // Check if file has valid WAV header
      final bytes = await file.readAsBytes();
      if (bytes.length < 12 ||
          String.fromCharCodes(bytes.take(4)) != 'RIFF' ||
          String.fromCharCodes(bytes.skip(8).take(4)) != 'WAVE') {
        debugPrint('File does not appear to be valid WAV');
        return null;
      }

      debugPrint('High-quality WAV file verified: $filePath (${size} bytes)');
      return filePath;
    } catch (e) {
      debugPrint('WAV file verification failed: $e');
      return null;
    }
  }

  // ---------- Synthesize to file ----------
  /// Tries to synthesize to a file and returns the absolute path, or null if unsupported/failed.
  Future<String?> synthesizeToFile() async {
    final content = _text.trim();
    if (content.isEmpty) {
      _setError('No text to synthesize to file');
      debugPrint('TTS: No text to synthesize to file');
      return null;
    }

    try {
      _clearError();
      debugPrint(
        'TTS: Attempting to synthesize to file: "${content.substring(0, content.length > 50 ? 50 : content.length)}..."',
      );

      await _applyVoice();
      await _tts.setSpeechRate(_rate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);

      final dir = await getApplicationDocumentsDirectory();
      final id = const Uuid().v4();
      final fileNameOnly =
          'tts_$id.wav'; // Use WAV format for better car audio compatibility
      final fullPath = p.join(dir.path, fileNameOnly);

      // Attempt #1: full path (works on some engines/platforms)
      try {
        await _tts.synthesizeToFile(content, fullPath);
        if (await File(fullPath).exists()) {
          // Verify file quality
          final file = File(fullPath);
          final size = await file.length();
          if (size > 1024) {
            // Ensure file is not empty/corrupted
            debugPrint(
              'TTS: Successfully synthesized to file: $fullPath (${size} bytes)',
            );
            return fullPath;
          }
        }
      } catch (_) {
        // Attempt #2: some engines expect just a file name and decide the path
        await _tts.synthesizeToFile(content, fileNameOnly);
        final f = File(fullPath);
        if (await f.exists()) {
          final size = await f.length();
          if (size > 1024) {
            debugPrint(
              'TTS: Successfully synthesized to file: $fullPath (${size} bytes)',
            );
            return f.path;
          }
        }
      }

      _setError('Audio export not supported on this device');
      return null;
    } catch (e) {
      _setError('Failed to export audio: ${e.toString()}');
      debugPrint('synthesizeToFile failed: $e');
      return null;
    }
  }

  // ---------- Misc ----------
  // ---------- Text management ----------
  // Text clearing functionality removed - focusing on core TTS functionality

  // ---------- Word highlighting system ----------

  @override
  void dispose() {
    _wordHighlightTimer?.cancel();
    _tts.stop();
    // _audioPlayer.dispose(); // This line was removed
    super.dispose();
  }
}

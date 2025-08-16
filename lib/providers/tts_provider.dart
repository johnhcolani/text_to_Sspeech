import 'dart:io';
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:text_to_speech/services/tts_cache.dart';
import 'package:text_to_speech/services/audio_player_service.dart';
import 'package:uuid/uuid.dart';

enum TTSState { playing, stopped, paused, continued }

class TTSProvider extends ChangeNotifier {
  late final TtsCache cache;
  // TTS
  final FlutterTts _tts = FlutterTts();
  TTSState _ttsState = TTSState.stopped;

  // Audio player service for high-quality playback
  final AudioPlayerService _audioPlayer = AudioPlayerService();

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
  double _timingOffset =
      1.3; // Increased to 1.3 to make highlighting faster and catch up to speech

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
    _initTTS();
    cache = TtsCache(
      localSynth: (text) async {
        // Reuse your existing synthesizeToFile() which uses current rate/pitch/voice
        _text = text; // so synthesizeToFile uses text
        return await synthesizeToFile(); // returns path or null
      },
      // cloud: YourCloudFetcher(), // add when you wire a real cloud backend
    );
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

    // Use a more frequent timer for smoother updates, but calculate position based on actual progress
    _wordHighlightTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (_ttsState == TTSState.playing && _speechStartTime != null) {
        _updateWordProgressBasedOnActualSpeech();
        // Periodically adjust timing for better synchronization
        if (timer.tick % 10 == 0) {
          // Every 1 second
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

    // Base time per character (varies by language and speech rate)
    final baseTimePerChar = 50.0; // milliseconds per character
    final baseTimePerWord = 300.0; // milliseconds per word

    // Calculate duration considering both character and word count
    final charBasedDuration = textLength * baseTimePerChar;
    final wordBasedDuration = wordsCount * baseTimePerWord;

    // Use the longer duration for more accurate estimation
    _actualSpeechDuration =
        (charBasedDuration > wordBasedDuration
            ? charBasedDuration
            : wordBasedDuration) /
        _rate;

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

    // Add a safety check to prevent jumping too many words at once
    final maxJump = (_totalWords * 0.05).round().clamp(
      1,
      3,
    ); // Max 5% jump or 3 words
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

  // ---------- Public setters ----------
  void setText(String v) {
    _text = v;
    _clearError();
    _resetProgress();
    _initializeWordTracking();
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    try {
      _clearError();
      _selectedLanguage = language;
      await _tts.setLanguage(language);
      await _loadVoices();
      _autoPickVoiceForLanguage();
      notifyListeners();
    } catch (e) {
      _setError('Failed to set language: ${e.toString()}');
      debugPrint('Error setting language: $e');
    }
  }

  Future<void> setVoice(String voiceName) async {
    try {
      _clearError();
      _selectedVoice = voiceName;
      await _applyVoice();
      notifyListeners();
    } catch (e) {
      _setError('Failed to set voice: ${e.toString()}');
      debugPrint('Error setting voice: $e');
    }
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

  void setRate(double newRate) {
    try {
      _rate = newRate.clamp(0.0, 1.0);
      _tts.setSpeechRate(_rate);
      // Restart word highlighting with new rate if active
      if (_wordHighlightingActive && _ttsState == TTSState.playing) {
        _stopWordHighlighting();
        _startWordHighlighting();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting rate: $e');
    }
  }

  void setPitch(double newPitch) {
    try {
      _pitch = newPitch.clamp(0.5, 2.0);
      _tts.setPitch(_pitch);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting pitch: $e');
    }
  }

  void setVolume(double newVolume) {
    try {
      _volume = newVolume.clamp(0.0, 1.0);
      _tts.setVolume(_volume);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
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
  void adjustTimingOffset(double offset) {
    _timingOffset = offset.clamp(
      0.3,
      2.0,
    ); // Allow fine-tuning between 0.3x and 2.0x speed

    // The new system automatically adjusts timing, so we don't need to restart
    // Just notify listeners to update the UI
    notifyListeners();
  }

  // ---------- File pick + text extraction ----------
  Future<void> pickFile() async {
    try {
      _isLoading = true;
      _clearError();
      notifyListeners();

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf'],
      );

      if (result == null) return;

      final filePath = result.files.single.path;
      if (filePath == null) {
        _setError('Failed to access selected file');
        return;
      }

      final file = File(filePath);
      _fileName = result.files.single.name;

      if (_fileName.toLowerCase().endsWith('.pdf')) {
        await _extractTextFromPDF(file);
      } else if (_fileName.toLowerCase().endsWith('.txt')) {
        await _extractTextFromTXT(file);
      }
    } catch (e) {
      _setError('Failed to process file: ${e.toString()}');
      debugPrint('Error picking file: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _extractTextFromPDF(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);

      final buffer = StringBuffer();
      for (int i = 0; i < document.pages.count; i++) {
        buffer.writeln(extractor.extractText(startPageIndex: i));
      }
      document.dispose();

      _text = buffer.toString().trim();
      if (_text.isEmpty) {
        _setError(
          'PDF file appears to be empty or contains no extractable text',
        );
      } else {
        _clearError();
      }
      _initializeWordTracking();
      notifyListeners();
    } catch (e) {
      _setError('Failed to extract text from PDF: ${e.toString()}');
      debugPrint('Error extracting text from PDF: $e');
      _text = '';
      notifyListeners();
    }
  }

  Future<void> _extractTextFromTXT(File file) async {
    try {
      _text = await file.readAsString();
      if (_text.isEmpty) {
        _setError('Text file is empty');
      } else {
        _clearError();
      }
      _initializeWordTracking();
      notifyListeners();
    } catch (e) {
      _setError('Failed to read text file: ${e.toString()}');
      debugPrint('Error reading text file: $e');
      _text = '';
      notifyListeners();
    }
  }

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
      await _audioPlayer.playFile(filePath);

      // Listen for completion
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == 3) {
          // 3 = completed state in just_audio
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
      await _audioPlayer.resume();
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
  bool get isPlayingSavedAudio => _audioPlayer.isPlaying;

  // ---------- Check device capabilities ----------
  /// Checks if the current device supports audio file synthesis
  Future<bool> isFileSynthesisSupported() async {
    try {
      // Try a simple test synthesis with minimal text
      final testText = "Test";
      final dir = await getApplicationDocumentsDirectory();
      final testFileName = 'test_synthesis.wav';
      final testPath = p.join(dir.path, testFileName);

      // Clean up any existing test file
      final testFile = File(testPath);
      if (await testFile.exists()) {
        await testFile.delete();
      }

      // Try to synthesize a test file
      await _tts.synthesizeToFile(testText, testPath);

      // Check if file was created and has content
      if (await testFile.exists()) {
        final size = await testFile.length();
        await testFile.delete(); // Clean up
        return size > 100; // File should have some content
      }

      return false;
    } catch (e) {
      debugPrint('File synthesis test failed: $e');
      return false;
    }
  }

  // ---------- High-quality audio synthesis for car audio ----------
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
        'TTS: Attempting high-quality synthesis: "${content.substring(0, content.length > 50 ? 50 : content.length)}..."',
      );

      // Apply optimal settings for car audio
      await _applyVoice();
      await _tts.setSpeechRate(_rate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);

      final dir = await getApplicationDocumentsDirectory();
      final id = const Uuid().v4();
      final fileNameOnly = 'tts_hq_$id.wav'; // High-quality WAV format
      final fullPath = p.join(dir.path, fileNameOnly);

      // Try multiple synthesis attempts with quality verification
      String? resultPath;

      // Attempt #1: Full path synthesis
      try {
        await _tts.synthesizeToFile(content, fullPath);
        if (await File(fullPath).exists()) {
          resultPath = await _verifyAndOptimizeFile(fullPath);
        }
      } catch (e) {
        debugPrint('Full path synthesis failed: $e');
      }

      // Attempt #2: Filename-only synthesis
      if (resultPath == null) {
        try {
          await _tts.synthesizeToFile(content, fileNameOnly);
          final f = File(fullPath);
          if (await f.exists()) {
            resultPath = await _verifyAndOptimizeFile(f.path);
          }
        } catch (e) {
          debugPrint('Filename synthesis failed: $e');
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

  Future<String?> _verifyAndOptimizeFile(String filePath) async {
    try {
      final file = File(filePath);
      final size = await file.length();

      // Ensure file is substantial and not corrupted
      if (size < 2048) {
        // Increased minimum size for high quality
        debugPrint('File too small for high quality: ${size} bytes');
        return null;
      }

      // Additional quality checks could be added here
      // For example, checking audio headers, duration, etc.

      debugPrint('High-quality file verified: $filePath (${size} bytes)');
      return filePath;
    } catch (e) {
      debugPrint('File verification failed: $e');
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
  void clearText() {
    // Stop any ongoing TTS or audio playback
    if (_ttsState != TTSState.stopped) {
      _tts.stop();
      _ttsState = TTSState.stopped;
    }

    // Stop any audio player
    _audioPlayer.stop();

    // Clear text and file information
    _text = '';
    _fileName = '';

    // Clear errors
    _clearError();

    // Reset all progress and timing
    _resetProgress();

    // Reset word tracking
    _words.clear();
    _wordStartPositions.clear();
    _currentWordIndex = 0;

    // Reset speech timing
    _speechStartTime = null;
    _actualSpeechDuration = 0.0;
    _currentSpeechProgress = 0.0;

    // Reset loading state
    _isLoading = false;

    debugPrint('TTS: Text and all related state cleared');
    notifyListeners();
  }

  @override
  void dispose() {
    _wordHighlightTimer?.cancel();
    _tts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }
}

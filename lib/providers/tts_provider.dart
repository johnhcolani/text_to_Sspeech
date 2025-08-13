import 'dart:io';
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';

enum TTSState { playing, stopped, paused, continued }

class TTSProvider extends ChangeNotifier {
  // TTS
  final FlutterTts _tts = FlutterTts();
  TTSState _ttsState = TTSState.stopped;
  
  // Error handling
  String? _lastError;
  bool _hasError = false;

  // Text + file
  String _text = '';
  String _fileName = '';
  bool _isLoading = false;
  
  // Progress tracking - now properly implemented
  int _progressStart = 0;   // current char start (inclusive)
  int _progressEnd = 0;     // current char end (exclusive)
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
  double _timingOffset = 1.3; // Increased to 1.3 to make highlighting faster and catch up to speech
  
  // Better timing system - track actual speech progress
  DateTime? _speechStartTime;
  int _totalWords = 0;
  
  // Gradual progression system to prevent runaway highlighting
  double _lastProgressPercentage = 0.0;
  int _lastWordIndex = 0;

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
  double _rate = 0.5;   // speaking rate
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
    _lastProgressPercentage = 0.0;
    _lastWordIndex = 0;
    _updateWordProgress();
    
    // Use a more frequent timer for smoother updates, but calculate position based on progress
    _wordHighlightTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_ttsState == TTSState.playing && _speechStartTime != null) {
        _updateWordProgressBasedOnTime();
      } else {
        timer.cancel();
        _wordHighlightingActive = false;
        _currentWordIndex = 0;
        _speechStartTime = null;
        _lastProgressPercentage = 0.0;
        _lastWordIndex = 0;
        notifyListeners();
      }
    });
  }

  void _stopWordHighlighting() {
    _wordHighlightTimer?.cancel();
    _wordHighlightingActive = false;
    _currentWordIndex = 0;
    _speechStartTime = null;
    _lastProgressPercentage = 0.0;
    _lastWordIndex = 0;
    _updateWordProgress();
  }

  void _updateWordProgress() {
    if (_currentWordIndex < _words.length && _currentWordIndex < _wordStartPositions.length) {
      final word = _words[_currentWordIndex];
      final startPos = _wordStartPositions[_currentWordIndex];
      final endPos = startPos + word.length;
      
      _progressStart = startPos;
      _progressEnd = endPos;
      _progressWord = word;
      _progressActive = true;
      
      // Calculate progress percentage
      if (_text.isNotEmpty) {
        _progressPercentage = (endPos / _text.length).clamp(0.0, 1.0);
      }
      
      notifyListeners();
    }
  }

  void _updateWordProgressBasedOnTime() {
    if (_speechStartTime == null || _words.isEmpty) return;
    
    final elapsed = DateTime.now().difference(_speechStartTime!).inMilliseconds;
    
    // Calculate expected word position based on elapsed time and speech rate
    // Estimate total speech duration: words * baseTimePerWord / rate
    final baseTimePerWord = 220; // Reduced from 280ms to 220ms for faster progression
    final estimatedTotalDuration = (_totalWords * baseTimePerWord) / _rate;
    
    // Calculate current word based on progress through speech
    final progress = elapsed / estimatedTotalDuration;
    
    // Apply timing offset but clamp it to prevent runaway progression
    final adjustedProgress = (progress * _timingOffset).clamp(0.0, 1.0);
    final targetWordIndex = (adjustedProgress * _totalWords).round();
    
    // Ensure we don't go beyond the word count
    final newWordIndex = targetWordIndex.clamp(0, _words.length - 1);
    
    // Add a safety check to prevent jumping too many words at once
    final maxJump = (_totalWords * 0.1).round().clamp(1, 5); // Max 10% jump or 5 words
    if ((newWordIndex - _currentWordIndex).abs() > maxJump) {
      // If the jump is too big, limit it to prevent runaway progression
      final limitedJump = newWordIndex > _currentWordIndex 
          ? _currentWordIndex + maxJump 
          : _currentWordIndex - maxJump;
      _currentWordIndex = limitedJump.clamp(0, _words.length - 1);
    } else {
      _currentWordIndex = newWordIndex;
    }
    
    _updateWordProgress();
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
      await _tts.awaitSpeakCompletion(true); // important for consistent callbacks

      // Event handlers
      _tts.setStartHandler(() {
        _ttsState = TTSState.playing;
        _progressActive = true;
        _clearError();
        _startWordHighlighting();
        notifyListeners();
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
        _ttsState = TTSState.continued;
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
            .map((m) => m.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')))
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
        (v) => (v['locale'] ?? '').toLowerCase().startsWith(_selectedLanguage.toLowerCase()),
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

  // ---------- Word highlighting timing adjustment ----------
  void adjustTimingOffset(double offset) {
    _timingOffset = offset.clamp(0.3, 2.0); // Allow fine-tuning between 0.3x and 2.0x speed
    
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
        _setError('PDF file appears to be empty or contains no extractable text');
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
      debugPrint('TTS: Starting to speak: "${toSay.substring(0, toSay.length > 50 ? 50 : toSay.length)}..."');
      await _applyVoice(); // ensure voice is set
      await _tts.setSpeechRate(_rate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);
      debugPrint('TTS: Calling flutter_tts.speak()');
      await _tts.speak(toSay);
      debugPrint('TTS: speak() called successfully');
    } catch (e) {
      _setError('Failed to start speech: ${e.toString()}');
      debugPrint('Error speaking: $e');
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
      await _tts.speak(toSay);
    } catch (e) {
      _setError('Failed to speak text: ${e.toString()}');
      debugPrint('Error speaking (playText): $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('Error stopping: $e');
    }
  }

  Future<void> pause() async {
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        await _tts.pause();             // supported on Apple platforms
      } else {
        await _tts.stop();              // Android: no real pause → stop instead
      }
    } catch (e) {
      debugPrint('Error pausing: $e');
    }
  }

  Future<void> resume() async {
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        // flutter_tts uses "continueSpeak" on Apple platforms
        final dynamic tts = _tts;       // call dynamically so it compiles on all platforms
        await tts.continueSpeak();
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
      debugPrint('TTS: Attempting to synthesize to file: "${content.substring(0, content.length > 50 ? 50 : content.length)}..."');

      await _applyVoice();
      await _tts.setSpeechRate(_rate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);

      final dir = await getApplicationDocumentsDirectory();
      final id = const Uuid().v4();
      final fileNameOnly = 'tts_$id.wav';
      final fullPath = p.join(dir.path, fileNameOnly);

      // Attempt #1: full path (works on some engines/platforms)
      try {
        await _tts.synthesizeToFile(content, fullPath);
        if (await File(fullPath).exists()) return fullPath;
      } catch (_) {
        // Attempt #2: some engines expect just a file name and decide the path
        await _tts.synthesizeToFile(content, fileNameOnly);
        final f = File(fullPath);
        if (await f.exists()) return f.path;
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
    _text = '';
    _fileName = '';
    _clearError();
    _resetProgress();
    notifyListeners();
  }

  @override
  void dispose() {
    _wordHighlightTimer?.cancel();
    _tts.stop();
    super.dispose();
  }
}

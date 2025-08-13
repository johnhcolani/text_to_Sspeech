import 'dart:io';

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

  // Text + file
  String _text = '';
  String _fileName = '';
  bool _isLoading = false;
  int _progressStart = 0;   // current char start (inclusive)
  int _progressEnd = 0;     // current char end (exclusive)
  String _progressWord = '';
  bool _progressActive = false;

  int get progressStart => _progressStart;
  int get progressEnd => _progressEnd;
  String get progressWord => _progressWord;
  bool get progressActive => _progressActive;
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

  // ---------- Initialization ----------
  Future<void> _initTTS() async {
    try {
      await _tts.setLanguage(_selectedLanguage);
      await _tts.setSpeechRate(_rate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);
      await _tts.awaitSpeakCompletion(true); // important for consistent callbacks

      // Event handlers
      _tts.setStartHandler(() {
        _ttsState = TTSState.playing;
        _progressActive = true;
        notifyListeners();
      });
      _tts.setCompletionHandler(() {
        _ttsState = TTSState.stopped;
        _progressActive = false;
        notifyListeners();
      });
      _tts.setCancelHandler(() {
        _ttsState = TTSState.stopped;
        _progressActive = false;
        notifyListeners();
      });
      _tts.setPauseHandler(() {
        _ttsState = TTSState.paused;
        notifyListeners();
      });
      _tts.setContinueHandler(() {
        _ttsState = TTSState.continued;
        notifyListeners();
      });

      await _loadVoices();
      // Pick a default voice matching language if possible
      _autoPickVoiceForLanguage();
    } catch (e) {
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
    }
  }

  void _autoPickVoiceForLanguage() {
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
  }

  Future<void> _applyVoice() async {
    if (_selectedVoice.isEmpty) return;
    // flutter_tts expects a map with at least name + locale on some platforms
    final voice = _voices.firstWhere(
          (v) => v['name'] == _selectedVoice,
      orElse: () => <String, String>{},
    );
    final locale = voice['locale'] ?? _selectedLanguage;
    try {
      await _tts.setVoice({"name": _selectedVoice, "locale": locale});
    } catch (e) {
      debugPrint('Error applying voice: $e');
    }
  }

  // ---------- Public setters ----------
  void setText(String v) {
    _text = v;
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    try {
      _selectedLanguage = language;
      await _tts.setLanguage(language);
      await _loadVoices();
      _autoPickVoiceForLanguage();
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting language: $e');
    }
  }

  Future<void> setVoice(String voiceName) async {
    _selectedVoice = voiceName;
    await _applyVoice();
    notifyListeners();
  }

  void setRate(double newRate) {
    _rate = newRate.clamp(0.0, 1.0);
    _tts.setSpeechRate(_rate);
    notifyListeners();
  }

  void setPitch(double newPitch) {
    _pitch = newPitch.clamp(0.5, 2.0);
    _tts.setPitch(_pitch);
    notifyListeners();
  }

  void setVolume(double newVolume) {
    _volume = newVolume.clamp(0.0, 1.0);
    _tts.setVolume(_volume);
    notifyListeners();
  }

  // ---------- File pick + text extraction ----------
  Future<void> pickFile() async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf'],
      );

      if (result == null) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      final file = File(filePath);
      _fileName = result.files.single.name;

      if (_fileName.toLowerCase().endsWith('.pdf')) {
        await _extractTextFromPDF(file);
      } else if (_fileName.toLowerCase().endsWith('.txt')) {
        await _extractTextFromTXT(file);
      }
    } catch (e) {
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
      notifyListeners();
    } catch (e) {
      debugPrint('Error extracting text from PDF: $e');
      _text = 'Error: Could not extract text from PDF file.';
      notifyListeners();
    }
  }

  Future<void> _extractTextFromTXT(File file) async {
    try {
      _text = await file.readAsString();
      notifyListeners();
    } catch (e) {
      debugPrint('Error reading text file: $e');
      _text = 'Error: Could not read text file.';
      notifyListeners();
    }
  }

  // ---------- Speak / Stop / Pause / Resume ----------
  Future<void> speak() async {
    final toSay = _text.trim();
    if (toSay.isEmpty) {
      debugPrint('TTS: No text to speak');
      return;
    }
    try {
      debugPrint('TTS: Starting to speak: "${toSay.substring(0, toSay.length > 50 ? 50 : toSay.length)}..."');
      await _applyVoice(); // ensure voice is set
      await _tts.setSpeechRate(_rate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);
      debugPrint('TTS: Calling flutter_tts.speak()');
      await _tts.speak(toSay);
      debugPrint('TTS: speak() called successfully');
    } catch (e) {
      debugPrint('Error speaking: $e');
    }
  }

  // Convenience if you want to speak arbitrary text
  Future<void> playText(String value) async {
    final toSay = value.trim();
    if (toSay.isEmpty) return;
    try {
      await _applyVoice();
      await _tts.setSpeechRate(_rate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);
      await _tts.speak(toSay);
    } catch (e) {
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
      debugPrint('TTS: No text to synthesize to file');
      return null;
    }
    debugPrint('TTS: Attempting to synthesize to file: "${content.substring(0, content.length > 50 ? 50 : content.length)}..."');

    try {
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
    } catch (e) {
      debugPrint('synthesizeToFile failed: $e');
    }
    return null;
  }

  // ---------- Misc ----------
  void clearText() {
    _text = '';
    _fileName = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}

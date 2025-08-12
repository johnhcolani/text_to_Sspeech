import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';

enum TTSState { playing, stopped, paused, continued }

class TTSProvider extends ChangeNotifier {
  FlutterTts flutterTts = FlutterTts();
  TTSState _ttsState = TTSState.stopped;
  
  String _text = '';
  String _fileName = '';
  bool _isLoading = false;
  double _speechRate = 0.5;
  double _pitch = 1.0;
  double _volume = 1.0;
  
  List<Map<String, String>> _voices = [];
  String _selectedVoice = '';
  String _selectedLanguage = 'en-US';
  
  // Getters
  String get text => _text;
  String get fileName => _fileName;
  bool get isLoading => _isLoading;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  TTSState get ttsState => _ttsState;
  List<Map<String, String>> get voices => _voices;
  String get selectedVoice => _selectedVoice;
  String get selectedLanguage => _selectedLanguage;
  
  TTSProvider() {
    _initTTS();
  }
  
  void _initTTS() async {
    try {
      // Initialize TTS with default settings
      await flutterTts.setLanguage(_selectedLanguage);
      await flutterTts.setSpeechRate(_speechRate);
      await flutterTts.setPitch(_pitch);
      await flutterTts.setVolume(_volume);
      
      // Set up event handlers for newer flutter_tts version
      flutterTts.setStartHandler(() {
        _ttsState = TTSState.playing;
        notifyListeners();
      });
      
      flutterTts.setCompletionHandler(() {
        _ttsState = TTSState.stopped;
        notifyListeners();
      });
      
      flutterTts.setCancelHandler(() {
        _ttsState = TTSState.stopped;
        notifyListeners();
      });
      
      flutterTts.setPauseHandler(() {
        _ttsState = TTSState.paused;
        notifyListeners();
      });
      
      flutterTts.setContinueHandler(() {
        _ttsState = TTSState.continued;
        notifyListeners();
      });
      
      // Get available voices
      await _loadVoices();
      
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }
  
  Future<void> _loadVoices() async {
    try {
      var availableVoices = await flutterTts.getVoices;
      if (availableVoices != null) {
        _voices = List<Map<String, String>>.from(availableVoices);
        if (_voices.isNotEmpty) {
          _selectedVoice = _voices.first['name'] ?? '';
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading voices: $e');
    }
  }
  
  void setText(String text) {
    _text = text;
    notifyListeners();
  }
  
  void setSpeechRate(double rate) {
    _speechRate = rate;
    flutterTts.setSpeechRate(rate);
    notifyListeners();
  }
  
  void setPitch(double pitch) {
    _pitch = pitch;
    flutterTts.setPitch(pitch);
    notifyListeners();
  }
  
  void setVolume(double volume) {
    _volume = volume;
    flutterTts.setVolume(volume);
    notifyListeners();
  }
  
  Future<void> setVoice(String voiceName) async {
    try {
      await flutterTts.setVoice({"name": voiceName, "locale": _selectedLanguage});
      _selectedVoice = voiceName;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting voice: $e');
    }
  }
  
  Future<void> setLanguage(String language) async {
    try {
      await flutterTts.setLanguage(language);
      _selectedLanguage = language;
      await _loadVoices(); // Reload voices for new language
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting language: $e');
    }
  }
  
  Future<void> pickFile() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf'],
      );
      
      if (result != null) {
        File file = File(result.files.single.path!);
        _fileName = result.files.single.name;
        
        if (_fileName.toLowerCase().endsWith('.pdf')) {
          await _extractTextFromPDF(file);
        } else if (_fileName.toLowerCase().endsWith('.txt')) {
          await _extractTextFromTXT(file);
        }
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
      // Load the PDF document
      PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
      
      // Extract text from all pages
      String extractedText = '';
      for (int i = 0; i < document.pages.count; i++) {
        PdfTextExtractor extractor = PdfTextExtractor(document);
        String pageText = extractor.extractText(startPageIndex: i);
        extractedText += pageText + '\n';
      }
      
      document.dispose();
      _text = extractedText.trim();
      notifyListeners();
    } catch (e) {
      debugPrint('Error extracting text from PDF: $e');
      _text = 'Error: Could not extract text from PDF file.';
      notifyListeners();
    }
  }
  
  Future<void> _extractTextFromTXT(File file) async {
    try {
      String content = await file.readAsString();
      _text = content;
      notifyListeners();
    } catch (e) {
      debugPrint('Error reading text file: $e');
      _text = 'Error: Could not read text file.';
      notifyListeners();
    }
  }
  
  Future<void> speak() async {
    if (_text.isNotEmpty) {
      try {
        await flutterTts.speak(_text);
      } catch (e) {
        debugPrint('Error speaking: $e');
      }
    }
  }
  
  Future<void> stop() async {
    try {
      await flutterTts.stop();
    } catch (e) {
      debugPrint('Error stopping: $e');
    }
  }
  
  Future<void> pause() async {
    try {
      await flutterTts.pause();
    } catch (e) {
      debugPrint('Error pausing: $e');
    }
  }
  
  // For newer flutter_tts version, we can use resume if available
  Future<void> resume() async {
    try {
      // Try to resume if the method exists, otherwise restart speech
      if (_text.isNotEmpty) {
        await flutterTts.speak(_text);
      }
    } catch (e) {
      debugPrint('Error resuming: $e');
    }
  }
  
  void clearText() {
    _text = '';
    _fileName = '';
    notifyListeners();
  }
  
  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }
}

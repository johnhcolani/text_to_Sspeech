import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service for managing word highlighting and text progress tracking.
///
/// Handles word extraction, position tracking, and timing-synchronized highlighting
/// during TTS playback.
class WordHighlightService {
  /// List of extracted words from text
  final List<String> _words = [];

  /// Starting positions of each word in original text
  final List<int> _wordStartPositions = [];

  /// Current highlighted word index
  int _currentWordIndex = 0;

  /// Timer for word highlighting updates
  Timer? _wordHighlightTimer;

  /// Whether word highlighting is active
  bool _wordHighlightingActive = false;

  /// Flag for cancellation
  bool _isCancelled = false;

  // Getters
  List<String> get words => _words;
  int get currentWordIndex => _currentWordIndex;
  bool get isHighlightingActive => _wordHighlightingActive;

  /// Initializes word tracking from given text
  ///
  /// Extracts words and their positions from the input text.
  /// Handles various whitespace and punctuation characters.
  void initializeWordTracking(String text) {
    _words.clear();
    _wordStartPositions.clear();
    _currentWordIndex = 0;
    _isCancelled = false;

    if (text.isEmpty) return;

    int pos = 0;
    String currentWord = '';
    bool inWord = false;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final isWordChar = _isWordCharacter(char);

      if (isWordChar) {
        if (!inWord) {
          pos = i;
          inWord = true;
        }
        currentWord += char;
      } else {
        if (inWord) {
          _words.add(currentWord);
          _wordStartPositions.add(pos);
          currentWord = '';
          inWord = false;
        }
      }
    }

    // Add last word if text ends with a word character
    if (inWord && currentWord.isNotEmpty) {
      _words.add(currentWord);
      _wordStartPositions.add(pos);
    }

    debugPrint('WordHighlightService: Initialized with ${_words.length} words');
  }

  /// Starts timed word highlighting synchronized with speech duration.
  ///
  /// Parameters:
  /// - [totalDurationMs]: Total speech duration in milliseconds
  /// - [onWordChanged]: Callback when highlighted word changes
  /// - [timingOffset]: Synchronization offset factor (default 0.8)
  void startTimedHighlighting({
    required int totalDurationMs,
    required Function(int wordIndex) onWordChanged,
    double timingOffset = 0.8,
  }) {
    if (_words.isEmpty || _isCancelled) return;

    stopHighlighting();

    _wordHighlightingActive = true;
    final startTime = DateTime.now();

    _wordHighlightTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (_isCancelled) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final progress = (elapsed / totalDurationMs * timingOffset).clamp(0.0, 1.0);
      final newWordIndex = (progress * _words.length).round().clamp(0, _words.length - 1);

      if (newWordIndex != _currentWordIndex) {
        _currentWordIndex = newWordIndex;
        onWordChanged(newWordIndex);
      }

      if (progress >= 1.0) {
        timer.cancel();
        _wordHighlightingActive = false;
      }
    });
  }

  /// Updates current word index based on manual progress.
  ///
  /// Used when progress is updated externally (e.g., manual seeking).
  void updateWordProgress(double progress) {
    if (_words.isEmpty) return;

    final newWordIndex = (progress * _words.length).round().clamp(0, _words.length - 1);

    if (newWordIndex != _currentWordIndex) {
      _currentWordIndex = newWordIndex;
    }
  }

  /// Gets the current highlighted word
  String? getCurrentWord() {
    if (_currentWordIndex >= 0 && _currentWordIndex < _words.length) {
      return _words[_currentWordIndex];
    }
    return null;
  }

  /// Gets the character positions of the current word in original text
  ({int start, int end})? getCurrentWordPositions() {
    if (_currentWordIndex >= 0 && _currentWordIndex < _wordStartPositions.length) {
      final start = _wordStartPositions[_currentWordIndex];
      final word = _words[_currentWordIndex];
      return (start: start, end: start + word.length);
    }
    return null;
  }

  /// Stops word highlighting timers
  void stopHighlighting() {
    _wordHighlightTimer?.cancel();
    _wordHighlightTimer = null;
    _wordHighlightingActive = false;
  }

  /// Resets highlighting to start
  void reset() {
    _currentWordIndex = 0;
    stopHighlighting();
  }

  /// Cancels operations and cleans up resources
  void cancel() {
    _isCancelled = true;
    stopHighlighting();
  }

  /// Disposes of all resources
  void dispose() {
    cancel();
    _words.clear();
    _wordStartPositions.clear();
  }

  /// Helper to determine if character is part of a word
  static bool _isWordCharacter(String char) {
    // Letters, numbers, apostrophes, and hyphens are word characters
    return RegExp(r"[a-zA-Z0-9'-]").hasMatch(char);
  }
}

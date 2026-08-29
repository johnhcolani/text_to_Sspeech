/// Input validation utilities for the Text-to-Speech app
///
/// This module provides validation functions for user inputs including
/// text length, file sizes, and other constraints.
class InputValidator {
  /// Maximum text length for TTS synthesis (characters)
  static const int maxTextLength = 5000;
  static const int minConfigurableTextLength = 500;
  static const int maxConfigurableTextLength = 50000;

  /// Minimum text length for TTS synthesis (characters)
  static const int minTextLength = 1;

  /// Maximum file size for processing (bytes) - 50 MB
  static const int maxFileSize = 50 * 1024 * 1024;

  /// List of allowed text document extensions
  static const List<String> allowedTextFileExtensions = ['txt', 'pdf'];

  /// Deprecated compatibility alias. Use [allowedTextFileExtensions].
  static const List<String> allowedAudioExtensions = allowedTextFileExtensions;

  /// List of allowed image file extensions
  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];

  /// Validates text input for TTS synthesis
  ///
  /// Returns an error message string if validation fails, null if valid.
  /// Checks for:
  /// - Minimum text length
  /// - Maximum text length
  /// - Non-empty content
  static String? validateText(String? text, {int maxLength = maxTextLength}) {
    if (text == null || text.isEmpty) {
      return 'Text cannot be empty. Please enter some text to convert to speech.';
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return 'Text cannot contain only whitespace. Please enter meaningful content.';
    }

    if (trimmed.length < minTextLength) {
      return 'Text is too short. Minimum length is $minTextLength character.';
    }

    if (trimmed.length > maxLength) {
      return 'Text is too long. Maximum length is $maxLength characters. '
          'Current length: ${trimmed.length} characters.';
    }

    return null;
  }

  /// Validates file size
  ///
  /// Returns an error message if file is too large, null if valid.
  static String? validateFileSize(int? fileSizeBytes) {
    if (fileSizeBytes == null) {
      return 'Unable to determine file size.';
    }

    if (fileSizeBytes <= 0) {
      return 'File is empty or corrupted.';
    }

    if (fileSizeBytes > maxFileSize) {
      final maxSizeMB = maxFileSize ~/ (1024 * 1024);
      final actualSizeMB = fileSizeBytes / (1024 * 1024);
      return 'File is too large. Maximum size is ${maxSizeMB}MB. '
          'Your file is ${actualSizeMB.toStringAsFixed(2)}MB.';
    }

    return null;
  }

  /// Validates file extension
  ///
  /// Returns an error message if extension is not allowed, null if valid.
  static String? validateFileExtension(
    String? filePath,
    List<String> allowedExtensions,
  ) {
    if (filePath == null || filePath.isEmpty) {
      return 'Invalid file path.';
    }

    final extension = filePath.split('.').last.toLowerCase();

    if (!allowedExtensions.contains(extension)) {
      return 'File type not supported. Allowed formats: ${allowedExtensions.join(", ")}.';
    }

    return null;
  }

  /// Validates audio file input
  ///
  /// Performs comprehensive validation of audio files.
  static String? validateAudioFile(String? filePath, int? fileSizeBytes) {
    // Check extension
    final extensionError = validateFileExtension(
      filePath,
      allowedAudioExtensions,
    );
    if (extensionError != null) return extensionError;

    // Check file size
    final sizeError = validateFileSize(fileSizeBytes);
    if (sizeError != null) return sizeError;

    return null;
  }

  /// Validates image file input
  ///
  /// Performs comprehensive validation of image files.
  static String? validateImageFile(String? filePath, int? fileSizeBytes) {
    // Check extension
    final extensionError = validateFileExtension(
      filePath,
      allowedImageExtensions,
    );
    if (extensionError != null) return extensionError;

    // Check file size
    final sizeError = validateFileSize(fileSizeBytes);
    if (sizeError != null) return sizeError;

    return null;
  }

  /// Validates language code
  ///
  /// Returns an error message if language code is invalid, null if valid.
  static String? validateLanguage(String? languageCode) {
    if (languageCode == null || languageCode.isEmpty) {
      return 'Language selection is required.';
    }

    // Language codes should follow pattern: language-COUNTRY (e.g., en-US)
    if (!RegExp(r'^[a-z]{2}(-[A-Z]{2})?$').hasMatch(languageCode)) {
      return 'Invalid language code: $languageCode';
    }

    return null;
  }

  /// Validates speech rate value
  ///
  /// Returns an error message if rate is invalid, null if valid.
  /// Rate should be between 0.0 and 1.0
  static String? validateSpeechRate(double? rate) {
    if (rate == null) {
      return 'Speech rate is required.';
    }

    if (rate < 0.0 || rate > 1.0) {
      return 'Speech rate must be between 0.0 and 1.0. Current value: $rate';
    }

    return null;
  }

  /// Validates pitch value
  ///
  /// Returns an error message if pitch is invalid, null if valid.
  /// Pitch should typically be between 0.5 and 2.0
  static String? validatePitch(double? pitch) {
    if (pitch == null) {
      return 'Pitch is required.';
    }

    if (pitch < 0.5 || pitch > 2.0) {
      return 'Pitch should be between 0.5 and 2.0. Current value: $pitch';
    }

    return null;
  }

  /// Validates volume value
  ///
  /// Returns an error message if volume is invalid, null if valid.
  /// Volume should be between 0.0 and 1.0
  static String? validateVolume(double? volume) {
    if (volume == null) {
      return 'Volume is required.';
    }

    if (volume < 0.0 || volume > 1.0) {
      return 'Volume must be between 0.0 and 1.0. Current value: $volume';
    }

    return null;
  }

  /// Sanitizes text input by removing dangerous content
  ///
  /// Removes leading/trailing whitespace and normalizes line breaks.
  static String sanitizeText(String text) {
    // Remove leading/trailing whitespace
    String sanitized = text.trim();

    // Normalize line breaks (convert different types to \n)
    sanitized = sanitized.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Split by lines, trim each line, and rejoin
    final lines = sanitized.split('\n').map((line) => line.trim()).toList();

    // Remove completely empty lines from the beginning and end
    while (lines.isNotEmpty && lines.first.isEmpty) {
      lines.removeAt(0);
    }
    while (lines.isNotEmpty && lines.last.isEmpty) {
      lines.removeLast();
    }

    // Join back and collapse excessive blank lines
    sanitized = lines.join('\n');
    sanitized = sanitized.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Collapse excessive spaces on same line
    sanitized = sanitized.replaceAll(RegExp(r' {2,}'), ' ');

    return sanitized;
  }
}

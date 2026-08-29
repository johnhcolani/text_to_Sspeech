/// Error codes and handling for the Text-to-Speech app
///
/// This module provides structured error codes and error handling utilities
/// for consistent error reporting across the application.
library;

/// Error codes used throughout the application
///
/// These error codes help identify the type of error that occurred
/// and can be used for logging, reporting, and user-friendly error messages.
abstract class ErrorCode {
  // General errors (100-199)
  static const int unknownError = 101;
  static const int initializationError = 102;
  static const int networkError = 103;
  static const int timeoutError = 104;

  // Input validation errors (200-299)
  static const int invalidTextLength = 201;
  static const int emptyTextError = 202;
  static const int invalidFileSize = 203;
  static const int invalidFileType = 204;
  static const int fileNotFound = 205;
  static const int invalidLanguage = 206;
  static const int invalidVoiceSelection = 207;

  // TTS errors (300-399)
  static const int ttsInitializationError = 301;
  static const int ttsEngineError = 302;
  static const int synthesisError = 303;
  static const int voiceNotAvailable = 304;

  // File processing errors (400-499)
  static const int fileReadError = 401;
  static const int fileParseFailed = 402;
  static const int pdfExtractionError = 403;
  static const int imageProcessingError = 404;
  static const int ocrError = 405;
  static const int textExtractionError = 406;

  // Database errors (500-599)
  static const int databaseError = 501;
  static const int databaseInitError = 502;
  static const int saveError = 503;
  static const int loadError = 504;

  // Permission errors (600-699)
  static const int permissionDenied = 601;
  static const int permissionNotRequested = 602;
  static const int cameraPermissionError = 603;
  static const int storagePermissionError = 604;
  static const int microphonePermissionError = 605;

  // Audio-specific errors (700-799)
  static const int audioPlaybackError = 701;
  static const int audioExportError = 702;
  static const int audioFileNotFound = 703;
  static const int audioFileCorrupted = 704;
  static const int audioPlayerError = 705;
  static const int audioQualityError = 706;
  static const int carAudioError = 707;
}

/// Represents an application error with code, message, and optional details
class AppError implements Exception {
  /// Unique error code
  final int code;

  /// Human-readable error message
  final String message;

  /// Additional error details
  final String? details;

  /// The original exception that caused this error
  final Object? originalError;

  /// Stack trace of where the error occurred
  final StackTrace? stackTrace;

  /// Timestamp when the error occurred
  final DateTime timestamp;

  AppError({
    required this.code,
    required this.message,
    this.details,
    this.originalError,
    this.stackTrace,
  }) : timestamp = DateTime.now();

  @override
  String toString() => 'AppError(code: $code, message: $message, details: $details)';

  /// Convert error to a user-friendly message
  String toUserMessage() {
    if (details != null && details!.isNotEmpty) {
      return '$message\n\nDetails: $details';
    }
    return message;
  }

  /// Convert error to debugging information
  String toDebugString() {
    final buffer = StringBuffer();
    buffer.writeln('AppError Code: $code');
    buffer.writeln('Message: $message');
    if (details != null) {
      buffer.writeln('Details: $details');
    }
    if (originalError != null) {
      buffer.writeln('Original Error: $originalError');
    }
    if (stackTrace != null) {
      buffer.writeln('Stack Trace:\n$stackTrace');
    }
    return buffer.toString();
  }
}

/// Error handler and factory
class ErrorHandler {
  /// Creates a TTS-specific error
  static AppError ttError(
    String message, {
    int code = ErrorCode.ttsEngineError,
    String? details,
    Object? originalError,
    StackTrace? stackTrace,
  }) =>
      AppError(
        code: code,
        message: message,
        details: details,
        originalError: originalError,
        stackTrace: stackTrace,
      );

  /// Creates a file processing error
  static AppError fileError(
    String message, {
    int code = ErrorCode.fileReadError,
    String? details,
    Object? originalError,
    StackTrace? stackTrace,
  }) =>
      AppError(
        code: code,
        message: message,
        details: details,
        originalError: originalError,
        stackTrace: stackTrace,
      );

  /// Creates a validation error
  static AppError validationError(
    String message, {
    int code = ErrorCode.invalidTextLength,
    String? details,
  }) =>
      AppError(
        code: code,
        message: message,
        details: details,
      );

  /// Creates a database error
  static AppError databaseError(
    String message, {
    int code = ErrorCode.databaseError,
    String? details,
    Object? originalError,
    StackTrace? stackTrace,
  }) =>
      AppError(
        code: code,
        message: message,
        details: details,
        originalError: originalError,
        stackTrace: stackTrace,
      );

  /// Creates a permission error
  static AppError permissionError(
    String message, {
    int code = ErrorCode.permissionDenied,
    String? details,
  }) =>
      AppError(
        code: code,
        message: message,
        details: details,
      );

  /// Creates an audio error
  static AppError audioError(
    String message, {
    int code = ErrorCode.audioPlaybackError,
    String? details,
    Object? originalError,
    StackTrace? stackTrace,
  }) =>
      AppError(
        code: code,
        message: message,
        details: details,
        originalError: originalError,
        stackTrace: stackTrace,
      );

  /// Gets a human-friendly message for an error code
  static String getErrorMessage(int errorCode) {
    switch (errorCode) {
      // General errors
      case ErrorCode.unknownError:
        return 'An unknown error occurred. Please try again.';
      case ErrorCode.initializationError:
        return 'Failed to initialize the application. Please restart the app.';
      case ErrorCode.networkError:
        return 'Network connection error. Please check your connection.';
      case ErrorCode.timeoutError:
        return 'The operation took too long. Please try again.';

      // Input validation errors
      case ErrorCode.invalidTextLength:
        return 'The text length is outside the allowed range.';
      case ErrorCode.emptyTextError:
        return 'Please enter some text to convert to speech.';
      case ErrorCode.invalidFileSize:
        return 'The file size is too large or empty.';
      case ErrorCode.invalidFileType:
        return 'The file type is not supported.';
      case ErrorCode.fileNotFound:
        return 'The requested file was not found.';
      case ErrorCode.invalidLanguage:
        return 'The selected language is not supported.';
      case ErrorCode.invalidVoiceSelection:
        return 'The selected voice is not available.';

      // TTS errors
      case ErrorCode.ttsInitializationError:
        return 'Failed to initialize the text-to-speech engine.';
      case ErrorCode.ttsEngineError:
        return 'The text-to-speech engine encountered an error.';
      case ErrorCode.synthesisError:
        return 'Failed to synthesize speech from the text.';
      case ErrorCode.audioPlaybackError:
        return 'Failed to play the audio. Please check your device audio settings.';
      case ErrorCode.audioExportError:
        return 'Failed to export the audio file.';
      case ErrorCode.voiceNotAvailable:
        return 'The selected voice is not available on your device.';

      // File processing errors
      case ErrorCode.fileReadError:
        return 'Failed to read the file. Please check the file and try again.';
      case ErrorCode.fileParseFailed:
        return 'Failed to parse the file content.';
      case ErrorCode.pdfExtractionError:
        return 'Failed to extract text from the PDF file.';
      case ErrorCode.imageProcessingError:
        return 'Failed to process the image.';
      case ErrorCode.ocrError:
        return 'Failed to recognize text in the image.';
      case ErrorCode.textExtractionError:
        return 'Failed to extract text from the file.';

      // Database errors
      case ErrorCode.databaseError:
        return 'A database error occurred. Please restart the app.';
      case ErrorCode.databaseInitError:
        return 'Failed to initialize the database.';
      case ErrorCode.saveError:
        return 'Failed to save your data.';
      case ErrorCode.loadError:
        return 'Failed to load your data.';

      // Permission errors
      case ErrorCode.permissionDenied:
        return 'Permission denied. Please enable the required permissions in app settings.';
      case ErrorCode.permissionNotRequested:
        return 'Permission request was not completed.';
      case ErrorCode.cameraPermissionError:
        return 'Camera permission is required to use this feature.';
      case ErrorCode.storagePermissionError:
        return 'Storage permission is required to access files.';
      case ErrorCode.microphonePermissionError:
        return 'Microphone permission is required to record audio.';

      // Audio-specific errors
      case ErrorCode.audioFileNotFound:
        return 'The audio file was not found.';
      case ErrorCode.audioFileCorrupted:
        return 'The audio file is corrupted or invalid.';
      case ErrorCode.audioPlayerError:
        return 'Audio player error. Please try again.';
      case ErrorCode.audioQualityError:
        return 'Failed to verify audio quality.';
      case ErrorCode.carAudioError:
        return 'Car audio system error. Please check your audio settings.';

      default:
        return 'An error occurred with code $errorCode.';
    }
  }
}

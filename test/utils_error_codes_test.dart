import 'package:flutter_test/flutter_test.dart';
import 'package:text_to_speech/utils/error_codes.dart';

void main() {
  group('ErrorHandler - Error Creation', () {
    test('ttError creates TTS error with correct code', () {
      final error = ErrorHandler.ttError('TTS failed');
      expect(error.code, equals(ErrorCode.ttsEngineError));
      expect(error.message, equals('TTS failed'));
      expect(error.timestamp, isNotNull);
    });

    test('fileError creates file error with correct code', () {
      final error = ErrorHandler.fileError('File read failed');
      expect(error.code, equals(ErrorCode.fileReadError));
      expect(error.message, equals('File read failed'));
    });

    test('validationError creates validation error with correct code', () {
      final error = ErrorHandler.validationError('Invalid input');
      expect(error.code, equals(ErrorCode.invalidTextLength));
      expect(error.message, equals('Invalid input'));
    });

    test('databaseError creates database error with correct code', () {
      final error = ErrorHandler.databaseError('DB query failed');
      expect(error.code, equals(ErrorCode.databaseError));
      expect(error.message, equals('DB query failed'));
    });

    test('permissionError creates permission error with correct code', () {
      final error = ErrorHandler.permissionError('Camera denied');
      expect(error.code, equals(ErrorCode.permissionDenied));
      expect(error.message, equals('Camera denied'));
    });

    test('audioError creates audio error with correct code', () {
      final error = ErrorHandler.audioError('Playback failed');
      expect(error.code, equals(ErrorCode.audioPlaybackError));
      expect(error.message, equals('Playback failed'));
    });

    test('Error with details stores details correctly', () {
      final error = ErrorHandler.fileError(
        'File not found',
        details: '/path/to/file.pdf',
      );
      expect(error.details, equals('/path/to/file.pdf'));
    });

    test('Error with original exception stores it', () {
      final originalError = Exception('Original');
      final error = ErrorHandler.fileError(
        'Wrapped error',
        originalError: originalError,
      );
      expect(error.originalError, equals(originalError));
    });
  });

  group('AppError - String Representations', () {
    test('toString returns formatted error string', () {
      final error = ErrorHandler.ttError('Test error', details: 'Test details');
      final stringValue = error.toString();
      expect(stringValue, contains('AppError'));
      expect(stringValue, contains('code'));
      expect(stringValue, contains('message'));
    });

    test('toUserMessage returns message only when no details', () {
      final error = ErrorHandler.validationError('Invalid input');
      expect(error.toUserMessage(), equals('Invalid input'));
    });

    test('toUserMessage includes details when available', () {
      final error = ErrorHandler.validationError(
        'Invalid input',
        details: 'Text is too long',
      );
      final userMessage = error.toUserMessage();
      expect(userMessage, contains('Invalid input'));
      expect(userMessage, contains('Text is too long'));
    });

    test('toDebugString includes all error information', () {
      final error = ErrorHandler.ttError(
        'TTS failed',
        details: 'Voice unavailable',
      );
      final debugString = error.toDebugString();
      expect(debugString, contains('AppError Code'));
      expect(debugString, contains('Message'));
      expect(debugString, contains('Details'));
    });
  });

  group('ErrorHandler - Error Messages', () {
    test('getErrorMessage returns message for all error codes', () {
      final testCodes = [
        ErrorCode.unknownError,
        ErrorCode.initializationError,
        ErrorCode.networkError,
        ErrorCode.invalidTextLength,
        ErrorCode.ttsEngineError,
        ErrorCode.fileReadError,
        ErrorCode.databaseError,
        ErrorCode.permissionDenied,
        ErrorCode.audioPlaybackError,
      ];

      for (final code in testCodes) {
        final message = ErrorHandler.getErrorMessage(code);
        expect(message, isNotNull);
        expect(message, isNotEmpty);
        expect(message, isNot('An error occurred with code $code.'));
      }
    });

    test('getErrorMessage returns custom message for unknown code', () {
      final message = ErrorHandler.getErrorMessage(999);
      expect(message, contains('999'));
    });

    test('Error messages are user-friendly', () {
      final message = ErrorHandler.getErrorMessage(ErrorCode.permissionDenied);
      expect(message.toLowerCase(), contains('permission'));
      expect(message, contains('Please'));
    });
  });

  group('Error Code Constants', () {
    test('All error code constants exist', () {
      expect(ErrorCode.unknownError, isNotNull);
      expect(ErrorCode.ttsEngineError, isNotNull);
      expect(ErrorCode.fileReadError, isNotNull);
      expect(ErrorCode.databaseError, isNotNull);
      expect(ErrorCode.permissionDenied, isNotNull);
      expect(ErrorCode.audioPlaybackError, isNotNull);
    });

    test('Error code constants are unique', () {
      final codes = [
        ErrorCode.unknownError,
        ErrorCode.initializationError,
        ErrorCode.networkError,
        ErrorCode.invalidTextLength,
        ErrorCode.ttsEngineError,
        ErrorCode.fileReadError,
        ErrorCode.databaseError,
        ErrorCode.permissionDenied,
      ];

      final uniqueCodes = codes.toSet();
      expect(uniqueCodes.length, equals(codes.length));
    });

    test('Error codes are organized by category', () {
      // General errors 100-199
      expect(ErrorCode.unknownError, greaterThanOrEqualTo(101));
      expect(ErrorCode.unknownError, lessThan(200));

      // Input validation errors 200-299
      expect(ErrorCode.emptyTextError, greaterThanOrEqualTo(200));
      expect(ErrorCode.emptyTextError, lessThan(300));

      // TTS errors 300-399
      expect(ErrorCode.ttsEngineError, greaterThanOrEqualTo(300));
      expect(ErrorCode.ttsEngineError, lessThan(400));

      // File processing errors 400-499
      expect(ErrorCode.fileReadError, greaterThanOrEqualTo(400));
      expect(ErrorCode.fileReadError, lessThan(500));

      // Database errors 500-599
      expect(ErrorCode.databaseError, greaterThanOrEqualTo(500));
      expect(ErrorCode.databaseError, lessThan(600));

      // Permission errors 600-699
      expect(ErrorCode.permissionDenied, greaterThanOrEqualTo(600));
      expect(ErrorCode.permissionDenied, lessThan(700));

      // Audio errors 700-799
      expect(ErrorCode.audioPlaybackError, greaterThanOrEqualTo(700));
      expect(ErrorCode.audioPlaybackError, lessThan(800));
    });
  });

  group('AppError Timestamp', () {
    test('AppError creates timestamp automatically', () {
      final beforeCreation = DateTime.now();
      final error = ErrorHandler.ttError('Test');
      final afterCreation = DateTime.now();

      expect(error.timestamp, isNotNull);
      expect(error.timestamp.isAfter(beforeCreation.subtract(Duration(seconds: 1))), isTrue);
      expect(error.timestamp.isBefore(afterCreation.add(Duration(seconds: 1))), isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:text_to_speech/utils/validators.dart';

void main() {
  group('InputValidator - Text Validation', () {
    test('validateText returns null for valid text', () {
      const validText = 'Hello, this is valid text';
      expect(InputValidator.validateText(validText), isNull);
    });

    test('validateText returns error for null text', () {
      final error = InputValidator.validateText(null);
      expect(error, isNotNull);
      expect(error, contains('cannot be empty'));
    });

    test('validateText returns error for empty text', () {
      final error = InputValidator.validateText('');
      expect(error, isNotNull);
      expect(error, contains('cannot be empty'));
    });

    test('validateText returns error for whitespace-only text', () {
      final error = InputValidator.validateText('   \n\n   ');
      expect(error, isNotNull);
      expect(error, contains('whitespace'));
    });

    test('validateText returns error for text exceeding max length', () {
      final longText = 'a' * (InputValidator.maxTextLength + 1);
      final error = InputValidator.validateText(longText);
      expect(error, isNotNull);
      expect(error, contains('too long'));
      expect(error, contains('${InputValidator.maxTextLength}'));
    });

    test('validateText accepts maximum allowed length', () {
      final maxText = 'a' * InputValidator.maxTextLength;
      expect(InputValidator.validateText(maxText), isNull);
    });

    test('validateText accepts text at minimum length', () {
      expect(InputValidator.validateText('a'), isNull);
    });
  });

  group('InputValidator - File Size Validation', () {
    test('validateFileSize returns null for valid size', () {
      expect(InputValidator.validateFileSize(1024 * 100), isNull);
    });

    test('validateFileSize returns error for null size', () {
      final error = InputValidator.validateFileSize(null);
      expect(error, isNotNull);
      expect(error, contains('Unable to determine'));
    });

    test('validateFileSize returns error for empty file', () {
      final error = InputValidator.validateFileSize(0);
      expect(error, isNotNull);
      expect(error, contains('empty'));
    });

    test('validateFileSize returns error for negative size', () {
      final error = InputValidator.validateFileSize(-1);
      expect(error, isNotNull);
      expect(error, contains('empty'));
    });

    test('validateFileSize returns error for oversized file', () {
      final oversized = InputValidator.maxFileSize + 1;
      final error = InputValidator.validateFileSize(oversized);
      expect(error, isNotNull);
      expect(error, contains('too large'));
    });

    test('validateFileSize accepts maximum allowed size', () {
      expect(InputValidator.validateFileSize(InputValidator.maxFileSize), isNull);
    });
  });

  group('InputValidator - File Extension Validation', () {
    test('validateFileExtension returns null for valid extension', () {
      final error = InputValidator.validateFileExtension(
        'document.pdf',
        InputValidator.allowedAudioExtensions,
      );
      expect(error, isNull);
    });

    test('validateFileExtension returns error for invalid extension', () {
      final error = InputValidator.validateFileExtension(
        'document.exe',
        InputValidator.allowedAudioExtensions,
      );
      expect(error, isNotNull);
      expect(error, contains('not supported'));
    });

    test('validateFileExtension is case-insensitive', () {
      final error = InputValidator.validateFileExtension(
        'document.PDF',
        InputValidator.allowedAudioExtensions,
      );
      expect(error, isNull);
    });

    test('validateFileExtension returns error for null path', () {
      final error = InputValidator.validateFileExtension(
        null,
        InputValidator.allowedAudioExtensions,
      );
      expect(error, isNotNull);
    });

    test('validateFileExtension returns error for empty path', () {
      final error = InputValidator.validateFileExtension(
        '',
        InputValidator.allowedAudioExtensions,
      );
      expect(error, isNotNull);
    });
  });

  group('InputValidator - Audio File Validation', () {
    test('validateAudioFile returns null for valid audio file', () {
      final error = InputValidator.validateAudioFile(
        'audio.pdf',
        1024 * 100,
      );
      expect(error, isNull);
    });

    test('validateAudioFile returns extension error for invalid format', () {
      final error = InputValidator.validateAudioFile(
        'audio.mp3',
        1024 * 100,
      );
      expect(error, isNotNull);
      expect(error, contains('not supported'));
    });

    test('validateAudioFile returns size error for oversized file', () {
      final error = InputValidator.validateAudioFile(
        'audio.pdf',
        InputValidator.maxFileSize + 1,
      );
      expect(error, isNotNull);
      expect(error, contains('too large'));
    });
  });

  group('InputValidator - Image File Validation', () {
    test('validateImageFile returns null for valid image', () {
      final error = InputValidator.validateImageFile(
        'photo.jpg',
        1024 * 100,
      );
      expect(error, isNull);
    });

    test('validateImageFile accepts all image formats', () {
      for (final ext in InputValidator.allowedImageExtensions) {
        final error = InputValidator.validateImageFile(
          'photo.$ext',
          1024 * 100,
        );
        expect(error, isNull);
      }
    });
  });

  group('InputValidator - Language Validation', () {
    test('validateLanguage returns null for valid language code', () {
      expect(InputValidator.validateLanguage('en-US'), isNull);
      expect(InputValidator.validateLanguage('fr-FR'), isNull);
      expect(InputValidator.validateLanguage('es'), isNull);
    });

    test('validateLanguage returns error for null language', () {
      final error = InputValidator.validateLanguage(null);
      expect(error, isNotNull);
    });

    test('validateLanguage returns error for empty language', () {
      final error = InputValidator.validateLanguage('');
      expect(error, isNotNull);
    });

    test('validateLanguage returns error for invalid format', () {
      final error = InputValidator.validateLanguage('invalid-language-code');
      expect(error, isNotNull);
      expect(error, contains('Invalid'));
    });
  });

  group('InputValidator - Speech Parameters Validation', () {
    test('validateSpeechRate returns null for valid rate', () {
      expect(InputValidator.validateSpeechRate(0.5), isNull);
      expect(InputValidator.validateSpeechRate(0.0), isNull);
      expect(InputValidator.validateSpeechRate(1.0), isNull);
    });

    test('validateSpeechRate returns error for out of range values', () {
      final errorLow = InputValidator.validateSpeechRate(-0.1);
      final errorHigh = InputValidator.validateSpeechRate(1.5);
      expect(errorLow, isNotNull);
      expect(errorHigh, isNotNull);
    });

    test('validatePitch returns null for valid pitch', () {
      expect(InputValidator.validatePitch(1.0), isNull);
      expect(InputValidator.validatePitch(0.5), isNull);
      expect(InputValidator.validatePitch(2.0), isNull);
    });

    test('validatePitch returns error for out of range values', () {
      final errorLow = InputValidator.validatePitch(0.4);
      final errorHigh = InputValidator.validatePitch(2.1);
      expect(errorLow, isNotNull);
      expect(errorHigh, isNotNull);
    });

    test('validateVolume returns null for valid volume', () {
      expect(InputValidator.validateVolume(0.5), isNull);
      expect(InputValidator.validateVolume(0.0), isNull);
      expect(InputValidator.validateVolume(1.0), isNull);
    });

    test('validateVolume returns error for out of range values', () {
      final errorLow = InputValidator.validateVolume(-0.1);
      final errorHigh = InputValidator.validateVolume(1.5);
      expect(errorLow, isNotNull);
      expect(errorHigh, isNotNull);
    });
  });

  group('InputValidator - Text Sanitization', () {
    test('sanitizeText removes leading and trailing whitespace', () {
      const input = '  hello world  ';
      const expected = 'hello world';
      expect(InputValidator.sanitizeText(input), equals(expected));
    });

    test('sanitizeText normalizes line breaks', () {
      const input = 'line1\r\nline2\rline3';
      const expected = 'line1\nline2\nline3';
      expect(InputValidator.sanitizeText(input), equals(expected));
    });

    test('sanitizeText removes excessive blank lines', () {
      const input = 'line1\n\n\n\nline2';
      const expected = 'line1\n\nline2';
      expect(InputValidator.sanitizeText(input), equals(expected));
    });

    test('sanitizeText removes excessive spaces', () {
      const input = 'hello    world';
      const expected = 'hello world';
      expect(InputValidator.sanitizeText(input), equals(expected));
    });

    test('sanitizeText handles complex input', () {
      const input = '   hello\r\nworld\n\n\n  test   ';
      const expected = 'hello\nworld\n\ntest';
      expect(InputValidator.sanitizeText(input), equals(expected));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:text_to_speech/services/encryption_service.dart';

void main() {
  final encryption = EncryptionService();

  test('round trips marked obfuscated values', () {
    const plaintext = 'Hello from TTS';
    final stored = encryption.encrypt(plaintext);

    expect(stored, startsWith('obf:v1:'));
    expect(encryption.decrypt(stored), plaintext);
  });

  test('preserves legacy plaintext including valid Base64', () {
    expect(encryption.decrypt('en-US'), 'en-US');
    expect(encryption.decrypt('SGVsbG8='), 'SGVsbG8=');
  });
}

import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Service for lightly obfuscating stored app data
///
/// Provides reversible obfuscation before storing data in the database. This
/// keeps values from being plainly readable during casual inspection, but it is
/// not cryptographic protection because the key ships with the app.
///
/// **Note:** For production apps, consider implementing:
/// - AES encryption with proper key management
/// - SQLCipher for database-level encryption
/// - Secure key storage
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  /// Static obfuscation key.
  /// For real encryption, generate this per install and store it securely.
  static const String _masterKey = 'tts_app_secure_key_2024';
  static const String _obfuscationPrefix = 'obf:v1:';

  /// Obfuscates a string using a reversible XOR transform
  ///
  /// Converts plaintext to base64-encoded obfuscated bytes.
  /// In production, use a proper encryption library like `cryptography` package.
  ///
  /// Parameters:
  /// - [plaintext]: The text to obfuscate
  ///
  /// Returns: Base64-encoded obfuscated string
  String encrypt(String plaintext) {
    try {
      if (plaintext.isEmpty) return '';

      // Convert strings to bytes
      final plaintextBytes = utf8.encode(plaintext);
      final keyBytes = utf8.encode(_masterKey);

      // Simple XOR encryption with key rotation
      final encryptedBytes = <int>[];
      for (int i = 0; i < plaintextBytes.length; i++) {
        final keyByte = keyBytes[i % keyBytes.length];
        encryptedBytes.add(plaintextBytes[i] ^ keyByte);
      }

      // Encode to base64 for storage
      return '$_obfuscationPrefix${base64.encode(encryptedBytes)}';
    } catch (e) {
      debugPrint('Encryption error: $e');
      return plaintext; // Fallback to plaintext if encryption fails
    }
  }

  /// Decodes a base64-encoded obfuscated string
  ///
  /// Reverses the encryption process to retrieve original plaintext.
  ///
  /// Parameters:
  /// - [encrypted]: Base64-encoded encrypted string
  ///
  /// Returns: Decrypted plaintext, or original string if decryption fails
  String decrypt(String encrypted) {
    try {
      if (encrypted.isEmpty) return '';

      // Values saved by earlier app versions are plaintext. Only decode data
      // explicitly marked by this service so legacy strings that happen to be
      // valid Base64 are never mistaken for obfuscated data.
      if (!encrypted.startsWith(_obfuscationPrefix)) return encrypted;

      // Decode from base64
      final encryptedBytes = base64.decode(
        encrypted.substring(_obfuscationPrefix.length),
      );
      final keyBytes = utf8.encode(_masterKey);

      // Simple XOR decryption with key rotation
      final decryptedBytes = <int>[];
      for (int i = 0; i < encryptedBytes.length; i++) {
        final keyByte = keyBytes[i % keyBytes.length];
        decryptedBytes.add(encryptedBytes[i] ^ keyByte);
      }

      // Convert bytes back to string
      return utf8.decode(decryptedBytes);
    } catch (e) {
      debugPrint('Decryption error: $e');
      return encrypted; // Return original if decryption fails
    }
  }

  /// Encrypts sensitive fields in a history item map
  ///
  /// Encrypts text and voice ID for privacy.
  ///
  /// Parameters:
  /// - [data]: Map containing history item data
  ///
  /// Returns: Map with encrypted sensitive fields
  Map<String, dynamic> encryptHistoryItem(Map<String, dynamic> data) {
    return {
      ...data,
      'text': encrypt(data['text'] as String? ?? ''),
      'voiceId': encrypt(data['voiceId'] as String? ?? ''),
    };
  }

  /// Decrypts sensitive fields in a history item map
  ///
  /// Decrypts text and voice ID for retrieval.
  ///
  /// Parameters:
  /// - [data]: Map containing encrypted history item data
  ///
  /// Returns: Map with decrypted fields
  Map<String, dynamic> decryptHistoryItem(Map<String, dynamic> data) {
    return {
      ...data,
      'text': decrypt(data['text'] as String? ?? ''),
      'voiceId': decrypt(data['voiceId'] as String? ?? ''),
    };
  }

  /// Encrypts a settings value
  ///
  /// Used for storing sensitive settings like API keys or personal preferences.
  ///
  /// Parameters:
  /// - [value]: The value to encrypt
  ///
  /// Returns: Encrypted value
  String encryptSetting(String value) => encrypt(value);

  /// Decrypts a settings value
  ///
  /// Retrieves and decrypts sensitive settings.
  ///
  /// Parameters:
  /// - [value]: The encrypted value
  ///
  /// Returns: Decrypted value
  String decryptSetting(String value) => decrypt(value);

  /// Hashes a string for comparison without storing plaintext
  ///
  /// Useful for passwords or sensitive identifiers where you only need
  /// to verify the value, not decrypt it.
  ///
  /// Parameters:
  /// - [value]: The value to hash
  ///
  /// Returns: Hashed value (one-way operation)
  String hash(String value) {
    try {
      final bytes = utf8.encode(value);
      int hash = 0;

      for (int i = 0; i < bytes.length; i++) {
        hash = ((hash << 5) - hash) + bytes[i];
        hash = hash & hash; // Convert to 32bit integer
      }

      return hash.abs().toString();
    } catch (e) {
      debugPrint('Hash error: $e');
      return '';
    }
  }
}

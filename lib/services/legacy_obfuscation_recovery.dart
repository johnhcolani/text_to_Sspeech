import 'dart:convert';

/// Compatibility helper for the accidental history-obfuscation build.
///
/// Two variants briefly existed during development:
/// 1. `obf:v1:<base64>` (the later, marked format)
/// 2. raw Base64 without the `obf:v1:` marker
///
/// The raw form is only decoded when the value is valid Base64 and the XOR
/// result is valid, plausible text. This keeps normal plaintext untouched.
class LegacyObfuscationRecovery {
  LegacyObfuscationRecovery._();

  static const String _prefix = 'obf:v1:';
  static const String _key = 'tts_app_secure_key_2024';
  static final RegExp _base64Candidate = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');

  static String recover(String value) {
    if (value.isEmpty) return value;

    if (value.startsWith(_prefix)) {
      return _decodePayload(value.substring(_prefix.length)) ?? value;
    }

    // The accidental early build wrote the Base64 payload without a marker.
    // Be conservative so ordinary words/settings are not mistaken for it.
    if (value.length < 8 ||
        value.length % 4 != 0 ||
        !_base64Candidate.hasMatch(value)) {
      return value;
    }

    final decoded = _decodePayload(value);
    if (decoded == null || !_looksLikePlainText(decoded)) return value;
    return decoded;
  }

  static String? _decodePayload(String payload) {
    try {
      final encryptedBytes = base64.decode(payload);
      final keyBytes = utf8.encode(_key);
      final decodedBytes = List<int>.generate(
        encryptedBytes.length,
        (index) => encryptedBytes[index] ^ keyBytes[index % keyBytes.length],
        growable: false,
      );
      return utf8.decode(decodedBytes, allowMalformed: false);
    } catch (_) {
      return null;
    }
  }

  static bool _looksLikePlainText(String value) {
    if (value.isEmpty || value.contains('\uFFFD')) return false;

    var printable = 0;
    var controls = 0;
    for (final rune in value.runes) {
      if (rune == 9 || rune == 10 || rune == 13) {
        printable++;
      } else if (rune < 32 || (rune >= 127 && rune < 160)) {
        controls++;
      } else {
        printable++;
      }
    }

    if (controls > 0) return false;
    if (printable == 0) return false;

    // Require at least one letter, digit, space, or common punctuation mark.
    return RegExp(r'[A-Za-z0-9\s.,!?;:\-()\u0080-\uFFFF]').hasMatch(value);
  }
}

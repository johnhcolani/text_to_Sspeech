import 'dart:io';

import 'package:flutter/services.dart';

/// Android-specific bridge used for reliable file synthesis.
///
/// This bypasses flutter_tts path handling so the app receives the exact
/// generated file path and can then encode/export it as a real MP3.
class AndroidTtsFileService {
  AndroidTtsFileService._();

  static const MethodChannel _channel = MethodChannel(
    'text_to_speech/android_audio_export',
  );

  static Future<String?> synthesizeToWav({
    required String text,
    required String voiceName,
    required String language,
    required double rate,
    required double pitch,
    required double volume,
  }) async {
    if (!Platform.isAndroid || text.trim().isEmpty) return null;

    return _channel.invokeMethod<String>('synthesizeToWav', {
      'text': text,
      'voiceName': voiceName,
      'language': language,
      'rate': rate,
      'pitch': pitch,
      'volume': volume,
    });
  }
}

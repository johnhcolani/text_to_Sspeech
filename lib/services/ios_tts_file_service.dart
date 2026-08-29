import 'dart:io';

import 'package:flutter/services.dart';

/// iOS-specific bridge used for reliable file synthesis.
///
/// flutter_tts can choose its own output location on iOS, which makes an
/// absolute path unreliable for history/export flows. This bridge delegates
/// synthesis to the app's iOS runner and returns the exact WAV path created.
class IosTtsFileService {
  static const MethodChannel _channel = MethodChannel(
    'text_to_speech/ios_audio_export',
  );

  static Future<String?> synthesizeToWav({
    required String text,
    required String voiceName,
    required String language,
    required double rate,
    required double pitch,
    required double volume,
  }) async {
    if (!Platform.isIOS || text.trim().isEmpty) return null;

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

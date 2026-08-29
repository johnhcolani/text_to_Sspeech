import 'dart:io';

import 'package:flutter/services.dart';

/// macOS-specific bridge used for reliable file synthesis.
///
/// flutter_tts currently writes macOS synthesized files to its own Documents
/// location and does not reliably honor an absolute destination path. This
/// bridge delegates file generation to the app's macOS runner so export can use
/// a real WAV file with the requested voice/rate/pitch settings.
class MacOsTtsFileService {
  static const MethodChannel _channel = MethodChannel(
    'text_to_speech/macos_audio_export',
  );

  static Future<String?> synthesizeToWav({
    required String text,
    required String voiceName,
    required String language,
    required double rate,
    required double pitch,
    required double volume,
  }) async {
    if (!Platform.isMacOS || text.trim().isEmpty) return null;

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

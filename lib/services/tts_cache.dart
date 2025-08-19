import 'dart:io';
import 'package:flutter/foundation.dart'; // Added for debugPrint
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Implement this to fetch bytes from your cloud TTS (Google/Azure/Polly/etc).
/// Return raw audio bytes (mp3/wav/m4a). Throw on failure.
abstract class CloudTtsFetcher {
  Future<Uint8List> fetchTtsBytes({
    required String text,
    required String voiceId,
    required double rate,
    required double pitch,
    String format = 'mp3',
  });
}

class TtsCache {
  TtsCache({required this.localSynth, this.cloud});
  final Future<String?> Function(String text)
  localSynth; // calls flutter_tts.synthesizeToFile
  final CloudTtsFetcher? cloud; // optional

  /// Ensures there is a local audio file for [text]. Returns a file path or null.
  /// Strategy:
  /// 1) Try local synth (fastest, no network if supported).
  /// 2) If local fails and we are online and cloud fetcher is provided, call cloud and save bytes.
  /// 3) If neither works, return null but don't treat as error.
  Future<String?> ensureCached({
    required String text,
    required String voiceId,
    required double rate,
    required double pitch,
    String preferredExt =
        'wav', // Changed to wav for better car audio compatibility
  }) async {
    final normalized = text.trim();
    if (normalized.isEmpty) return null;

    // 1) Try local with high-quality settings
    try {
      final local = await localSynth(normalized);
      if (local != null && File(local).existsSync()) {
        // Verify file quality and size
        final file = File(local);
        final size = await file.length();
        if (size > 1024) {
          // Ensure file is not empty/corrupted
          debugPrint('Local synthesis successful: $local (${size} bytes)');
          return local;
        } else {
          debugPrint('Local synthesis file too small: ${size} bytes');
        }
      }
    } catch (e) {
      debugPrint('Local synthesis failed: $e');
    }

    // 2) Cloud fallback only if online & cloud fetcher exists
    if (cloud == null) {
      debugPrint('No cloud TTS available for fallback');
      return null;
    }
    
    final online = await _hasConnectivity();
    if (!online) {
      debugPrint('No internet connection for cloud TTS fallback');
      return null;
    }

    try {
      debugPrint('Attempting cloud TTS fallback...');
      final bytes = await cloud!.fetchTtsBytes(
        text: normalized,
        voiceId: voiceId,
        rate: rate,
        pitch: pitch,
        format: preferredExt,
      );
      final out = await _writeBytes(bytes, preferredExt);
      debugPrint('Cloud TTS successful: ${out.path}');
      return out.path;
    } catch (e) {
      debugPrint('Cloud TTS fallback failed: $e');
      return null;
    }
  }

  Future<bool> _hasConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<File> _writeBytes(Uint8List bytes, String ext) async {
    final dir = await getApplicationDocumentsDirectory();
    final id = const Uuid().v4();
    final outPath = p.join(dir.path, 'tts_$id.$ext');
    final f = File(outPath);
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }
}

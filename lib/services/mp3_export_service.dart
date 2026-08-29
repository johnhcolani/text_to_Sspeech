import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_lame/flutter_lame.dart';
import 'package:path/path.dart' as p;
import 'package:wav/wav.dart';

/// Produces a real MP3 file for user-facing exports.
///
/// Older app builds sometimes copied WAV bytes to a path ending in `.mp3`.
/// This service detects the actual file signature instead of trusting the
/// extension, and encodes WAV/PCM data with LAME when needed.
class Mp3ExportService {
  Mp3ExportService._();

  static Future<File> prepareRealMp3(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('Audio source file does not exist.');
    }

    final header = await _readHeader(source, 12);
    if (_looksLikeMp3(header)) {
      return source;
    }

    if (!_looksLikeWav(header)) {
      throw StateError(
        'This saved audio is not a supported WAV/MP3 file and cannot be exported as MP3.',
      );
    }

    final outputPath = p.join(
      Directory.systemTemp.path,
      'tts_export_${DateTime.now().microsecondsSinceEpoch}.mp3',
    );

    final wav = await compute(Wav.readFile, sourcePath);
    if (wav.channels.isEmpty || wav.channels.length > 2) {
      throw StateError('Unsupported WAV channel layout.');
    }

    final encoder = LameMp3Encoder(
      sampleRate: wav.samplesPerSecond,
      numChannels: wav.channels.length,
    );
    final output = File(outputPath);
    final sink = output.openWrite();

    try {
      final Float64List left = wav.channels[0];
      final Float64List? right =
          wav.channels.length > 1 ? wav.channels[1] : null;
      final chunkSize = math.max(1024, wav.samplesPerSecond);

      for (var start = 0; start < left.length; start += chunkSize) {
        final end = math.min(start + chunkSize, left.length);
        final frame = await encoder.encodeDouble(
          leftChannel: left.sublist(start, end),
          rightChannel: right?.sublist(start, end),
        );
        if (frame.isNotEmpty) sink.add(frame);
      }

      final tail = await encoder.flush();
      if (tail.isNotEmpty) sink.add(tail);
      await sink.flush();
      await sink.close();
    } catch (_) {
      await sink.close();
      if (await output.exists()) {
        await output.delete();
      }
      rethrow;
    } finally {
      encoder.close();
    }

    final encodedHeader = await _readHeader(output, 10);
    if (!await output.exists() ||
        await output.length() < 256 ||
        !_looksLikeMp3(encodedHeader)) {
      if (await output.exists()) await output.delete();
      throw StateError('MP3 encoding did not produce a valid file.');
    }

    return output;
  }

  static Future<Uint8List> _readHeader(File file, int length) async {
    final randomAccess = await file.open();
    try {
      return await randomAccess.read(length);
    } finally {
      await randomAccess.close();
    }
  }

  static bool _looksLikeWav(Uint8List bytes) {
    if (bytes.length < 12) return false;
    return String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WAVE';
  }

  static bool _looksLikeMp3(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0x49 &&
        bytes[1] == 0x44 &&
        bytes[2] == 0x33) {
      return true; // ID3 tag
    }

    return bytes.length >= 2 &&
        bytes[0] == 0xFF &&
        (bytes[1] & 0xE0) == 0xE0; // MPEG audio frame sync
  }
}

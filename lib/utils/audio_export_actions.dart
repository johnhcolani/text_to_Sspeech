import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../model/tts_history_item.dart';
import '../providers/history_provider.dart';
import '../providers/tts_provider.dart';

/// Exports the audio associated with a history item using the platform-native
/// Save As flow.
///
/// If an older history entry does not have a usable audio file yet, the audio
/// is regenerated from the saved text/voice/rate/pitch settings first and the
/// new local file path is persisted back to history.
///
/// Returns the destination path reported by the platform, or `null` if the
/// user cancels the save dialog.
Future<String?> exportHistoryAudio({
  required TtsHistoryItem item,
  required TTSProvider ttsProvider,
  required HistoryProvider historyProvider,
}) async {
  String? sourcePath = item.filePath;

  if (sourcePath == null || !await File(sourcePath).exists()) {
    sourcePath = await _regenerateHistoryAudio(
      item: item,
      ttsProvider: ttsProvider,
      historyProvider: historyProvider,
    );
  }

  if (sourcePath == null || !await File(sourcePath).exists()) {
    throw StateError('Audio file could not be generated on this device.');
  }

  final sourceFile = File(sourcePath);
  final bytes = await sourceFile.readAsBytes();
  final extension = _safeAudioExtension(sourcePath);
  final fileName = _buildExportFileName(item.createdAt, extension);

  return FilePicker.platform.saveFile(
    dialogTitle: 'Export Audio',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: [extension],
    bytes: bytes,
  );
}

Future<String?> _regenerateHistoryAudio({
  required TtsHistoryItem item,
  required TTSProvider ttsProvider,
  required HistoryProvider historyProvider,
}) async {
  final originalText = ttsProvider.text;
  final originalVoice = ttsProvider.selectedVoice;
  final originalRate = ttsProvider.rate;
  final originalPitch = ttsProvider.pitch;

  try {
    await ttsProvider.setText(item.text);
    await ttsProvider.setVoice(item.voiceId);
    await ttsProvider.setRate(item.rate);
    await ttsProvider.setPitch(item.pitch);

    final generatedPath = await ttsProvider.synthesizeToFileHighQuality();
    if (generatedPath != null && await File(generatedPath).exists()) {
      await historyProvider.updateFilePath(item.id, generatedPath);
      return generatedPath;
    }

    return null;
  } finally {
    // Restore the user's current editing/playback settings after regenerating
    // an older history item for export.
    await ttsProvider.setText(originalText);
    await ttsProvider.setVoice(originalVoice);
    await ttsProvider.setRate(originalRate);
    await ttsProvider.setPitch(originalPitch);
  }
}

String _safeAudioExtension(String sourcePath) {
  final extension = p.extension(sourcePath).replaceFirst('.', '').toLowerCase();
  if (extension == 'mp3' || extension == 'wav' || extension == 'm4a') {
    return extension;
  }
  return 'wav';
}

String _buildExportFileName(DateTime createdAt, String extension) {
  final local = createdAt.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');

  final timestamp =
      '${local.year}-${two(local.month)}-${two(local.day)}_'
      '${two(local.hour)}-${two(local.minute)}-${two(local.second)}';

  return 'tts_$timestamp.$extension';
}

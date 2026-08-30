import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../model/tts_history_item.dart';
import '../providers/history_provider.dart';
import '../providers/tts_provider.dart';
import '../services/android_tts_file_service.dart';
import '../services/ios_tts_file_service.dart';
import '../services/macos_tts_file_service.dart';
import '../services/mp3_export_service.dart';

/// Exports the audio associated with a history item using the platform-native
/// Save As flow.
///
/// If an older history entry does not have a usable audio file yet, the audio
/// is regenerated from the saved text/voice/rate/pitch settings first and the
/// new local file path is persisted back to history.
///
/// User-facing exports are always a real MP3. Older builds sometimes stored
/// WAV bytes behind an `.mp3` extension; Mp3ExportService detects the actual
/// file signature and encodes the WAV with LAME instead of renaming it.
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

  final mp3File = await Mp3ExportService.prepareRealMp3(sourcePath);
  final isTemporaryMp3 = mp3File.path != sourcePath;

  try {
    final bytes = await mp3File.readAsBytes();
    final fileName = _buildExportFileName(item.createdAt, 'mp3');

    return await FilePicker.platform.saveFile(
      dialogTitle: 'Export Audio',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['mp3'],
      bytes: bytes,
    );
  } finally {
    if (isTemporaryMp3 && await mp3File.exists()) {
      await mp3File.delete();
    }
  }
}

Future<String?> _regenerateHistoryAudio({
  required TtsHistoryItem item,
  required TTSProvider ttsProvider,
  required HistoryProvider historyProvider,
}) async {
  // Android flutter_tts may save synthesized files outside the exact path the
  // app supplied unless full-path mode is used. Generate inside our own app
  // container so export always receives a known, readable source file.
  if (Platform.isAndroid) {
    final generatedPath = await AndroidTtsFileService.synthesizeToWav(
      text: item.text,
      voiceName: item.voiceId,
      language: _languageForHistoryItem(item, ttsProvider),
      rate: item.rate,
      pitch: item.pitch,
      volume: ttsProvider.volume,
    );

    if (generatedPath != null && await File(generatedPath).exists()) {
      await historyProvider.updateFilePath(item.id, generatedPath);
      return generatedPath;
    }

    return null;
  }

  // iOS flutter_tts can choose its own Documents output location. Generate the
  // WAV in our own app container so export always receives the exact file path.
  if (Platform.isIOS) {
    final generatedPath = await IosTtsFileService.synthesizeToWav(
      text: item.text,
      voiceName: item.voiceId,
      language: _languageForHistoryItem(item, ttsProvider),
      rate: item.rate,
      pitch: item.pitch,
      volume: ttsProvider.volume,
    );

    if (generatedPath != null && await File(generatedPath).exists()) {
      await historyProvider.updateFilePath(item.id, generatedPath);
      return generatedPath;
    }

    return null;
  }

  // flutter_tts has a macOS path-handling limitation in synthesizeToFile.
  // Use our native AVSpeechSynthesizer bridge there so the generated file is
  // written to a known path and the requested voice settings are applied.
  if (Platform.isMacOS) {
    final generatedPath = await MacOsTtsFileService.synthesizeToWav(
      text: item.text,
      voiceName: item.voiceId,
      language: _languageForHistoryItem(item, ttsProvider),
      rate: item.rate,
      pitch: item.pitch,
      volume: ttsProvider.volume,
    );

    if (generatedPath != null && await File(generatedPath).exists()) {
      await historyProvider.updateFilePath(item.id, generatedPath);
      return generatedPath;
    }

    return null;
  }

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

String _languageForHistoryItem(
  TtsHistoryItem item,
  TTSProvider ttsProvider,
) {
  if (item.voiceId.isNotEmpty) {
    for (final voice in ttsProvider.voices) {
      if (voice['name'] == item.voiceId) {
        final locale = voice['locale'];
        if (locale != null && locale.isNotEmpty) return locale;
      }
    }
  }

  // Older history rows may not contain a voice name. In that case use the
  // app's currently selected language and let the platform choose its default
  // voice when regenerating.
  return ttsProvider.selectedLanguage;
}

String _buildExportFileName(DateTime createdAt, String extension) {
  final local = createdAt.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');

  final timestamp =
      '${local.year}-${two(local.month)}-${two(local.day)}_'
      '${two(local.hour)}-${two(local.minute)}-${two(local.second)}';

  return 'tts_$timestamp.$extension';
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../model/tts_history_item.dart';
import '../providers/tts_provider.dart';
import '../providers/history_provider.dart';

Future<void> playAndSaveToHistory(BuildContext context, TTSProvider ttsProvider, HistoryProvider historyProvider) async {
  // 1) Play using the correct method name
  await ttsProvider.speak();

  // 2) Try to export to file (if supported)
  final path = await ttsProvider.synthesizeToFile();

  // 3) Save metadata + optional file path
  final item = TtsHistoryItem(
    id: const Uuid().v4(),
    text: ttsProvider.text,
    filePath: path,
    voiceId: ttsProvider.selectedVoice, // Fixed: use selectedVoice instead of voiceId
    rate: ttsProvider.rate,
    pitch: ttsProvider.pitch,
    createdAt: DateTime.now(),
  );
  await historyProvider.add(item);
}

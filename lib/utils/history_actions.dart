import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../model/tts_history_item.dart';
import '../providers/tts_provider.dart';
import '../providers/history_provider.dart';

Future<void> playAndSaveToHistory(BuildContext context, TTSProvider ttsProvider, HistoryProvider historyProvider) async {
  try {
    // 1) Play using the correct method name
    await ttsProvider.speak();

    // 2) Try to export to file (if supported)
    final path = await ttsProvider.synthesizeToFile();

    // 3) Save metadata + optional file path
    final item = TtsHistoryItem(
      id: const Uuid().v4(),
      text: ttsProvider.text,
      filePath: path,
      voiceId: ttsProvider.selectedVoice,
      rate: ttsProvider.rate,
      pitch: ttsProvider.pitch,
      createdAt: DateTime.now(),
    );
    await historyProvider.add(item);

    // 4) Show success feedback
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  path != null 
                    ? 'Audio saved to history with export file'
                    : 'Audio saved to history',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  } catch (e) {
    // Show error feedback
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Failed to save to history: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}

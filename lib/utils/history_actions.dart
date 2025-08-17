import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tts_provider.dart';
import '../providers/history_provider.dart';
import '../model/tts_history_item.dart';
import 'package:uuid/uuid.dart';

Future<void> playAndSaveToHistory(
  BuildContext context,
  TTSProvider ttsProvider,
  HistoryProvider historyProvider,
) async {
  try {
    // 1) Play using the correct method name
    await ttsProvider.speak();

    // 2) Try to export to high-quality file (if supported)
    String? path;

    // Check if device supports file synthesis
    final supportsFileSynthesis = await ttsProvider.isFileSynthesisSupported();
    if (supportsFileSynthesis) {
      path = await ttsProvider.synthesizeToFileHighQuality();
    }

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
              Icon(
                path != null ? Icons.check_circle : Icons.info_outline,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  path != null
                      ? 'High-quality audio saved to history'
                      : 'Audio saved to history (live TTS only)',
                ),
              ),
            ],
          ),
          backgroundColor: path != null ? Colors.green : Colors.blue,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}

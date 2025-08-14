import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../model/tts_history_item.dart';
import '../providers/tts_provider.dart';
import '../providers/history_provider.dart';

Future<void> playAndCacheNow(BuildContext context) async {
  final tts = context.read<TTSProvider>();
  final hp = context.read<HistoryProvider>();

  // Check if device supports file synthesis
  final supportsFileSynthesis = await tts.isFileSynthesisSupported();
  
  if (!supportsFileSynthesis) {
    // Device doesn't support file synthesis, just play and save metadata
    await tts.speak();
    
    // Save to history without file path
    final item = TtsHistoryItem(
      id: const Uuid().v4(),
      text: tts.text,
      filePath: null, // No file path available
      voiceId: tts.selectedVoice,
      rate: tts.rate,
      pitch: tts.pitch,
      createdAt: DateTime.now(),
    );
    await hp.add(item);
    
    // Show info message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Device doesn\'t support offline audio. Playing with live TTS.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return;
  }

  // 1) Ensure we have a local file (local synth or cloud)
  final path = await tts.cache.ensureCached(
    text: tts.text,
    voiceId: tts.selectedVoice,
    rate: tts.rate,
    pitch: tts.pitch,
    preferredExt: 'wav', // Use WAV for better car audio compatibility
  );

  if (path == null) {
    // Last resort: just speak (streaming), but warn user it isn't cached
    await tts.speak();
    
    // Save to history without file path
    final item = TtsHistoryItem(
      id: const Uuid().v4(),
      text: tts.text,
      filePath: null,
      voiceId: tts.selectedVoice,
      rate: tts.rate,
      pitch: tts.pitch,
      createdAt: DateTime.now(),
    );
    await hp.add(item);
    
    // Show warning message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Could not cache audio. Playing with live TTS.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return;
  }

  // 2) Save/Update history with the path
  final item = TtsHistoryItem(
    id: const Uuid().v4(),
    text: tts.text,
    filePath: path,
    voiceId: tts.selectedVoice,
    rate: tts.rate,
    pitch: tts.pitch,
    createdAt: DateTime.now(),
  );
  await hp.add(item);

  // 3) Play from file using high-quality audio player
  try {
    await tts.playSavedAudio(path);
  } catch (e) {
    debugPrint('Error playing cached audio: $e');
    // Fallback to TTS
    await tts.speak();
  }
}

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

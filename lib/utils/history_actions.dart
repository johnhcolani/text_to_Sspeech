import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../model/tts_history_item.dart';
import '../providers/tts_provider.dart';
import '../providers/history_provider.dart';

Future<void> playAndSaveToHistory(context) async {
  final tts = context.read<TTSProvider>();

  // 1) Play using your existing method
  await tts.play(); // or whatever your method name is

  // 2) Try to export to file (if supported)
  final path = await tts.synthesizeToFile();

  // 3) Save metadata + optional file path
  final item = TtsHistoryItem(
    id: const Uuid().v4(),
    text: tts.text,
    filePath: path,
    voiceId: tts.voiceId,
    rate: tts.rate,
    pitch: tts.pitch,
    createdAt: DateTime.now(),
  );
  await context.read<HistoryProvider>().add(item);
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../model/tts_history_item.dart';
import '../providers/history_provider.dart';
import '../providers/tts_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    // HistoryProvider.load() is already called in main
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play(TtsHistoryItem item) async {
    if (item.filePath != null && File(item.filePath!).existsSync()) {
      await _player.setFilePath(item.filePath!);
      await _player.play();
    } else {
      // Fallback: speak from TTS if there is no file stored
      final tts = context.read<TTSProvider>();
      await tts.playText(item.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, hp, _) {
        final items = hp.items;
        return Scaffold(
          appBar: AppBar(
            title: const Text('History'),
            actions: [
              if (items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: 'Clear all',
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Clear history?'),
                        content: const Text('This removes all saved items.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) await hp.clear();
                  },
                ),
            ],
          ),
          body: items.isEmpty
              ? const Center(child: Text('No saved items yet'))
              : ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final it = items[i];
              return Dismissible(
                key: ValueKey(it.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.redAccent,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => hp.remove(it.id),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete item?'),
                      content: const Text('This will remove it from history.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                child: ListTile(
                  leading: Icon(it.filePath != null ? Icons.audiotrack : Icons.history),
                  title: Text(
                    it.text.length > 60 ? '${it.text.substring(0, 60)}…' : it.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${it.voiceId} • rate ${it.rate.toStringAsFixed(2)} • pitch ${it.pitch.toStringAsFixed(2)}\n'
                        '${it.createdAt}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => _play(it),
                  ),
                  onTap: () => _play(it),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

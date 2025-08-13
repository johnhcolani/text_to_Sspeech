import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

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

  // Track which item is active and whether playback is via TTS or file
  String? _currentId;
  bool _usingTts = false; // should be false most of the time now (offline playback)

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    // Configure audio session for speech (routes correctly, ducks music)
    AudioSession.instance.then((session) {
      session.configure(const AudioSessionConfiguration.speech());
    });

    // Clear selection when local file finishes
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _player.stop();
        setState(() {
          _currentId = null;
          _usingTts = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _ensureOffline(TtsHistoryItem item) async {
    final tts = context.read<TTSProvider>();
    final hp = context.read<HistoryProvider>();

    // Reapply saved settings to match original sound
    await tts.setVoice(item.voiceId);
    tts.setRate(item.rate);
    tts.setPitch(item.pitch);

    final path = await tts.synthesizeToFile();
    if (path == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save offline audio on this device/voice.')),
      );
      return;
    }

    await hp.updateFilePath(item.id, path);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Offline audio saved.')),
    );

    // Re-fetch the updated item (with filePath) and start playing it
    final updated = hp.items.firstWhere((e) => e.id == item.id, orElse: () => item);
    await _startItem(updated);
  }

  Future<void> _startItem(TtsHistoryItem item) async {
    // Stop any current playback
    await _stopCurrent();

    final path = item.filePath;
    final hasFile = path != null && File(path).existsSync();

    if (!hasFile) {
      // No local file → ask to generate (do NOT stream online here)
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Offline file missing'),
          content: const Text('Generate and save offline audio for this item?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      );
      if (ok == true) await _ensureOffline(item);
      return;
    }

    // Play saved audio file
    try {
      await _player.setFilePath(path!);
      await _player.play();
      setState(() {
        _currentId = item.id;
        _usingTts = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not play saved audio: $e')),
      );
    }
  }

  Future<void> _pauseItem() async {
    if (_currentId == null) return;
    if (_usingTts) {
      await context.read<TTSProvider>().pause();
    } else {
      if (_player.playing) {
        await _player.pause();
      }
    }
    setState(() {}); // refresh buttons
  }

  Future<void> _resumeItem() async {
    if (_currentId == null) return;
    if (_usingTts) {
      await context.read<TTSProvider>().resume();
    } else {
      await _player.play();
    }
    setState(() {});
  }

  Future<void> _stopCurrent() async {
    if (_currentId == null) return;
    if (_usingTts) {
      await context.read<TTSProvider>().stop();
    } else {
      await _player.stop();
    }
    setState(() {
      _currentId = null;
      _usingTts = false;
    });
  }

  bool _isCurrent(String id) => _currentId == id;

  Widget _buildControls(BuildContext context, TtsHistoryItem item) {
    final isCurrent = _isCurrent(item.id);
    final ttsState = context.watch<TTSProvider>().ttsState;

    final isFilePlaying = !_usingTts && _player.playing && isCurrent;
    final isFilePaused = !_usingTts &&
        !(_player.playing) &&
        isCurrent &&
        _player.playerState.processingState == ProcessingState.ready;

    final isTtsPlaying = _usingTts && isCurrent && ttsState == TTSState.playing;
    final isTtsPaused = _usingTts && isCurrent && ttsState == TTSState.paused;

    final showPause = isFilePlaying || isTtsPlaying;
    final showResume = isFilePaused || isTtsPaused;
    final showStop = isCurrent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isCurrent || showResume)
          IconButton(
            tooltip: showResume ? 'Resume' : 'Play',
            icon: Icon(showResume ? Icons.play_arrow : Icons.play_circle),
            onPressed: () => isCurrent ? _resumeItem() : _startItem(item),
          ),
        if (showPause)
          IconButton(
            tooltip: 'Pause',
            icon: const Icon(Icons.pause_circle),
            onPressed: _pauseItem,
          ),
        if (showStop)
          IconButton(
            tooltip: 'Stop',
            icon: const Icon(Icons.stop_circle),
            onPressed: _stopCurrent,
          ),
      ],
    );
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
                    if (ok == true) {
                      await _stopCurrent();
                      await hp.clear();
                    }
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
              final hasLocal =
                  it.filePath != null && File(it.filePath!).existsSync();

              return Dismissible(
                key: ValueKey(it.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.redAccent,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
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
                onDismissed: (_) async {
                  if (_isCurrent(it.id)) {
                    await _stopCurrent();
                  }
                  await hp.remove(it.id);
                },
                child: ListTile(
                  leading: Icon(
                    hasLocal ? Icons.audiotrack : Icons.cloud_download,
                  ),
                  title: Text(
                    it.text.length > 60
                        ? '${it.text.substring(0, 60)}…'
                        : it.text,
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!hasLocal)
                        IconButton(
                          tooltip: 'Save offline',
                          icon: const Icon(Icons.download_for_offline),
                          onPressed: () => _ensureOffline(it),
                        ),
                      _buildControls(context, it),
                    ],
                  ),
                  onTap: () => _startItem(it),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

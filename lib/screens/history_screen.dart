import 'dart:io';

import 'package:flutter/material.dart';
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
  // Track which item is active
  String? _currentId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _ensureOffline(TtsHistoryItem item) async {
    final tts = context.read<TTSProvider>();
    final hp = context.read<HistoryProvider>();

    // First check if the device supports file synthesis
    final supportsFileSynthesis = await tts.isFileSynthesisSupported();
    
    if (!supportsFileSynthesis) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This device doesn\'t support saving offline audio. Playing with live TTS instead.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Play directly with TTS instead of trying to save
      await _startItem(item);
      return;
    }

    // Try to save offline audio
    final path = await tts.cache.ensureCached(
      text: item.text,
      voiceId: item.voiceId,
      rate: item.rate,
      pitch: item.pitch,
    );
    
    if (path == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Could not save offline audio. Playing with live TTS instead.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Fallback to live TTS
      await _startItem(item);
      return;
    }

    // Successfully saved offline audio
    await hp.updateFilePath(item.id, path);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Offline audio saved successfully!',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    final updated = hp.items.firstWhere(
      (e) => e.id == item.id,
      orElse: () => item,
    );
    await _startItem(updated);
  }

  Future<void> _startItem(TtsHistoryItem item) async {
    // Stop any current playback
    await _stopCurrent();

    final tts = context.read<TTSProvider>();

    // Check if we have a saved audio file for high-quality playback
    if (item.filePath != null && File(item.filePath!).existsSync()) {
      // Use high-quality audio playback for saved files
      await tts.playSavedAudio(item.filePath!);
    } else {
      // Fallback to TTS synthesis
      await tts.setVoice(item.voiceId);
      tts.setRate(item.rate);
      tts.setPitch(item.pitch);
      tts.setText(item.text);
      await tts.speak();
    }

    setState(() {
      _currentId = item.id;
    });
  }

  Future<void> _pauseItem() async {
    if (_currentId == null) return;
    final tts = context.read<TTSProvider>();

    // Check if we're playing saved audio
    if (tts.isPlayingSavedAudio) {
      await tts.pauseSavedAudio();
    } else {
      await tts.pause();
    }

    setState(() {}); // refresh buttons
  }

  Future<void> _resumeItem() async {
    if (_currentId == null) return;
    final tts = context.read<TTSProvider>();

    // Check if we're playing saved audio
    if (tts.isPlayingSavedAudio) {
      await tts.resumeSavedAudio();
    } else {
      await tts.resume();
    }

    setState(() {});
  }

  Future<void> _stopCurrent() async {
    if (_currentId == null) return;
    final tts = context.read<TTSProvider>();

    // Check if we're playing saved audio
    if (tts.isPlayingSavedAudio) {
      await tts.stopSavedAudio();
    } else {
      await tts.stop();
    }

    setState(() {
      _currentId = null;
    });
  }

  bool _isCurrent(String id) => _currentId == id;

  Widget _buildControls(BuildContext context, TtsHistoryItem item) {
    final isCurrent = _isCurrent(item.id);
    final ttsState = context.watch<TTSProvider>().ttsState;

    final isPlaying = isCurrent && ttsState == TTSState.playing;
    final isPaused = isCurrent && ttsState == TTSState.paused;

    final showPause = isPlaying;
    final showResume = isPaused;
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
    return Scaffold(
      backgroundColor: const Color(
        0xFF293a4c,
      ), // Using the same color as splash screen
      appBar: AppBar(
        title: const Text(
          'TTS History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF293a4c),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer2<TTSProvider, HistoryProvider>(
        builder: (context, ttsProvider, historyProvider, child) {
          final history = historyProvider.items;

          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No TTS history yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start converting text to speech to see your history here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return _buildHistoryItem(
                context,
                item,
                ttsProvider,
                historyProvider,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    TtsHistoryItem item,
    TTSProvider ttsProvider,
    HistoryProvider historyProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          item.text.length > 100
              ? '${item.text.substring(0, 100)}...'
              : item.text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.voice_chat,
                  size: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'Voice: ${item.voiceId}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.speed,
                  size: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'Rate: ${item.rate.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.tune,
                  size: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'Pitch: ${item.pitch.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(item.createdAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (item.filePath != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.audio_file,
                    size: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Audio file available',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.8)),
          onSelected: (value) {
            switch (value) {
              case 'play':
                _ensureOffline(item);
                break;
              case 'delete':
                _showDeleteDialog(context, item, historyProvider);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'play',
              child: Row(
                children: [
                  Icon(Icons.play_arrow),
                  SizedBox(width: 8),
                  Text('Play'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    TtsHistoryItem item,
    HistoryProvider historyProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF293a4c),
        title: const Text(
          'Delete History Item',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this TTS history item?',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          TextButton(
            onPressed: () {
              historyProvider.remove(item.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('History item deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

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
  // Track which items are expanded to show full text
  Set<String> _expandedItems = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Toggle expansion state of a history item
  void _toggleExpansion(String itemId) {
    setState(() {
      if (_expandedItems.contains(itemId)) {
        _expandedItems.remove(itemId);
      } else {
        _expandedItems.add(itemId);
      }
    });
  }

  // Check if an item is expanded
  bool _isExpanded(String itemId) => _expandedItems.contains(itemId);

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
    ScaffoldMessenger.of(context).showSnackBar(
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

    // Set the current ID FIRST, before starting playback
    if (mounted) {
      setState(() {
        _currentId = item.id;
      });

      // Small delay to ensure UI rebuilds
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final tts = context.read<TTSProvider>();

    // Set the text and voice settings for the reading panel
    tts.setText(item.text);
    tts.setVoice(item.voiceId);
    tts.setRate(item.rate);
    tts.setPitch(item.pitch);

    // Check if we have a saved audio file for high-quality playback
    if (item.filePath != null && File(item.filePath!).existsSync()) {
      // Use high-quality audio playback for saved files
      await tts.playSavedAudio(item.filePath!);
    } else {
      // Fallback to TTS synthesis
      await tts.speak();
    }
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

    if (mounted) {
      setState(() {}); // refresh buttons
    }
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

    if (mounted) {
      setState(() {});
    }
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

    if (mounted) {
      setState(() {
        _currentId = null;
      });
    }
  }

  bool _isCurrent(String id) => _currentId == id;

  Widget _buildControls(BuildContext context, TtsHistoryItem item) {
    final isCurrent = _isCurrent(item.id);
    final ttsState = context.watch<TTSProvider>().ttsState;

    // Treat continued state the same as playing for button logic
    final isPlaying =
        isCurrent &&
        (ttsState == TTSState.playing || ttsState == TTSState.continued);
    final isPaused = isCurrent && ttsState == TTSState.paused;

    // Show buttons based on state
    final showPlay = !isCurrent || (isCurrent && ttsState == TTSState.stopped);
    final showPause = isPlaying;
    final showResume = isPaused;
    final showStop = isPlaying || isPaused; // Show stop when playing or paused

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPlay)
          IconButton(
            tooltip: 'Play',
            icon: const Icon(
              Icons.play_circle,
              color: const Color(
                0xFF64B5F6,
              ), // Light blue for better visibility
            ),
            onPressed: () => _startItem(item),
          ),
        if (showPause)
          IconButton(
            tooltip: 'Pause',
            icon: const Icon(
              Icons.pause_circle,
              color: const Color(0xFFFFB74D), // Orange for pause
            ),
            onPressed: _pauseItem,
          ),
        if (showResume)
          IconButton(
            tooltip: 'Resume',
            icon: const Icon(
              Icons.play_arrow,
              color: const Color(0xFF64B5F6), // Light blue for resume
            ),
            onPressed: _resumeItem,
          ),
        if (showStop)
          IconButton(
            tooltip: 'Stop',
            icon: const Icon(
              Icons.stop_circle,
              color: const Color(0xFFEF5350), // Red for stop
            ),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Tap to play • Use expand button to read full text',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
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
    final isExpanded = _isExpanded(item.id);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteDialog(context, item, historyProvider);
      },
      onDismissed: (direction) {
        historyProvider.remove(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('History item deleted'),
            backgroundColor: Colors.red,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            // Main content with tap to play
            GestureDetector(
              onTap: () => _startItem(item),
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Expand/collapse button
                    IconButton(
                      onPressed: () => _toggleExpansion(item.id),
                      icon: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: const Color(0xFF64B5F6),
                      ),
                      tooltip: isExpanded
                          ? 'Collapse'
                          : 'Expand to read full text',
                    ),
                    // Play controls
                    _buildControls(context, item),
                  ],
                ),
              ),
            ),

            // Expanded text section
            if (isExpanded) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.text_fields,
                          size: 16,
                          color: const Color(0xFF64B5F6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Full Text:',
                          style: TextStyle(
                            color: const Color(0xFF64B5F6),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteDialog(
    BuildContext context,
    TtsHistoryItem item,
    HistoryProvider historyProvider,
  ) {
    return showDialog<bool>(
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
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          TextButton(
            onPressed: () {
              historyProvider.remove(item.id);
              Navigator.pop(context, true);
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

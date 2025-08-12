import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tts_provider.dart';
import '../utils/history_actions.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TTSProvider>(
      builder: (context, ttsProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Panel header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      color: Theme.of(context).colorScheme.tertiary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Playback Controls',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Control buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(ttsProvider.ttsState).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(ttsProvider.ttsState).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(ttsProvider.ttsState),
                            color: _getStatusColor(ttsProvider.ttsState),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getStatusText(ttsProvider.ttsState),
                            style: TextStyle(
                              color: _getStatusColor(ttsProvider.ttsState),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Main control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Play/Pause button
                        _buildControlButton(
                          context: context,
                          onPressed: ttsProvider.text.isEmpty ? null : () {
                            if (ttsProvider.ttsState == TTSState.playing) {
                              ttsProvider.pause();
                            } else if (ttsProvider.ttsState == TTSState.paused) {
                              ttsProvider.resume();
                            } else {
                              ttsProvider.speak();
                            }
                          },
                          icon: _getPlayPauseIcon(ttsProvider.ttsState),
                          label: _getPlayPauseLabel(ttsProvider.ttsState),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          size: 70,
                        ),
                        
                        // Stop button
                        _buildControlButton(
                          context: context,
                          onPressed: ttsProvider.ttsState == TTSState.stopped ? null : ttsProvider.stop,
                          icon: Icons.stop,
                          label: 'Stop',
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(context).colorScheme.onError,
                          size: 50,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Text length info
                    if (ttsProvider.text.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Text Length:',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${ttsProvider.text.length} characters',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play & Save'),
                          onPressed: () async {
                            await playAndSaveToHistory(context);
                            // Optional: jump to History after each play
                            // if (context.mounted) Navigator.pushNamed(context, '/history');
                          },
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.history),
                          label: const Text('History'),
                          onPressed: () => Navigator.pushNamed(context, '/history'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required double size,
  }) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(size / 2),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              size: size * 0.4,
              color: foregroundColor,
            ),
            tooltip: label,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color _getStatusColor(TTSState state) {
    switch (state) {
      case TTSState.playing:
        return Colors.green;
      case TTSState.paused:
        return Colors.orange;
      case TTSState.stopped:
        return Colors.grey;
      case TTSState.continued:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(TTSState state) {
    switch (state) {
      case TTSState.playing:
        return Icons.play_arrow;
      case TTSState.paused:
        return Icons.pause;
      case TTSState.stopped:
        return Icons.stop;
      case TTSState.continued:
        return Icons.play_arrow;
    }
  }

  String _getStatusText(TTSState state) {
    switch (state) {
      case TTSState.playing:
        return 'Playing';
      case TTSState.paused:
        return 'Paused';
      case TTSState.stopped:
        return 'Stopped';
      case TTSState.continued:
        return 'Playing';
    }
  }

  IconData _getPlayPauseIcon(TTSState state) {
    switch (state) {
      case TTSState.playing:
        return Icons.pause;
      case TTSState.paused:
        return Icons.play_arrow;
      default:
        return Icons.play_arrow;
    }
  }

  String _getPlayPauseLabel(TTSState state) {
    switch (state) {
      case TTSState.playing:
        return 'Pause';
      case TTSState.paused:
        return 'Resume';
      default:
        return 'Play';
    }
  }
}

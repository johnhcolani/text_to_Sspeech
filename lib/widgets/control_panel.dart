import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChannels;
import 'package:provider/provider.dart';
import '../providers/tts_provider.dart';
import '../providers/history_provider.dart';
import '../utils/history_actions.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TTSProvider>(
      builder: (context, ttsProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), // Slightly brighter than text input panel
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.25), // Slightly brighter border
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25), // Slightly brighter shadow
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
                  color: const Color(0xFF64B5F6).withOpacity(0.3), // Slightly brighter blue
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      color: const Color(0xFF64B5F6), // Light blue icon
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Playback Controls',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64B5F6), // Light blue text
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
                    // Error display
                    if (ttsProvider.hasError) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF5350).withOpacity(0.25), // Slightly brighter red
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFEF5350).withOpacity(0.5), // Brighter red border
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: const Color(0xFFEF5350), // Red icon
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ttsProvider.lastError ?? 'An error occurred',
                                style: TextStyle(
                                  color: Colors.white, // White text
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          ttsProvider.ttsState,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(
                            ttsProvider.ttsState,
                          ).withOpacity(0.3),
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

                    // Progress indicator
                    if (ttsProvider.progressActive &&
                        ttsProvider.text.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1), // Light white background
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2), // White border
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progress',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8), // White text with opacity
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${(ttsProvider.progressPercentage * 100).toInt()}%',
                                  style: TextStyle(
                                    color: Colors.white, // White text
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: ttsProvider.progressPercentage,
                              backgroundColor: Colors.white.withOpacity(0.2), // White background with opacity
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFF64B5F6), // Light blue progress
                              ),
                            ),
                            if (ttsProvider.progressWord.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Current word: "${ttsProvider.progressWord}"',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9), // White text with opacity
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Main control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Play/Pause button
                        _buildControlButton(
                          context: context,
                          onPressed: ttsProvider.text.isEmpty
                              ? null
                              : () {
                                  if (ttsProvider.ttsState ==
                                      TTSState.playing) {
                                    ttsProvider.pause();
                                  } else if (ttsProvider.ttsState ==
                                      TTSState.paused) {
                                    ttsProvider.resume();
                                  } else {
                                    ttsProvider.speak();
                                  }
                                },
                          icon: _getPlayPauseIcon(ttsProvider.ttsState),
                          label: _getPlayPauseLabel(ttsProvider.ttsState),
                          backgroundColor: const Color(0xFF64B5F6), // Light blue background
                          foregroundColor: Colors.white, // White text and icon
                          size: 70,
                        ),

                        // Stop button
                        _buildControlButton(
                          context: context,
                          onPressed: ttsProvider.ttsState == TTSState.stopped
                              ? null
                              : ttsProvider.stop,
                          icon: Icons.stop,
                          label: 'Stop',
                          backgroundColor: const Color(0xFFEF5350), // Red background
                          foregroundColor: Colors.white, // White text and icon
                          size: 50,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Voice selection quick access
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF64B5F6).withOpacity(0.2), // Light blue with opacity
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF64B5F6).withOpacity(0.4), // Light blue border
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.record_voice_over,
                                color: const Color(0xFF64B5F6), // Light blue icon
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Current Voice',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white, // White text
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ttsProvider.selectedVoice.isNotEmpty
                                      ? ttsProvider.selectedVoice
                                      : 'Default Voice',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.mic),
                                label: const Text('Change'),
                                onPressed: () =>
                                    _showVoicePicker(context, ttsProvider),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF64B5F6), // Light blue text
                                  side: BorderSide(
                                    color: const Color(0xFF64B5F6).withOpacity(0.5), // Light blue border
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Text length info
                    if (ttsProvider.text.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1), // Light white background
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2), // White border
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Text Length:',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8), // White text with opacity
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${ttsProvider.text.length} characters',
                              style: TextStyle(
                                color: Colors.white, // White text
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Text management buttons
                    if (ttsProvider.text.isNotEmpty) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear Text'),
                              onPressed: () {
                                ttsProvider.clearText();
                                // Show confirmation
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Text cleared successfully'),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF5350), // Red text
                                side: BorderSide(
                                  color: const Color(0xFFEF5350).withOpacity(0.5), // Red border
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Upload New'),
                              onPressed: () => ttsProvider.pickFile(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.secondary,
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary.withOpacity(0.5),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Keyboard management
                    if (MediaQuery.of(context).viewInsets.bottom > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF64B5F6).withOpacity(0.2), // Light blue with opacity
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF64B5F6).withOpacity(0.4), // Light blue border
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.keyboard,
                              color: const Color(0xFF64B5F6), // Light blue icon
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Keyboard Active',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white, // White text
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                // Hide keyboard
                                FocusScope.of(context).unfocus();
                                // Also hide keyboard on iOS
                                SystemChannels.textInput.invokeMethod(
                                  'TextInput.hide',
                                );
                              },
                              icon: const Icon(Icons.keyboard_hide, size: 18),
                              label: const Text('Hide'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF64B5F6), // Light blue text
                                side: BorderSide(
                                  color: const Color(0xFF64B5F6).withOpacity(0.5), // Light blue border
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play & Save'),
                            onPressed: ttsProvider.text.isEmpty
                                ? null
                                : () async {
                                    await playAndSaveToHistory(
                                      context,
                                      ttsProvider,
                                      context.read<HistoryProvider>(),
                                    );
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.history),
                          label: const Text('History'),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/history'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF64B5F6), // Light blue text
                            side: BorderSide(
                              color: const Color(0xFF64B5F6).withOpacity(0.5), // Light blue border
                            ),
                          ),
                        ),
                      ],
                    ),
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
            icon: Icon(icon, size: size * 0.4, color: foregroundColor),
            tooltip: label,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white, // White text for better visibility
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
        return const Color(0xFF4CAF50); // Brighter green
      case TTSState.paused:
        return const Color(0xFFFF9800); // Brighter orange
      case TTSState.stopped:
        return const Color(0xFF9E9E9E); // Brighter grey
      case TTSState.continued:
        return const Color(0xFF2196F3); // Brighter blue
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

  void _showVoicePicker(BuildContext context, TTSProvider ttsProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: const Color(0xFF293a4c), // Dark background matching app theme
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3), // White handle bar
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.record_voice_over,
                    color: const Color(0xFF64B5F6), // Light blue icon
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Select Voice',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // White text
                    ),
                  ),
                ],
              ),
            ),

            // Voice list
            Expanded(
              child: ttsProvider.voices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.voice_chat_outlined,
                            size: 64,
                            color: Colors.white.withOpacity(0.5), // White icon with opacity
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No voices available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white, // White text
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try changing the language first',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7), // White text with opacity
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: ttsProvider.voices.length,
                      itemBuilder: (context, index) {
                        final voice = ttsProvider.voices[index];
                        final voiceName = voice['name'] ?? 'Unknown';
                        final locale = voice['locale'] ?? 'Unknown';
                        final isSelected =
                            voiceName == ttsProvider.selectedVoice;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isSelected
                              ? const Color(0xFF64B5F6).withOpacity(0.2) // Light blue when selected
                              : Colors.white.withOpacity(0.1), // Light white when not selected
                          child: ListTile(
                            leading: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.record_voice_over,
                              color: isSelected
                                  ? const Color(0xFF64B5F6) // Light blue when selected
                                  : Colors.white.withOpacity(0.7), // White with opacity when not selected
                            ),
                            title: Text(
                              voiceName,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF64B5F6) // Light blue when selected
                                    : Colors.white, // White when not selected
                              ),
                            ),
                            subtitle: Text(
                              locale,
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF64B5F6).withOpacity(0.8) // Light blue with opacity when selected
                                    : Colors.white.withOpacity(0.7), // White with opacity when not selected
                              ),
                            ),
                            onTap: () {
                              ttsProvider.setVoice(voiceName);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
            ),

            // Close button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64B5F6), // Light blue text
                    side: BorderSide(
                      color: const Color(0xFF64B5F6).withOpacity(0.5), // Light blue border
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

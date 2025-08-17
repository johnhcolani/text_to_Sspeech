import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../widgets/voice_settings_panel.dart';
import '../providers/tts_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF293a4c), // Same color as other screens
      appBar: AppBar(
        backgroundColor: const Color(0xFF293a4c),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
              Platform.isIOS ? Icons.settings : Icons.settings,
              color: const Color(0xFF64B5F6),
            ),
            const SizedBox(width: 12),
            Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF293a4c),
              const Color(0xFF293a4c).withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ), // Reduced padding
            child: Column(
              children: [
                // Header info
                Container(
                  padding: const EdgeInsets.all(12), // Reduced padding
                  decoration: BoxDecoration(
                    color: const Color(0xFF64B5F6).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12), // Reduced radius
                    border: Border.all(
                      color: const Color(0xFF64B5F6).withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFF64B5F6),
                        size: 20, // Reduced size
                      ),
                      const SizedBox(width: 10), // Reduced spacing
                      Expanded(
                        child: Text(
                          'Configure voice settings, language, and audio preferences for optimal text-to-speech experience.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13, // Reduced font size
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16), // Reduced spacing
                // Voice Settings Panel
                const VoiceSettingsPanel(),

                const SizedBox(height: 16), // Reduced spacing
                // Synchronization Settings Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.sync,
                              color: const Color(0xFFFF9800),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Reading Synchronization',
                              style: TextStyle(
                                color: const Color(0xFFFF9800),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Timing Offset Control
                      Consumer<TTSProvider>(
                        builder: (context, tts, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Timing Offset',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Adjust if reading position and highlighting don\'t match',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Slider(
                                value: tts.timingOffset,
                                min: 0.3,
                                max: 2.0,
                                divisions: 17,
                                label: tts.timingOffset.toStringAsFixed(1),
                                onChanged: tts.adjustTimingOffset,
                                activeColor: const Color(0xFFFF9800),
                                inactiveColor: Colors.white.withOpacity(0.2),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Faster (0.3)',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    'Slower (2.0)',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Manual Synchronization Controls
                      Consumer<TTSProvider>(
                        builder: (context, tts, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.build,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Manual Synchronization',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Use these tools when reading and highlighting are out of sync',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: tts.progressActive
                                          ? () {
                                              // Reset progress to beginning
                                              tts.resetProgress();
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Progress reset to beginning',
                                                  ),
                                                  backgroundColor: const Color(
                                                    0xFFFF9800,
                                                  ),
                                                ),
                                              );
                                            }
                                          : null,
                                      icon: const Icon(Icons.refresh, size: 16),
                                      label: const Text('Reset Progress'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFFFF9800,
                                        ),
                                        side: BorderSide(
                                          color: const Color(
                                            0xFFFF9800,
                                          ).withOpacity(0.5),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        // Force refresh of the reading panel
                                        tts.notifyListeners();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Reading panel refreshed',
                                            ),
                                            backgroundColor: const Color(
                                              0xFFFF9800,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.visibility,
                                        size: 16,
                                      ),
                                      label: const Text('Refresh Display'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFFFF9800,
                                        ),
                                        side: BorderSide(
                                          color: const Color(
                                            0xFFFF9800,
                                          ).withOpacity(0.5),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Troubleshooting Tips
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.blue[300],
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Troubleshooting Tips',
                                  style: TextStyle(
                                    color: Colors.blue[300],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• If highlighting is ahead: Increase timing offset\n'
                              '• If highlighting is behind: Decrease timing offset\n'
                              '• Use "Reset Progress" to start over\n'
                              '• Use "Refresh Display" to update the view',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16), // Reduced spacing
                // Platform-specific information
                if (Platform.isIOS) ...[
                  Container(
                    padding: const EdgeInsets.all(12), // Reduced padding
                    decoration: BoxDecoration(
                      color: const Color(0xFF64B5F6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12), // Reduced radius
                      border: Border.all(
                        color: const Color(0xFF64B5F6).withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.phone_iphone,
                              color: const Color(0xFF64B5F6),
                              size: 20, // Reduced size
                            ),
                            const SizedBox(width: 10), // Reduced spacing
                            Text(
                              'iOS Features',
                              style: TextStyle(
                                color: const Color(0xFF64B5F6),
                                fontSize: 15, // Reduced font size
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10), // Reduced spacing
                        Text(
                          '• True pause/resume functionality\n• High-quality voice synthesis\n• Advanced audio processing',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13, // Reduced font size
                            height: 1.3, // Reduced line height
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (Platform.isAndroid) ...[
                  Container(
                    padding: const EdgeInsets.all(12), // Reduced padding
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12), // Reduced radius
                      border: Border.all(
                        color: const Color(0xFFFF9800).withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.android,
                              color: const Color(0xFFFF9800),
                              size: 20, // Reduced size
                            ),
                            const SizedBox(width: 10), // Reduced spacing
                            Text(
                              'Android Features',
                              style: TextStyle(
                                color: const Color(0xFFFF9800),
                                fontSize: 15, // Reduced font size
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10), // Reduced spacing
                        Text(
                          '• Pause = Stop & Restart\n• Wide voice selection\n• Customizable speech parameters',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13, // Reduced font size
                            height: 1.3, // Reduced line height
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16), // Reduced spacing
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../widgets/voice_settings_panel.dart';

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced padding
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

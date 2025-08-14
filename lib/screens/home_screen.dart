import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/tts_provider.dart';
import '../widgets/reading_panel.dart';
import '../widgets/text_input_panel.dart';
import '../widgets/control_panel.dart';
import '../widgets/voice_settings_panel.dart'; // Added import for VoiceSettingsPanel

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF293a4c), // Same color as history screen
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF293a4c), // Dark blue background
              const Color(0xFF293a4c).withOpacity(0.8), // Slightly lighter for gradient effect
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Main content - wrapped in ScrollView to prevent overflow
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Text input panel
                      const TextInputPanel(),
                      
                      const SizedBox(height: 20),
                      
                      // Control panel
                      const ControlPanel(),
                      
                      const SizedBox(height: 20),
                      const ReadingPanel(),
                      
                      // Add bottom padding to ensure content doesn't get cut off
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Text to Speech',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Changed to white for better contrast
                      ),
                    ),
                    Text(
                      'Natural Human Voice',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8), // Changed to white with opacity
                      ),
                    ),
                  ],
                ),
              ),
              // Settings button with gear icon
              _buildSettingsButton(),
            ],
          ),
          const SizedBox(height: 16),
          
          // Platform-specific hint text
          if (Platform.isIOS) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF64B5F6).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF64B5F6).withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: const Color(0xFF64B5F6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'iOS: Supports pause/resume',
                    style: TextStyle(
                      color: const Color(0xFF64B5F6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (Platform.isAndroid) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF64B5F6).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF64B5F6).withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: const Color(0xFF64B5F6),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Android: Upload PDF/TXT files or type text to convert to natural speech',
                      style: TextStyle(
                        color: const Color(0xFF64B5F6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsButton() {
    return IconButton(
      onPressed: () {
        _showVoiceSettingsBottomSheet(context);
      },
      icon: Icon(
        Icons.settings, // Changed from microphone to gear icon
        size: 28,
        color: const Color(0xFF64B5F6), // Light blue for better visibility
      ),
      tooltip: 'Voice Settings',
      // Platform-specific styling
      style: IconButton.styleFrom(
        backgroundColor: Platform.isIOS 
            ? Colors.white.withOpacity(0.1) 
            : Colors.transparent,
        foregroundColor: const Color(0xFF64B5F6),
      ),
    );
  }

  void _showVoiceSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF293a4c),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_voice,
                      color: const Color(0xFF64B5F6),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Voice Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                color: Color(0xFF64B5F6),
                height: 1,
                thickness: 1,
              ),
              // Voice settings content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: const VoiceSettingsPanel(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tts_provider.dart';
import '../widgets/text_input_panel.dart';
import '../widgets/control_panel.dart';
import '../widgets/reading_panel.dart';
import '../widgets/voice_settings_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showVoiceSettings = false; // Track whether to show voice settings

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF293a4c),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Language and Voice Selection Chips
                    _buildLanguageVoiceSelection(),
                    const SizedBox(height: 24),

                    // Text Input Panel
                    const TextInputPanel(),
                    const SizedBox(height: 16),

                    // Control Panel
                    const ControlPanel(),
                    const SizedBox(height: 16),

                    // Reading Panel
                    const ReadingPanel(),

                    // Voice Settings Panel (shown/hidden when gear button is clicked)
                    if (_showVoiceSettings) ...[
                      const SizedBox(height: 24),
                      Container(
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
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.settings_voice,
                                    color: Colors.blue[300],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Voice Settings',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: VoiceSettingsPanel(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Text to Speech',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildSettingsButton(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Natural Human Voice',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageVoiceSelection() {
    return Consumer<TTSProvider>(
      builder: (context, tts, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Language & Voice',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Language Selection
                Container(
                  width: 180,
                  height: 60,
                  child: ActionChip(
                    avatar: Icon(Icons.language, color: Colors.white, size: 24),
                    label: Text(
                      tts.selectedLanguage,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: Colors.blue.withOpacity(0.6),
                    side: BorderSide(
                      color: Colors.blue.withOpacity(0.8),
                      width: 1,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    onPressed: () => _showLanguageSelection(),
                  ),
                ),

                // Voice Selection
                Container(
                  width: 180,
                  height: 60,
                  child: ActionChip(
                    avatar: Icon(
                      Icons.record_voice_over,
                      color: Colors.white,
                      size: 24,
                    ),
                    label: Text(
                      tts.selectedVoice.isNotEmpty
                          ? tts.selectedVoice
                          : 'Default Voice',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: Colors.green.withOpacity(0.6),
                    side: BorderSide(
                      color: Colors.green.withOpacity(0.8),
                      width: 1,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    onPressed: () => _showVoiceSelection(),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsButton() {
    return IconButton(
      icon: Icon(Icons.settings, color: Colors.white),
      onPressed: () {
        setState(() {
          _showVoiceSettings = !_showVoiceSettings;
        });
      },
    );
  }

  void _showLanguageSelection() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Language'),
        content: Consumer<TTSProvider>(
          builder: (context, tts, child) {
            // Show only the most popular languages
            final popularLanguages = ['en-US', 'en-GB', 'es-ES', 'fr-FR'];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: popularLanguages.map((lang) {
                return ListTile(
                  title: Text(lang),
                  trailing: tts.selectedLanguage == lang
                      ? Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    tts.setLanguage(lang);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  void _showVoiceSelection() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Voice'),
        content: Consumer<TTSProvider>(
          builder: (context, tts, child) {
            if (tts.voices.isEmpty) {
              return Center(child: CircularProgressIndicator());
            }

            // Filter to show only popular voices (first 3-4)
            final popularVoices = tts.voices.take(4).toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: popularVoices.map((voice) {
                final voiceName = voice['name'] ?? 'Unknown';
                final locale = voice['locale'] ?? '';
                return ListTile(
                  title: Text(voiceName),
                  subtitle: Text(locale),
                  trailing: tts.selectedVoice == voiceName
                      ? Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    tts.setVoice(voiceName);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  void _showVoiceSettingsBottomSheet() {
    // This method is no longer needed since we're adding settings directly to the screen
  }
}

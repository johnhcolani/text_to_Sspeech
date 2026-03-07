import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tts_provider.dart';
import '../widgets/text_input_panel.dart';
import '../widgets/control_panel.dart';
import '../widgets/reading_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _HomeMenuAction { settings, history }

class _HomeScreenState extends State<HomeScreen> {
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
              _buildMenuButton(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Natural Human Voice',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withAlpha(204),
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
                SizedBox(
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
                    backgroundColor: Colors.blue.withAlpha(153),
                    side: BorderSide(
                      color: Colors.blue.withAlpha(204),
                      width: 1,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    onPressed: () => _showLanguageSelection(),
                  ),
                ),

                // Voice Selection
                SizedBox(
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
                          : 'Voice',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: Colors.green.withAlpha(153),
                    side: BorderSide(
                      color: Colors.green.withAlpha(204),
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

  Widget _buildMenuButton() {
    const Color background = Color(0xFF293a4c);
    final Color menuColor = Color.lerp(background, Colors.white, 0.1)!;
    return PopupMenuButton<_HomeMenuAction>(
      icon: Icon(Icons.more_vert, color: Colors.white),
      color: menuColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (action) {
        switch (action) {
          case _HomeMenuAction.settings:
            Navigator.pushNamed(context, '/settings');
            break;
          case _HomeMenuAction.history:
            Navigator.pushNamed(context, '/history');
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<_HomeMenuAction>(
          value: _HomeMenuAction.settings,
          child: ListTile(
            leading: Icon(Icons.settings, color: Colors.white70),
            title: Text(
              'Settings',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const PopupMenuItem<_HomeMenuAction>(
          value: _HomeMenuAction.history,
          child: ListTile(
            leading: Icon(Icons.history, color: Colors.white70),
            title: Text(
              'History',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
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
}

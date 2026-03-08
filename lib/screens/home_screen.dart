import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tts_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/text_input_panel.dart';
import '../widgets/control_panel.dart';
import '../widgets/reading_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _HomeMenuAction { settings, history, colorTheme }

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final scaffoldBg = context.watch<ThemeProvider>().scaffoldBackground;
    return Scaffold(
      backgroundColor: scaffoldBg,
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
    return Consumer2<TTSProvider, ThemeProvider>(
      builder: (context, tts, themeProvider, child) {
        final accent = themeProvider.accentColor;
        final chipStyle = TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        );
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
            Row(
              children: [
                // Language Selection
                Expanded(
                  child: ActionChip(
                    avatar: Icon(Icons.language, color: Colors.white, size: 22),
                    label: Text(
                      tts.selectedLanguage,
                      style: chipStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                    backgroundColor: accent.withAlpha(153),
                    side: BorderSide(color: accent.withAlpha(204), width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    onPressed: () => _showLanguageSelection(),
                  ),
                ),
                const SizedBox(width: 12),
                // Voice Selection
                Expanded(
                  child: ActionChip(
                    avatar: Icon(Icons.record_voice_over, color: Colors.white, size: 22),
                    label: Text(
                      tts.selectedVoice.isNotEmpty ? tts.selectedVoice : 'Voice',
                      style: chipStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                    backgroundColor: accent.withAlpha(153),
                    side: BorderSide(color: accent.withAlpha(204), width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  void _showThemePicker(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: themeProvider.scaffoldBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.white24),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.palette, color: themeProvider.accentColor, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Color theme',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: AppTheme.values.map((theme) {
                      final isSelected = themeProvider.current == theme;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: theme.surfaceColor.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () {
                              themeProvider.setTheme(theme);
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: theme.scaffoldBackground,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: theme.accentColor.withOpacity(0.6)),
                                    ),
                                    child: Icon(theme.icon, color: theme.accentColor, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          theme.displayName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          theme.description,
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_circle, color: themeProvider.accentColor, size: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton() {
    final background = context.watch<ThemeProvider>().scaffoldBackground;
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
          case _HomeMenuAction.colorTheme:
            _showThemePicker(context);
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
        const PopupMenuItem<_HomeMenuAction>(
          value: _HomeMenuAction.colorTheme,
          child: ListTile(
            leading: Icon(Icons.palette_outlined, color: Colors.white70),
            title: Text(
              'Color theme',
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

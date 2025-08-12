import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tts_provider.dart';

class VoiceSettingsPanel extends StatelessWidget {
  const VoiceSettingsPanel({super.key});

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
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_voice,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Voice Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Settings content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Language selection
                    _buildSettingSection(
                      context: context,
                      title: 'Language',
                      icon: Icons.language,
                      child: DropdownButtonFormField<String>(
                        value: ttsProvider.selectedLanguage,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: [
                          'en-US',
                          'en-GB',
                          'es-ES',
                          'fr-FR',
                          'de-DE',
                          'it-IT',
                          'pt-BR',
                          'ja-JP',
                          'ko-KR',
                          'zh-CN',
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            ttsProvider.setLanguage(newValue);
                          }
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Voice selection
                    if (ttsProvider.voices.isNotEmpty) ...[
                      _buildSettingSection(
                        context: context,
                        title: 'Voice',
                        icon: Icons.record_voice_over,
                        child: DropdownButtonFormField<String>(
                          value: ttsProvider.selectedVoice,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: ttsProvider.voices.map((voice) {
                            String voiceName = voice['name'] ?? 'Unknown';
                            return DropdownMenuItem<String>(
                              value: voiceName,
                              child: Text(
                                voiceName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              ttsProvider.setVoice(newValue);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Speech rate
                    _buildSettingSection(
                      context: context,
                      title: 'Speech Rate',
                      icon: Icons.speed,
                      child: Column(
                        children: [
                          Slider(
                            value: ttsProvider.speechRate,
                            min: 0.1,
                            max: 1.0,
                            divisions: 9,
                            label: ttsProvider.speechRate.toStringAsFixed(1),
                            onChanged: ttsProvider.setSpeechRate,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Slow',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Fast',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Pitch
                    _buildSettingSection(
                      context: context,
                      title: 'Pitch',
                      icon: Icons.tune,
                      child: Column(
                        children: [
                          Slider(
                            value: ttsProvider.pitch,
                            min: 0.5,
                            max: 2.0,
                            divisions: 15,
                            label: ttsProvider.pitch.toStringAsFixed(1),
                            onChanged: ttsProvider.setPitch,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Low',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'High',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Volume
                    _buildSettingSection(
                      context: context,
                      title: 'Volume',
                      icon: Icons.volume_up,
                      child: Column(
                        children: [
                          Slider(
                            value: ttsProvider.volume,
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            label: (ttsProvider.volume * 100).toInt().toString() + '%',
                            onChanged: ttsProvider.setVolume,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mute',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Max',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildSettingSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.secondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

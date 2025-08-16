import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
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
            color: Colors.white.withOpacity(0.15), // Same as other panels
            borderRadius: BorderRadius.circular(14), // Further reduced from 16
            border: Border.all(
              color: Colors.white.withOpacity(0.25), // White border
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2), // Further reduced shadow
                blurRadius: 8, // Further reduced from 10
                offset: const Offset(0, 2), // Further reduced from 3
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Panel header - made even more compact
              Container(
                padding: const EdgeInsets.all(10), // Further reduced from 12
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF64B5F6,
                  ).withOpacity(0.3), // Light blue header
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14), // Further reduced from 16
                    topRight: Radius.circular(14), // Further reduced from 16
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_voice,
                      color: const Color(0xFF64B5F6), // Light blue icon
                      size: 18, // Further reduced from 20
                    ),
                    const SizedBox(width: 6), // Further reduced from 8
                    Expanded(
                      child: Text(
                        'Voice Settings',
                        style: TextStyle(
                          fontSize: 15, // Further reduced from 16
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64B5F6), // Light blue text
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Settings content - made even more compact
              Padding(
                padding: const EdgeInsets.all(8), // Further reduced from 10
                child: Column(
                  children: [
                    // Language selection
                    _buildSettingSection(
                      context: context,
                      title: 'Language',
                      icon: Icons.language,
                      child: DropdownButtonFormField<String>(
                        value: ttsProvider.selectedLanguage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ), // Further reduced font size
                        dropdownColor: const Color(
                          0xFF293a4c,
                        ), // Dark background for dropdown
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: const Color(0xFF64B5F6), // Light blue arrow
                          size: 20,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              6,
                            ), // Further reduced from 8
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(
                                0.3,
                              ), // White border
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              6,
                            ), // Further reduced from 8
                            borderSide: BorderSide(
                              color: const Color(
                                0xFF64B5F6,
                              ), // Light blue focused border
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(
                            0.05,
                          ), // Light background
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, // Further reduced from 10
                            vertical: 6, // Further reduced from 8
                          ),
                        ),
                        items:
                            [
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
                                child: Text(
                                  value,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ), // Further reduced font size
                                ),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            ttsProvider.setLanguage(newValue);
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 8), // Further reduced from 10
                    // Voice selection
                    if (ttsProvider.voices.isNotEmpty) ...[
                      _buildSettingSection(
                        context: context,
                        title: 'Voice',
                        icon: Icons.record_voice_over,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: ttsProvider.selectedVoice,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ), // Further reduced font size
                                    dropdownColor: const Color(
                                      0xFF293a4c,
                                    ), // Dark background for dropdown
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      color: const Color(
                                        0xFF64B5F6,
                                      ), // Light blue arrow
                                      size: 20,
                                    ),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          6,
                                        ), // Further reduced from 8
                                        borderSide: BorderSide(
                                          color: Colors.white.withOpacity(
                                            0.3,
                                          ), // White border
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          6,
                                        ), // Further reduced from 8
                                        borderSide: BorderSide(
                                          color: const Color(
                                            0xFF64B5F6,
                                          ), // Light blue focused border
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(
                                        0.05,
                                      ), // Light background
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal:
                                                8, // Further reduced from 10
                                            vertical:
                                                6, // Further reduced from 8
                                          ),
                                    ),
                                    items: ttsProvider.voices.map((voice) {
                                      String voiceName =
                                          voice['name'] ?? 'Unknown';
                                      String locale = voice['locale'] ?? '';
                                      return DropdownMenuItem<String>(
                                        value: voiceName,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              voiceName,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    Colors.white, // White text
                                                fontSize:
                                                    11, // Further reduced font size
                                              ),
                                            ),
                                            if (locale.isNotEmpty)
                                              Text(
                                                locale,
                                                style: TextStyle(
                                                  fontSize:
                                                      9, // Further reduced from 10
                                                  color: Colors.white
                                                      .withOpacity(
                                                        0.7,
                                                      ), // White with opacity
                                                ),
                                              ),
                                          ],
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
                                const SizedBox(
                                  width: 4,
                                ), // Further reduced from 6
                                IconButton(
                                  onPressed: () => ttsProvider.refreshVoices(),
                                  icon: const Icon(
                                    Icons.refresh,
                                    size: 16,
                                  ), // Further reduced size
                                  tooltip: 'Refresh voices',
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(
                                      0xFF64B5F6,
                                    ).withOpacity(0.2), // Light blue background
                                    foregroundColor: const Color(
                                      0xFF64B5F6,
                                    ), // Light blue icon
                                    padding: const EdgeInsets.all(
                                      4,
                                    ), // Further reduced padding
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3), // Further reduced from 4
                            Text(
                              '${ttsProvider.voices.length} voices available',
                              style: TextStyle(
                                fontSize: 9, // Further reduced from 10
                                color: Colors.white.withOpacity(
                                  0.7,
                                ), // White with opacity
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8), // Further reduced from 10
                    ] else ...[
                      // No voices available - simplified
                      _buildSettingSection(
                        context: context,
                        title: 'Voice',
                        icon: Icons.record_voice_over,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(
                                8,
                              ), // Further reduced from 10
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFEF5350,
                                ).withOpacity(0.2), // Red with opacity
                                borderRadius: BorderRadius.circular(
                                  6,
                                ), // Further reduced from 8
                                border: Border.all(
                                  color: const Color(
                                    0xFFEF5350,
                                  ).withOpacity(0.4), // Red border
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_outlined,
                                    color: const Color(0xFFEF5350), // Red icon
                                    size: 14, // Further reduced from 16
                                  ),
                                  const SizedBox(
                                    width: 6,
                                  ), // Further reduced from 8
                                  Expanded(
                                    child: Text(
                                      'No voices available',
                                      style: TextStyle(
                                        color: Colors.white, // White text
                                        fontSize: 11, // Further reduced from 12
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3), // Further reduced from 4
                            OutlinedButton.icon(
                              icon: const Icon(
                                Icons.refresh,
                                size: 12,
                              ), // Further reduced size
                              label: const Text(
                                'Refresh Voices',
                                style: TextStyle(fontSize: 10),
                              ), // Further reduced font size
                              onPressed: () => ttsProvider.refreshVoices(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(
                                  0xFF64B5F6,
                                ), // Light blue text
                                side: BorderSide(
                                  color: const Color(
                                    0xFF64B5F6,
                                  ).withOpacity(0.5), // Light blue border
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 4,
                                ), // Further reduced padding
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8), // Further reduced from 10
                    ],

                    // Speech rate
                    _buildSettingSection(
                      context: context,
                      title: 'Speech Rate',
                      icon: Icons.speed,
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(
                                0xFF64B5F6,
                              ), // Light blue active track
                              inactiveTrackColor: Colors.white.withOpacity(
                                0.2,
                              ), // White inactive track
                              thumbColor: const Color(
                                0xFF64B5F6,
                              ), // Light blue thumb
                              overlayColor: const Color(
                                0xFF64B5F6,
                              ).withOpacity(0.2), // Light blue overlay
                              valueIndicatorColor: const Color(
                                0xFF64B5F6,
                              ), // Light blue value indicator
                              valueIndicatorTextStyle: const TextStyle(
                                color: Colors.white, // White text
                                fontSize: 10, // Further reduced from 11
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: Slider(
                              value: context.watch<TTSProvider>().rate,
                              min: 0.1,
                              max: 1.0,
                              divisions: 9,
                              label: context
                                  .watch<TTSProvider>()
                                  .rate
                                  .toStringAsFixed(1),
                              onChanged: context.read<TTSProvider>().setRate,
                            ),
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Slow',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(
                                    0.7,
                                  ), // White text with opacity
                                  fontSize: 9, // Further reduced from 10
                                ),
                              ),
                              Text(
                                'Fast',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(
                                    0.7,
                                  ), // White text with opacity
                                  fontSize: 9, // Further reduced from 10
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8), // Further reduced from 10
                    // Speech pitch
                    _buildSettingSection(
                      context: context,
                      title: 'Speech Pitch',
                      icon: Platform.isIOS
                          ? Icons.tune
                          : Icons.music_note, // Platform-specific icon
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(
                                0xFF64B5F6,
                              ), // Light blue active track
                              inactiveTrackColor: Colors.white.withOpacity(
                                0.2,
                              ), // White inactive track
                              thumbColor: const Color(
                                0xFF64B5F6,
                              ), // Light blue thumb
                              overlayColor: const Color(
                                0xFF64B5F6,
                              ).withOpacity(0.2), // Light blue overlay
                              valueIndicatorColor: const Color(
                                0xFF64B5F6,
                              ), // Light blue value indicator
                              valueIndicatorTextStyle: const TextStyle(
                                color: Colors.white, // White text
                                fontSize: 10, // Further reduced from 11
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: Slider(
                              value: context.watch<TTSProvider>().pitch,
                              min: 0.5,
                              max: 2.0,
                              divisions: 15,
                              label: context
                                  .watch<TTSProvider>()
                                  .pitch
                                  .toStringAsFixed(1),
                              onChanged: context.read<TTSProvider>().setPitch,
                            ),
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Low',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(
                                    0.7,
                                  ), // White text with opacity
                                  fontSize: 9, // Further reduced from 10
                                ),
                              ),
                              Text(
                                'High',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(
                                    0.7,
                                  ), // White text with opacity
                                  fontSize: 9, // Further reduced from 10
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8), // Further reduced from 10
                    // Volume
                    _buildSettingSection(
                      context: context,
                      title: 'Volume',
                      icon: Icons.volume_up,
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(
                                0xFF64B5F6,
                              ), // Light blue active track
                              inactiveTrackColor: Colors.white.withOpacity(
                                0.2,
                              ), // White inactive track
                              thumbColor: const Color(
                                0xFF64B5F6,
                              ), // Light blue thumb
                              overlayColor: const Color(
                                0xFF64B5F6,
                              ).withOpacity(0.2), // Light blue overlay
                              valueIndicatorColor: const Color(
                                0xFF64B5F6,
                              ), // Light blue value indicator
                              valueIndicatorTextStyle: const TextStyle(
                                color: Colors.white, // White text
                                fontSize: 10, // Further reduced from 11
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: Slider(
                              value: ttsProvider.volume,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              label:
                                  (ttsProvider.volume * 100)
                                      .toInt()
                                      .toString() +
                                  '%',
                              onChanged: ttsProvider.setVolume,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mute',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(
                                    0.7,
                                  ), // White text with opacity
                                  fontSize: 9, // Further reduced from 10
                                ),
                              ),
                              Text(
                                'Max',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(
                                    0.7,
                                  ), // White text with opacity
                                  fontSize: 9, // Further reduced from 10
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8), // Further reduced from 10
                    // Audio Quality Settings for Car Audio - simplified
                    _buildSettingSection(
                      context: context,
                      title: 'Audio Quality (Car Optimized)',
                      icon: Icons.high_quality,
                      child: Container(
                        padding: const EdgeInsets.all(
                          6,
                        ), // Further reduced from 8
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF64B5F6,
                          ).withOpacity(0.2), // Light blue with opacity
                          borderRadius: BorderRadius.circular(
                            4,
                          ), // Further reduced from 6
                          border: Border.all(
                            color: const Color(
                              0xFF64B5F6,
                            ).withOpacity(0.4), // Light blue border
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 12, // Further reduced from 14
                                  color: const Color(
                                    0xFF64B5F6,
                                  ), // Light blue icon
                                ),
                                const SizedBox(
                                  width: 4,
                                ), // Further reduced from 6
                                Text(
                                  'Car Audio Optimized',
                                  style: TextStyle(
                                    fontSize: 10, // Further reduced from 12
                                    fontWeight: FontWeight.w600,
                                    color: const Color(
                                      0xFF64B5F6,
                                    ), // Light blue text
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3), // Further reduced from 4
                            Text(
                              'WAV format for smooth car playback',
                              style: TextStyle(
                                fontSize: 9, // Further reduced from 10
                                color: Colors.white.withOpacity(
                                  0.7,
                                ), // White with opacity
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8), // Further reduced from 10
                    // Timing offset slider for word highlighting sync
                    _buildSettingSection(
                      context: context,
                      title: 'Highlight Timing',
                      icon: Icons.timer,
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(
                                0xFF64B5F6,
                              ), // Light blue active track
                              inactiveTrackColor: Colors.white.withOpacity(
                                0.2,
                              ), // White inactive track
                              thumbColor: const Color(
                                0xFF64B5F6,
                              ), // Light blue thumb
                              overlayColor: const Color(
                                0xFF64B5F6,
                              ).withOpacity(0.2), // Light blue overlay
                              valueIndicatorColor: const Color(
                                0xFF64B5F6,
                              ), // Light blue value indicator
                              valueIndicatorTextStyle: const TextStyle(
                                color: Colors.white, // White text
                                fontSize: 10, // Further reduced from 11
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: Slider(
                              value: ttsProvider.timingOffset,
                              min: 0.3,
                              max: 2.0,
                              divisions: 17,
                              label: ttsProvider.timingOffset.toStringAsFixed(
                                1,
                              ),
                              onChanged: ttsProvider.adjustTimingOffset,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Faster',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(
                                    0.7,
                                  ), // White text with opacity
                                  fontSize: 9, // Further reduced from 10
                                ),
                              ),
                              Text(
                                'Slower',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(
                                    0.7,
                                  ), // White text with opacity
                                  fontSize: 9, // Further reduced from 10
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
              color: const Color(0xFF64B5F6), // Light blue icon
              size: 14, // Further reduced from 16
            ),
            const SizedBox(width: 3), // Further reduced from 4
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13, // Further reduced from 14
                  fontWeight: FontWeight.w600,
                  color: Colors.white, // White text
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3), // Further reduced from 4
        child,
      ],
    );
  }
}

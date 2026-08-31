import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:text_to_speech/providers/history_provider.dart';
import 'package:text_to_speech/providers/theme_provider.dart';
import 'ads/ad_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'providers/tts_provider.dart';
import 'services/file_processing_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request permissions at startup on Android only
  // iOS handles permissions automatically when needed
  if (Platform.isAndroid) {
    await FileProcessingService().requestPermissions();
  }

  final ttsProvider = TTSProvider();
  await ttsProvider.initialize();

  final themeProvider = ThemeProvider();
  await themeProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ttsProvider),
        ChangeNotifierProvider(create: (_) => HistoryProvider()..load()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const MyApp(),
    ),
  );

  // Start consent + Mobile Ads setup after the first frame so any required
  // privacy form has a fully initialized UI to present from.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AdService.instance.initialize();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Text to Speech',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentThemeData,
          home: const SplashScreen(),
          routes: {
            '/home': (context) => const HomeScreen(),
            '/history': (context) => const HistoryScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
          // Accessibility improvements
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                  MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.5),
                ),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}

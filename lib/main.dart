import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:text_to_speech/providers/history_provider.dart';
import 'package:text_to_speech/providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'providers/tts_provider.dart';
import 'services/file_processing_service.dart';

/// Entry point of the Text to Speech application
///
/// Initializes the app with:
/// - Platform-specific permissions (Android)
/// - TTS provider with voice engine
/// - Theme provider for UI customization
/// - History provider for saved sessions
///
/// The app uses Provider pattern for state management across multiple providers,
/// ensuring efficient state sharing and widget rebuilds.
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
}

/// Root widget of the application
///
/// Configures Material Design theme, navigation routes, and accessibility settings.
/// Responds to theme changes and applies text scaling constraints.
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
        home: const SplashScreen(), // Restored original splash screen
        routes: {
          '/home': (context) => const HomeScreen(),
          '/history': (context) => const HistoryScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
        // Accessibility improvements
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.5)),
            ),
            child: child!,
          );
        },
      );
      },
    );
  }
}

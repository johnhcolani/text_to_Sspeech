import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:text_to_speech/providers/history_provider.dart';
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
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ttsProvider),
        ChangeNotifierProvider(create: (_) => HistoryProvider()..load()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Text to Speech',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          // Accessibility improvements
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          // Accessibility improvements
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
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
              textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.5),
            ),
            child: child!,
          );
        },
      );
  }
}

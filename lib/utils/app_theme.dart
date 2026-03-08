import 'package:flutter/material.dart';

/// Seasonal and default color themes for the app.
enum AppTheme {
  defaultTheme,
  spring,
  summer,
  autumn,
  winter,
}

extension AppThemeExtension on AppTheme {
  String get displayName {
    switch (this) {
      case AppTheme.defaultTheme:
        return 'Default';
      case AppTheme.spring:
        return 'Spring';
      case AppTheme.summer:
        return 'Summer';
      case AppTheme.autumn:
        return 'Autumn';
      case AppTheme.winter:
        return 'Winter';
    }
  }

  String get storageKey {
    switch (this) {
      case AppTheme.defaultTheme:
        return 'default';
      case AppTheme.spring:
        return 'spring';
      case AppTheme.summer:
        return 'summer';
      case AppTheme.autumn:
        return 'autumn';
      case AppTheme.winter:
        return 'winter';
    }
  }

  /// Short description for theme picker
  String get description {
    switch (this) {
      case AppTheme.defaultTheme:
        return 'Classic blue';
      case AppTheme.spring:
        return 'Fresh greens & blossom';
      case AppTheme.summer:
        return 'Warm sun & ocean';
      case AppTheme.autumn:
        return 'Cozy earth tones';
      case AppTheme.winter:
        return 'Cool ice & snow';
    }
  }

  /// Accent color used for buttons, highlights, icons
  Color get accentColor {
    switch (this) {
      case AppTheme.defaultTheme:
        return const Color(0xFF64B5F6); // Light blue
      case AppTheme.spring:
        return const Color(0xFF81C784); // Sage / mint green
      case AppTheme.summer:
        return const Color(0xFFFFB74D); // Warm amber / golden
      case AppTheme.autumn:
        return const Color(0xFFE57C42); // Pumpkin / rust
      case AppTheme.winter:
        return const Color(0xFF90A4AE); // Cool blue-grey / ice
    }
  }

  /// Main scaffold/surface background (dark-style)
  Color get scaffoldBackground {
    switch (this) {
      case AppTheme.defaultTheme:
        return const Color(0xFF293a4c);
      case AppTheme.spring:
        return const Color(0xFF2d3d2f); // Dark sage
      case AppTheme.summer:
        return const Color(0xFF3d3528); // Warm dark amber
      case AppTheme.autumn:
        return const Color(0xFF3d2e28); // Dark rust/brown
      case AppTheme.winter:
        return const Color(0xFF2a3441); // Cool dark blue-grey
    }
  }

  /// Secondary surface (cards, panels)
  Color get surfaceColor {
    switch (this) {
      case AppTheme.defaultTheme:
        return const Color(0xFF364652);
      case AppTheme.spring:
        return const Color(0xFF384a3a);
      case AppTheme.summer:
        return const Color(0xFF4a4235);
      case AppTheme.autumn:
        return const Color(0xFF4a3a32);
      case AppTheme.winter:
        return const Color(0xFF364352);
    }
  }

  /// Icon for theme picker
  IconData get icon {
    switch (this) {
      case AppTheme.defaultTheme:
        return Icons.palette_outlined;
      case AppTheme.spring:
        return Icons.local_florist;
      case AppTheme.summer:
        return Icons.wb_sunny;
      case AppTheme.autumn:
        return Icons.eco;
      case AppTheme.winter:
        return Icons.ac_unit;
    }
  }
}

class AppThemeData {
  const AppThemeData._();

  static AppTheme fromStorageKey(String? key) {
    switch (key) {
      case 'spring':
        return AppTheme.spring;
      case 'summer':
        return AppTheme.summer;
      case 'autumn':
        return AppTheme.autumn;
      case 'winter':
        return AppTheme.winter;
      default:
        return AppTheme.defaultTheme;
    }
  }

  static ThemeData themeFor(AppTheme theme) {
    final accent = theme.accentColor;
    final surface = theme.scaffoldBackground;
    final onSurface = Colors.white;
    final onSurfaceVariant = Colors.white70;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: accent,
        onPrimary: Colors.white,
        secondary: accent.withOpacity(0.8),
        onSecondary: Colors.white,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: theme.surfaceColor,
        onSurfaceVariant: onSurfaceVariant,
        outline: onSurfaceVariant.withOpacity(0.5),
      ),
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: theme.surfaceColor.withOpacity(0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

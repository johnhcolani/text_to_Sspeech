import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _storageKey = 'appTheme';

  final DatabaseService _db = DatabaseService();

  AppTheme _current = AppTheme.defaultTheme;
  bool _loaded = false;

  AppTheme get current => _current;
  ThemeData get currentThemeData => AppThemeData.themeFor(_current);

  /// Convenience: accent and scaffold for screens that still use custom colors
  Color get accentColor => _current.accentColor;
  Color get scaffoldBackground => _current.scaffoldBackground;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final value = await _db.getSetting(_storageKey);
      _current = AppThemeData.fromStorageKey(value);
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('ThemeProvider load error: $e');
      _loaded = true;
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    if (_current == theme) return;
    _current = theme;
    try {
      await _db.setSetting(_storageKey, theme.storageKey);
    } catch (e) {
      debugPrint('ThemeProvider setTheme error: $e');
    }
    notifyListeners();
  }
}

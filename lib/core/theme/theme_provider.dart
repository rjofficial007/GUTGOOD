import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier(this._prefs) : _themeMode = _loadTheme(_prefs);
  static const String _themeKey = 'theme_mode';
  final SharedPreferences _prefs;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  static ThemeMode _loadTheme(SharedPreferences prefs) {
    try {
      final theme = prefs.get(_themeKey);
      if (theme is String) {
        if (theme == 'light') return ThemeMode.light;
        if (theme == 'dark') return ThemeMode.dark;
      }
    } catch (_) {
      // Fallback for any storage issues
    }
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    if (mode == ThemeMode.light) {
      await _prefs.setString(_themeKey, 'light');
    } else if (mode == ThemeMode.dark) {
      await _prefs.setString(_themeKey, 'dark');
    } else {
      await _prefs.remove(_themeKey);
    }
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
}

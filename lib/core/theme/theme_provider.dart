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
      final theme = prefs.getString(_themeKey);
      if (theme == 'light') return ThemeMode.light;
      if (theme == 'dark') return ThemeMode.dark;
      if (theme == 'system') return ThemeMode.system;
    } catch (_) {
      // Fallback for any storage issues
    }
    return ThemeMode.light; // Default to light as requested
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    String themeStr;
    switch (mode) {
      case ThemeMode.light:
        themeStr = 'light';
        break;
      case ThemeMode.dark:
        themeStr = 'dark';
        break;
      case ThemeMode.system:
        themeStr = 'system';
        break;
    }
    await _prefs.setString(_themeKey, themeStr);
  }

}

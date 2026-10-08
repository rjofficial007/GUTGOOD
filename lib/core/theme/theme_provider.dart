import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier(this._prefs)
      : _themeMode = _loadTheme(_prefs),
        _hasExplicitPreference = _prefs.containsKey(_themeKey);
  static const String _themeKey = 'theme_mode';
  final SharedPreferences _prefs;
  ThemeMode _themeMode;
  bool _hasExplicitPreference;

  ThemeMode get themeMode => _themeMode;
  bool get hasExplicitPreference => _hasExplicitPreference;

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
    if (_themeMode == mode && _hasExplicitPreference) return;
    _themeMode = mode;
    _hasExplicitPreference = true;
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

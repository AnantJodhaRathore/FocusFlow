import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeService {
  ThemeModeService._internal();

  static final ThemeModeService instance = ThemeModeService._internal();

  static const String _themeModeKey = 'focusflow_theme_mode';

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.dark);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getString(_themeModeKey);

    themeMode.value = _themeModeFromString(savedValue);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeToString(mode));
  }

  ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
    }
  }
}

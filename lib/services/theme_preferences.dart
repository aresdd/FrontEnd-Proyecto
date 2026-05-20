import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferences {
  ThemePreferences._();

  static const _key = 'calbalance_theme_mode';

  static Future<ThemeMode> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key);
    switch (s) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.light;
    }
  }

  static Future<void> save(ThemeMode mode) async {
    final p = await SharedPreferences.getInstance();
    final v = mode == ThemeMode.dark
        ? 'dark'
        : mode == ThemeMode.light
            ? 'light'
            : 'system';
    await p.setString(_key, v);
  }
}

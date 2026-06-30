import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's theme preference (light / dark / system).
class ThemeService extends ChangeNotifier {
  ThemeService._();
  static final ThemeService _instance = ThemeService._();
  factory ThemeService() => _instance;

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  /// Load persisted preference from SharedPreferences.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('theme_mode');
    if (stored != null) {
      switch (stored) {
        case 'light':
          _mode = ThemeMode.light;
          break;
        case 'dark':
          _mode = ThemeMode.dark;
          break;
        default:
          _mode = ThemeMode.system;
      }
    }
    notifyListeners();
  }

  /// Cycle to the next mode: system → light → dark → system …
  void cycleMode() {
    switch (_mode) {
      case ThemeMode.system:
        _mode = ThemeMode.light;
        break;
      case ThemeMode.light:
        _mode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _mode = ThemeMode.system;
        break;
    }
    _persist();
    notifyListeners();
  }

  void _persist() async {
    final prefs = await SharedPreferences.getInstance();
    String value;
    switch (_mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
    }
    await prefs.setString('theme_mode', value);
  }
}

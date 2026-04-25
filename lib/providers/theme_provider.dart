import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/themes.dart';

enum AppTheme { lachispa, light, dark }

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';

  AppTheme _current = AppTheme.lachispa;
  AppTheme get current => _current;

  ThemeData get themeData {
    switch (_current) {
      case AppTheme.lachispa:
        return chispaTheme();
      case AppTheme.light:
        return lightTheme();
      case AppTheme.dark:
        return darkTheme();
    }
  }

  ThemeProvider() {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_themeKey);
      if (saved == null) return;

      final match = AppTheme.values.firstWhere(
        (t) => t.name == saved,
        orElse: () => AppTheme.lachispa,
      );
      if (match != _current) {
        _current = match;
        notifyListeners();
      }
    } catch (e) {
      print('[ThemeProvider] Error cargando tema guardado: $e');
    }
  }

  Future<void> changeTheme(AppTheme theme) async {
    if (_current == theme) return;
    _current = theme;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme.name);
    } catch (e) {
      print('[ThemeProvider] Error guardando preferencia de tema: $e');
    }
  }
}

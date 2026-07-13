import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  double _fontSize = 16.0;
  String _language = AppConstants.langChinese;

  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  String get language => _language;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString(AppConstants.keyTheme) ?? AppConstants.themeLight;
    final fontSize = prefs.getInt(AppConstants.keyFontSize) ?? 16;
    final lang = prefs.getString(AppConstants.keyLanguage) ?? AppConstants.langChinese;

    _themeMode = _parseTheme(theme);
    _fontSize = fontSize.toDouble();
    _language = lang;
    notifyListeners();
  }

  ThemeMode _parseTheme(String theme) {
    switch (theme) {
      case AppConstants.themeDark:
        return ThemeMode.dark;
      case AppConstants.themeSystem:
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    String themeStr;
    switch (mode) {
      case ThemeMode.dark:
        themeStr = AppConstants.themeDark;
        break;
      case ThemeMode.system:
        themeStr = AppConstants.themeSystem;
        break;
      default:
        themeStr = AppConstants.themeLight;
    }
    await prefs.setString(AppConstants.keyTheme, themeStr);
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyFontSize, size.round());
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLanguage, lang);
  }
}

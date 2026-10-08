import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _themeKey = 'settings_theme_mode';
  static const _currencyKey = 'settings_currency';

  ThemeMode _themeMode = ThemeMode.system;
  String _currency = 'INR';

  ThemeMode get themeMode => _themeMode;
  String get currency => _currency;

  bool _initialized = false;
  bool get initialized => _initialized;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final themeValue = prefs.getString(_themeKey);

    switch (themeValue) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        _themeMode = ThemeMode.system;
    }

    _currency = prefs.getString(_currencyKey) ?? 'INR';

    _initialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _themeKey,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );

    notifyListeners();
  }

  Future<void> setCurrency(String currency) async {
    _currency = currency;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency);

    notifyListeners();
  }

  String get currencySymbol {
    switch (_currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'INR':
      default:
        return '₹';
    }
  }
}
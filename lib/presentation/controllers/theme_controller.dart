import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';

/// State notifier for application theme mode (light / dark)
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;

  bool get isDarkMode => state == ThemeMode.dark;

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  static ThemeData buildTheme(Brightness brightness) =>
      AppTheme.buildTheme(brightness);

  static final ThemeData lightTheme = AppTheme.lightTheme;
  static final ThemeData darkTheme = AppTheme.darkTheme;
}

final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

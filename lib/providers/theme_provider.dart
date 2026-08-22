import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;

  bool get isDarkMode => state == ThemeMode.dark;

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  static ThemeData buildTheme(Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: 'GoogleSans',
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
      ),
    );
  }

  static final ThemeData lightTheme = buildTheme(Brightness.light);
  static final ThemeData darkTheme = buildTheme(Brightness.dark);
}

final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

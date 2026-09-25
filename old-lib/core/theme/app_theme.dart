import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'app_colors.dart';

/// App theme definitions and builders
class AppTheme {
  AppTheme._();

  static ThemeData buildTheme(Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: AppConstants.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primarySeed,
        brightness: brightness,
      ),
    );
  }

  static final ThemeData lightTheme = buildTheme(Brightness.light);
  static final ThemeData darkTheme = buildTheme(Brightness.dark);
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Centralized application constants and configurations
class AppConstants {
  AppConstants._();

  static const String appName = 'BiGuess Game';
  static const String appTitle = 'BiGuess';
  static const String appTagline = 'The Ultimate 2-Player Mystery Challenge';
  static const String defaultVersion = '0.31.0';
  static const String fontFamily = 'GoogleSans';

  // Asset paths
  static const String appIconPath = 'assets/logos/biguess-icon.webp';

  // Default game values
  static const int defaultCountdownSeconds = 2;
  static const List<int> supportedCountdownDurations = [2, 3, 5, 10];

  // Topic metadata: display icon and accent color per topic
  static const Map<String, IconData> topicIcons = {
    'Anime': Icons.auto_awesome_rounded,
    'Geography': Icons.public_rounded,
    'Movies': Icons.movie_creation_rounded,
  };

  static const Map<String, Color> topicColors = {
    'Anime': AppColors.animeAccent,
    'Geography': AppColors.geographyAccent,
    'Movies': AppColors.moviesAccent,
  };
}

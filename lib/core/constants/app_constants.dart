import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Centralized application constants and configurations
class AppConstants {
  AppConstants._();

  static const String appName = 'BiGuess Game';
  static const String appTitle = 'BiGuess';
  static const String appTagline = 'The Ultimate 2-Player Mystery Challenge';
  static const String defaultVersion = '0.36.0';
  static const String fontFamily = 'GoogleSans';
  static const String imageDisclaimer =
      'We do not own any of the images. All rights belong to their respective owners.';

  // Asset paths
  static const String appIconPath = 'assets/logos/biguess-icon.webp';
  static const String defaultProfilePath = 'assets/profile/abderrahmane_saoudi.webp';

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

  /// Returns a themed accent color for any topic with dynamic palette hashing fallback
  static Color getTopicColor(String topic) {
    if (topicColors.containsKey(topic)) return topicColors[topic]!;

    final hash = topic.toLowerCase().codeUnits.fold(0, (sum, c) => sum + c);
    const dynamicPalette = [
      AppColors.animeAccent,
      AppColors.geographyAccent,
      AppColors.moviesAccent,
      Color(0xFF00E676), // Emerald
      Color(0xFF00B0FF), // Electric cyan
      Color(0xFFFF9100), // Amber
      Color(0xFFE040FB), // Magenta
      Color(0xFFFF5252), // Coral
      Color(0xFF7C4DFF), // Deep purple
      Color(0xFFFFD600), // Bright gold
      Color(0xFF1DE9B6), // Mint teal
    ];
    return dynamicPalette[hash % dynamicPalette.length];
  }

  /// Returns a contextual icon for any topic with smart keyword matching fallback
  static IconData getTopicIcon(String topic) {
    if (topicIcons.containsKey(topic)) return topicIcons[topic]!;

    final lower = topic.toLowerCase();
    if (lower.contains('flag') ||
        lower.contains('geography') ||
        lower.contains('country') ||
        lower.contains('world')) {
      return Icons.public_rounded;
    }
    if (lower.contains('movie') ||
        lower.contains('cinema') ||
        lower.contains('film') ||
        lower.contains('tv')) {
      return Icons.movie_creation_rounded;
    }
    if (lower.contains('anime') ||
        lower.contains('manga') ||
        lower.contains('otaku')) {
      return Icons.auto_awesome_rounded;
    }
    if (lower.contains('game') ||
        lower.contains('gaming') ||
        lower.contains('play')) {
      return Icons.sports_esports_rounded;
    }
    if (lower.contains('music') ||
        lower.contains('song') ||
        lower.contains('artist')) {
      return Icons.music_note_rounded;
    }
    if (lower.contains('sport') ||
        lower.contains('football') ||
        lower.contains('soccer')) {
      return Icons.sports_soccer_rounded;
    }
    if (lower.contains('science') ||
        lower.contains('bio') ||
        lower.contains('physics')) {
      return Icons.science_rounded;
    }
    if (lower.contains('history') || lower.contains('historical')) {
      return Icons.history_edu_rounded;
    }
    if (lower.contains('animal') ||
        lower.contains('pet') ||
        lower.contains('fauna')) {
      return Icons.pets_rounded;
    }
    if (lower.contains('food') ||
        lower.contains('cook') ||
        lower.contains('kitchen')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('car') ||
        lower.contains('vehicle') ||
        lower.contains('auto')) {
      return Icons.directions_car_rounded;
    }
    if (lower.contains('book') ||
        lower.contains('novel') ||
        lower.contains('literature')) {
      return Icons.menu_book_rounded;
    }
    return Icons.category_rounded;
  }
}

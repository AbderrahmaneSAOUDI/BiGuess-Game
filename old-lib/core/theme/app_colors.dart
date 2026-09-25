import 'package:flutter/material.dart';

/// Semantic colors and palette tokens used throughout BiGuess
class AppColors {
  AppColors._();

  static const Color primarySeed = Colors.blue;

  // Countdown timer colors
  static const Color countdownCritical = Color(0xFFFF3366); // Energetic Crimson (1s)
  static const Color countdownWarning = Color(0xFFFF9900);  // Vibrant Amber (2s)
  static const Color countdownAlert = Color(0xFFFFD700);    // Gold (3s)
  static const Color countdownDefault = Color(0xFF00E5FF);  // Electric Cyan (4s+)

  // Gameplay Action Buttons
  static const Color startGradientStart = Color(0xFF00E676); // Spring Green
  static const Color startGradientEnd = Color(0xFF00C853);   // Emerald Green
  static const Color refreshGradientStart = Color(0xFF2979FF); // Electric Blue
  static const Color refreshGradientEnd = Color(0xFF1565C0);   // Deep Blue
}

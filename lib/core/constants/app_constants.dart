import '../../domain/models/category.dart';

/// Centralized application constants and configurations
class AppConstants {
  AppConstants._();

  static const String appName = 'BiGuess Game';
  static const String appTagline = 'The Ultimate 2-Player Anime Mystery Challenge';
  static const String gdgTitle = 'GDG Ghardaia';
  static const String defaultVersion = '0.30.3';
  static const String fontFamily = 'GoogleSans';

  // Asset paths
  static const String gdgLogoPath = 'assets/logos/gdg_logo.webp';
  static const String appIconPath = 'assets/logos/biguess-icon.webp';
  static const String defaultProfilePath = 'assets/profile/profile.webp';

  // Default game values
  static const int defaultCountdownSeconds = 2;
  static const List<int> supportedCountdownDurations = [2, 3, 5, 10];

  // Default category list definition
  static const List<GameCategory> categories = [
    GameCategory(
      name: 'Attack on Titan',
      path: 'assets/images/attack_on_titan',
      logoPath: 'assets/logos/Attack on Titan.webp',
    ),
    GameCategory(
      name: 'Black Clover',
      path: 'assets/images/black_clover',
      logoPath: 'assets/logos/Black-Clover.webp',
    ),
    GameCategory(
      name: 'Demon Slayer',
      path: 'assets/images/demon_slayer',
      logoPath: 'assets/logos/Demon Slayer.webp',
    ),
    GameCategory(
      name: 'Hunter X Hunter',
      path: 'assets/images/hunter_x_hunter',
      logoPath: 'assets/logos/Hunter X Hunter.webp',
    ),
    GameCategory(
      name: 'Naruto',
      path: 'assets/images/naruto',
      logoPath: 'assets/logos/Naruto Uzumaki.webp',
    ),
    GameCategory(
      name: 'One Piece',
      path: 'assets/images/one_piece',
      logoPath: 'assets/logos/One Piece.webp',
    ),
    GameCategory(
      name: 'Bleach',
      path: 'assets/images/bleach',
      logoPath: 'assets/logos/Bleach.webp',
    ),
    GameCategory(
      name: 'Code Geass',
      path: 'assets/images/code_geass',
      logoPath: 'assets/logos/Code Geass.webp',
    ),
    GameCategory(
      name: 'Death Note',
      path: 'assets/images/death_note',
      logoPath: 'assets/logos/Death Note.webp',
    ),
    GameCategory(
      name: 'Detective Conan',
      path: 'assets/images/detective_conan',
      logoPath: 'assets/logos/Detective Conan.webp',
    ),
    GameCategory(
      name: 'Dr. Stone',
      path: 'assets/images/dr_stone',
      logoPath: 'assets/logos/Dr. Stone.webp',
    ),
    GameCategory(
      name: 'Dragon Ball Z',
      path: 'assets/images/dragon_ball_z',
      logoPath: 'assets/logos/Dragon Ball Z.webp',
    ),
    GameCategory(
      name: 'FMAB',
      path: 'assets/images/fmab',
      logoPath: 'assets/logos/FMAB.webp',
    ),
    GameCategory(
      name: 'Jujutsu Kaisen',
      path: 'assets/images/jujutsu_kaisen',
      logoPath: 'assets/logos/Jujutsu Kaisen.webp',
    ),
    GameCategory(
      name: 'My Hero Academia',
      path: 'assets/images/my_hero_academia',
      logoPath: 'assets/logos/My Hero Academia.webp',
    ),
    GameCategory(
      name: 'Solo Leveling',
      path: 'assets/images/solo_leveling',
      logoPath: 'assets/logos/Solo Leveling.webp',
    ),
    GameCategory(
      name: 'Tokyo Revengers',
      path: 'assets/images/tokyo_revengers',
      logoPath: 'assets/logos/Tokyo Revengers.webp',
    ),
    GameCategory(
      name: 'Vinland Saga',
      path: 'assets/images/vinland_saga',
      logoPath: 'assets/logos/Winland Saga.webp',
    ),
  ];
}

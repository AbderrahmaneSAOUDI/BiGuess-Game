import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../main.dart';
import '../widgets/animations/interactive_scale_card.dart';
import '../widgets/info_dialog.dart';
import 'game_screen.dart';

export '../widgets/info_dialog.dart'
    show
        GameInfoDialog,
        GameInfoTab,
        GameSettingsDialog,
        RulesContactDialog;

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  static const List<Map<String, String>> categories = [
    {
      'name': 'Attack on Titan',
      'path': 'assets/images/attack_on_titan',
      'logo_path': 'assets/logos/Attack on Titan.webp',
    },
    {
      'name': 'Black Clover',
      'path': 'assets/images/black_clover',
      'logo_path': 'assets/logos/Black-Clover.webp',
    },
    {
      'name': 'Demon Slayer',
      'path': 'assets/images/demon_slayer',
      'logo_path': 'assets/logos/Demon Slayer.webp',
    },
    {
      'name': 'Hunter X Hunter',
      'path': 'assets/images/hunter_x_hunter',
      'logo_path': 'assets/logos/Hunter X Hunter.webp',
    },
    {
      'name': 'Naruto',
      'path': 'assets/images/naruto',
      'logo_path': 'assets/logos/Naruto Uzumaki.webp',
    },
    {
      'name': 'One Piece',
      'path': 'assets/images/one_piece',
      'logo_path': 'assets/logos/One Piece.webp',
    },
    {
      'name': 'Bleach',
      'path': 'assets/images/bleach',
      'logo_path': 'assets/logos/Bleach.webp',
    },
    {
      'name': 'Code Geass',
      'path': 'assets/images/code_geass',
      'logo_path': 'assets/logos/Code Geass.webp',
    },
    {
      'name': 'Death Note',
      'path': 'assets/images/death_note',
      'logo_path': 'assets/logos/Death Note.webp',
    },
    {
      'name': 'Detective Conan',
      'path': 'assets/images/detective_conan',
      'logo_path': 'assets/logos/Detective Conan.webp',
    },
    {
      'name': 'Dr. Stone',
      'path': 'assets/images/dr_stone',
      'logo_path': 'assets/logos/Dr. Stone.webp',
    },
    {
      'name': 'Dragon Ball Z',
      'path': 'assets/images/dragon_ball_z',
      'logo_path': 'assets/logos/Dragon Ball Z.webp',
    },
    {
      'name': 'FMAB',
      'path': 'assets/images/fmab',
      'logo_path': 'assets/logos/FMAB.webp',
    },
    {
      'name': 'Jujutsu Kaisen',
      'path': 'assets/images/jujutsu_kaisen',
      'logo_path': 'assets/logos/Jujutsu Kaisen.webp',
    },
    {
      'name': 'My Hero Academia',
      'path': 'assets/images/my_hero_academia',
      'logo_path': 'assets/logos/My Hero Academia.webp',
    },
    {
      'name': 'Solo Leveling',
      'path': 'assets/images/solo_leveling',
      'logo_path': 'assets/logos/Solo Leveling.webp',
    },
    {
      'name': 'Tokyo Revengers',
      'path': 'assets/images/tokyo_revengers',
      'logo_path': 'assets/logos/Tokyo Revengers.webp',
    },
    {
      'name': 'Vinland Saga',
      'path': 'assets/images/vinland_saga',
      'logo_path': 'assets/logos/Winland Saga.webp',
    },
  ];

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _logoSpinController;

  @override
  void initState() {
    super.initState();
    _logoSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _logoSpinController.dispose();
    super.dispose();
  }

  void _triggerLogoSpin() {
    if (!_logoSpinController.isAnimating) {
      _logoSpinController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GDG Ghardaia',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.2),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: GestureDetector(
            onTap: _triggerLogoSpin,
            child: RotationTransition(
              turns: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _logoSpinController,
                  curve: Curves.easeOutBack,
                ),
              ),
              child: Image.asset('assets/logos/gdg_logo.webp'),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () {
              GameInfoDialog.show(
                context,
                initialTab: GameInfoTab.settings,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Rules & About',
            onPressed: () {
              GameInfoDialog.show(
                context,
                initialTab: GameInfoTab.howToPlay,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              turns: isDark ? 0.5 : 0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 300),
                scale: isDark ? 1.15 : 1.0,
                child: IconButton(
                  tooltip:
                      isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  ),
                  onPressed: () =>
                      ref.read(themeNotifierProvider.notifier).toggleTheme(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimationLimiter(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: CategoriesScreen.categories.length,
          itemBuilder: (context, index) {
            final category = CategoriesScreen.categories[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 800),
              columnCount: 2,
              child: SlideAnimation(
                verticalOffset: 50.0,
                curve: Curves.easeOutCubic,
                child: FadeInAnimation(
                  duration: const Duration(milliseconds: 800),
                  child: AnimatedCard(
                    category: category,
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder<void>(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              GameScreen(
                            categoryName: category['name']!,
                          ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.95,
                                  end: 1.0,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                                child: child,
                              ),
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 350),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AnimatedCard extends StatelessWidget {
  final Map<String, String> category;
  final VoidCallback onTap;

  const AnimatedCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryName = category['name'] ?? '';
    final logoPath = category['logo_path'] ?? '';

    return InteractiveScaleCard(
      onTap: onTap,
      glowColor: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ],
          ),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Hero(
                  tag: 'category_$categoryName',
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 700),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutBack,
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: (0.7 + 0.3 * value).clamp(0.0, 1.0),
                        child: child,
                      );
                    },
                    child: Image.asset(
                      logoPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image_rounded, size: 40),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 1,
                child: Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

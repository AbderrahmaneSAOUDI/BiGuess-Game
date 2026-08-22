import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../main.dart';
import '../widgets/info_dialog.dart';
import 'game_screen.dart';

export '../widgets/info_dialog.dart'
    show
        GameInfoDialog,
        GameInfoTab,
        GameSettingsDialog,
        RulesContactDialog;


class CategoriesScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GDG Ghardaia'),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Image.asset('assets/logos/gdg_logo.webp'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              GameInfoDialog.show(
                context,
                initialTab: GameInfoTab.settings,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
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
              turns: isDark ? 0.5 : 0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 300),
                scale: isDark ? 1.2 : 1.0,
                child: IconButton(
                  tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                  ),
                  onPressed: () => ref.read(themeNotifierProvider.notifier).toggleTheme(),
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
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 1200),
              columnCount: 2,
              child: SlideAnimation(
                horizontalOffset: 300.0,
                child: FadeInAnimation(
                  duration: const Duration(milliseconds: 1200),
                  child: AnimatedCard(
                    category: category,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => GameScreen(
                            categoryName: category['name']!,
                          ),
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

class AnimatedCard extends StatefulWidget {
  final Map<String, String> category;
  final VoidCallback onTap;

  const AnimatedCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotateAnimation;
  bool _isLongPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    setState(() => _isLongPressed = true);
    _controller.forward();
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    setState(() => _isLongPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryName = widget.category['name'] ?? '';
    final logoPath = widget.category['logo_path'] ?? '';

    return GestureDetector(
      onLongPressStart: _handleLongPressStart,
      onLongPressEnd: _handleLongPressEnd,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: _isLongPressed ? 6 : 4,
                offset: Offset(0, _isLongPressed ? 3 : 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surface.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Hero(
                          tag: 'category_$categoryName',
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            curve: Curves.easeOutBack,
                            builder: (context, double value, child) {
                              return Transform(
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateX((1 - value) * 0.5)
                                  ..rotateY((1 - value) * 0.5)
                                  ..scaleByDouble(
                                    value,
                                    value,
                                    1.0,
                                    1.0,
                                  ),
                                alignment: Alignment.center,
                                child: Image.asset(
                                  logoPath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 40),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 1,
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          curve: Curves.easeOutBack,
                          builder: (context, double value, child) {
                            return Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..translateByDouble(
                                  0.0,
                                  30.0 * (1 - value),
                                  0.0,
                                  1.0,
                                )
                                ..scaleByDouble(
                                  value,
                                  value,
                                  1.0,
                                  1.0,
                                ),
                              alignment: Alignment.center,
                              child: Text(
                                categoryName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        builder: (context, child) {
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateZ(_rotateAnimation.value)
              ..scaleByDouble(
                _scaleAnimation.value,
                _scaleAnimation.value,
                1.0,
                1.0,
              ),
            alignment: Alignment.center,
            child: child,
          );
        },
      ),
    );
  }
}


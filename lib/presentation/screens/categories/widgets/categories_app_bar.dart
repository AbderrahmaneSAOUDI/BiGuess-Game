import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../controllers/theme_controller.dart';
import '../../../dialogs/info/game_info_dialog.dart';
import '../../../widgets/animations/animated_glass_app_bar_background.dart';
import '../../../widgets/common/gdg_logo_button.dart';
import '../../../widgets/common/glass_icon_button.dart';

/// Top AppBar for Categories Screen with animated glass background and actions
class CategoriesAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  const CategoriesAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  ConsumerState<CategoriesAppBar> createState() => _CategoriesAppBarState();
}

class _CategoriesAppBarState extends ConsumerState<CategoriesAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOut,
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;
    final theme = Theme.of(context);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          flexibleSpace: const AnimatedGlassAppBarBackground(),
          title: Text(
            AppConstants.gdgTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
              color: theme.colorScheme.onSurface,
              shadows: [
                Shadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.7),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          leading: const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: GdgLogoButton(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.0),
              child: GlassIconButton.icon(
                iconData: Icons.settings_rounded,
                tooltip: 'Settings',
                onPressed: () {
                  GameInfoDialog.show(
                    context,
                    initialTab: GameInfoTab.settings,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.0),
              child: GlassIconButton.icon(
                iconData: Icons.info_outline_rounded,
                tooltip: 'Rules & About',
                onPressed: () {
                  GameInfoDialog.show(
                    context,
                    initialTab: GameInfoTab.howToPlay,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 3.0, right: 12.0),
              child: GlassIconButton(
                tooltip:
                    isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                onPressed: () =>
                    ref.read(themeNotifierProvider.notifier).toggleTheme(),
                icon: AnimatedRotation(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  turns: isDark ? 0.5 : 0,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 300),
                    scale: isDark ? 1.15 : 1.0,
                    child: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      size: 20,
                      color: isDark ? Colors.amberAccent : Colors.orangeAccent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

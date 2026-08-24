import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../dialogs/info/game_info_dialog.dart';
import '../../../widgets/animations/animated_glass_app_bar_background.dart';
import '../../../widgets/common/glass_icon_button.dart';

/// Top AppBar for Game Screen with animated glass background and actions
class GameAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String categoryName;

  const GameAppBar({
    super.key,
    required this.categoryName,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<GameAppBar> createState() => _GameAppBarState();
}

class _GameAppBarState extends State<GameAppBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          flexibleSpace: const AnimatedGlassAppBarBackground(),
          centerTitle: true,
          leading: canPop
              ? Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Center(
                    child: GlassIconButton.icon(
                      iconData: Icons.arrow_back_rounded,
                      tooltip: 'Back to Categories',
                      size: 38,
                      iconSize: 20,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                )
              : null,
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(
                    alpha: isDark ? 0.15 : 0.08,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.categoryName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                letterSpacing: -0.2,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3.0),
              child: GlassIconButton.icon(
                iconData: Icons.settings_rounded,
                tooltip: 'Settings',
                size: 38,
                iconSize: 20,
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
                tooltip: 'Rules & Info',
                size: 38,
                iconSize: 20,
                onPressed: () {
                  GameInfoDialog.show(
                    context,
                    initialTab: GameInfoTab.howToPlay,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4.0, right: 12.0),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  ),
                  child: Image.asset(
                    AppConstants.gdgLogoPath,
                    width: 26,
                    height: 26,
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

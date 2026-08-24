import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../controllers/theme_controller.dart';
import '../../../dialogs/info/game_info_dialog.dart';
import '../../../widgets/common/gdg_logo_button.dart';

/// Top AppBar for Categories Screen with actions and animated theme toggle
class CategoriesAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CategoriesAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;

    return AppBar(
      title: const Text(
        AppConstants.gdgTitle,
        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.2),
      ),
      leading: const Padding(
        padding: EdgeInsets.only(left: 12.0),
        child: GdgLogoButton(),
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
                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
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
    );
  }
}

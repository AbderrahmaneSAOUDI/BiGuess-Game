import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../dialogs/info/game_info_dialog.dart';

/// Top AppBar for Game Screen with category title and settings/info dialog shortcuts
class GameAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String categoryName;

  const GameAppBar({
    super.key,
    required this.categoryName,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        categoryName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_rounded),
          onPressed: () {
            GameInfoDialog.show(
              context,
              initialTab: GameInfoTab.settings,
            );
          },
        ),
        IconButton(
          tooltip: 'Rules & Info',
          icon: const Icon(Icons.info_outline_rounded),
          onPressed: () {
            GameInfoDialog.show(
              context,
              initialTab: GameInfoTab.howToPlay,
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Image.asset(AppConstants.gdgLogoPath, width: 36),
        ),
      ],
      centerTitle: true,
    );
  }
}

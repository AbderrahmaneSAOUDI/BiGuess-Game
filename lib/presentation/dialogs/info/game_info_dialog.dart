import 'package:flutter/material.dart';
import '../../../../domain/models/character_algorithm.dart';
import '../../../../domain/models/game_info_tab.dart';
import 'tabs/about_game_tab.dart';
import 'tabs/developers_tab.dart';
import 'tabs/how_to_play_tab.dart';
import 'tabs/settings_tab.dart';
import 'widgets/info_dialog_header.dart';

export '../../../../domain/models/game_info_tab.dart';

/// Modal dialog providing game configuration, rules, branding, and contributor information
class GameInfoDialog extends StatefulWidget {
  final GameInfoTab initialTab;
  final CharacterAlgorithm? algorithm;
  final ValueChanged<CharacterAlgorithm>? onAlgorithmChanged;

  const GameInfoDialog({
    super.key,
    this.initialTab = GameInfoTab.settings,
    this.algorithm,
    this.onAlgorithmChanged,
  });

  static Future<void> show(
    BuildContext context, {
    GameInfoTab initialTab = GameInfoTab.settings,
    CharacterAlgorithm? algorithm,
    ValueChanged<CharacterAlgorithm>? onAlgorithmChanged,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Game Info Dialog',
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, anim1, anim2) => GameInfoDialog(
        initialTab: initialTab,
        algorithm: algorithm,
        onAlgorithmChanged: onAlgorithmChanged,
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<GameInfoDialog> createState() => _GameInfoDialogState();
}

class _GameInfoDialogState extends State<GameInfoDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<_TabItem> _tabs = [
    _TabItem(
      label: 'Settings',
      icon: Icons.tune_rounded,
      tab: GameInfoTab.settings,
    ),
    _TabItem(
      label: 'How to Play',
      icon: Icons.sports_esports_rounded,
      tab: GameInfoTab.howToPlay,
    ),
    _TabItem(
      label: 'About Game',
      icon: Icons.auto_awesome_rounded,
      tab: GameInfoTab.aboutGame,
    ),
    _TabItem(
      label: 'Developers',
      icon: Icons.people_alt_rounded,
      tab: GameInfoTab.developers,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final initialIndex = _tabs.indexWhere((t) => t.tab == widget.initialTab);
    _tabController = TabController(
      length: _tabs.length,
      initialIndex: initialIndex >= 0 ? initialIndex : 0,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    final dialogWidth =
        mediaQuery.size.width > 680 ? 640.0 : mediaQuery.size.width * 0.92;
    final dialogHeight =
        mediaQuery.size.height > 720 ? 620.0 : mediaQuery.size.height * 0.88;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            // Top Bar
            InfoDialogHeader(
              onClose: () => Navigator.of(context).pop(),
            ),

            // Modern Segmented Capsule Tab Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: theme.brightness == Brightness.dark ? 0.45 : 0.60),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant
                        .withValues(alpha: theme.brightness == Brightness.dark ? 0.25 : 0.35),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  splashBorderRadius: BorderRadius.circular(12),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  labelColor: theme.colorScheme.onPrimary,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: _tabs.map((tab) {
                    return Tab(
                      height: 38,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tab.icon, size: 17),
                          const SizedBox(width: 6),
                          Text(tab.label),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Tab Content Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SettingsTab(
                    algorithm: widget.algorithm,
                    onAlgorithmChanged: widget.onAlgorithmChanged,
                  ),
                  const HowToPlayTab(),
                  const AboutGameTab(),
                  const DevelopersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final GameInfoTab tab;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.tab,
  });
}

/// Backward compatibility alias wrappers
class GameSettingsDialog extends StatelessWidget {
  final CharacterAlgorithm? algorithm;
  final ValueChanged<CharacterAlgorithm>? onAlgorithmChanged;

  const GameSettingsDialog({
    super.key,
    this.algorithm,
    this.onAlgorithmChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GameInfoDialog(
      initialTab: GameInfoTab.settings,
      algorithm: algorithm,
      onAlgorithmChanged: onAlgorithmChanged,
    );
  }
}

class RulesContactDialog extends StatelessWidget {
  final GameInfoTab initialTab;

  const RulesContactDialog({
    super.key,
    this.initialTab = GameInfoTab.howToPlay,
  });

  @override
  Widget build(BuildContext context) {
    return GameInfoDialog(
      initialTab: initialTab,
    );
  }
}

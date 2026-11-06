import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/models/pack_selection.dart';
import '../../../domain/use_cases/select_packs_use_case.dart';
import '../../../providers/pack_selection_controller.dart';
import '../../../providers/topic_pack_providers.dart';
import '../../widgets/animations/animated_glass_app_bar_background.dart';
import '../../widgets/animations/interactive_scale_card.dart';
import '../../widgets/common/glass_icon_button.dart';
import '../../dialogs/info/game_info_dialog.dart';
import 'selected_packs_setup.dart';
import 'pack_selection_controls.dart';

/// Second screen: Pack selection grid for a chosen topic
class PacksScreen extends ConsumerStatefulWidget {
  final String topicName;
  final String? topicId;

  const PacksScreen({super.key, required this.topicName, this.topicId});

  @override
  ConsumerState<PacksScreen> createState() => _PacksScreenState();
}

class _PacksScreenState extends ConsumerState<PacksScreen> {
  bool _wasCurrent = false;
  String? _resolvedTopicId;

  String get topicName => widget.topicName;
  String? get topicId => widget.topicId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = ModalRoute.isCurrentOf(context) ?? true;
    if (current && !_wasCurrent) {
      // Setup replaces itself with the game route. Refresh when Packs actually
      // becomes visible again, including after that replacement route exits.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _resolvedTopicId == null) return;
        ref.invalidate(packOptionsProvider(_resolvedTopicId!));
      });
    }
    _wasCurrent = current;
  }

  @override
  Widget build(BuildContext context) {
    final topics = ref
        .watch(contentRepositoryProvider)
        .getTopics()
        .where(
          (topic) =>
              topicId == null ? topic.name == topicName : topic.id == topicId,
        );
    final id = topics.firstOrNull?.id;
    _resolvedTopicId = id;
    final packs = id == null
        ? <PackOption>[]
        : ref.watch(packOptionsProvider(id));
    final selection = id == null ? null : ref.watch(packSelectionProvider(id));
    final controller = id == null
        ? null
        : ref.read(packSelectionProvider(id).notifier);
    final playableCount = packs
        .where((pack) => pack.availability == PackAvailability.playable)
        .length;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppConstants.getTopicColor(topicName);

    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight + 24;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _PacksAppBar(topicName: topicName, accent: accent),
      body: Stack(
        children: [
          // Ambient background with topic accent
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.35),
                  radius: 1.3,
                  colors: isDark
                      ? [
                          theme.colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.35,
                          ),
                          theme.scaffoldBackgroundColor,
                        ]
                      : [
                          theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.25,
                          ),
                          theme.scaffoldBackgroundColor,
                        ],
                ),
              ),
            ),
          ),
          AnimationLimiter(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, topPadding, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: selection == null
                        ? const Text('Topic unavailable.')
                        : PackSelectionControls(
                            selection: selection,
                            playableCount: playableCount,
                            selectedCount: selection.packIds
                                .where(
                                  (id) => packs.any(
                                    (option) =>
                                        option.pack.id == id &&
                                        option.availability ==
                                            PackAvailability.playable,
                                  ),
                                )
                                .length,
                            onModeChanged: controller!.setMode,
                            onRandomCountChanged: controller.setRandomCount,
                            onContinue: () =>
                                _navigateToSetup(context, ref, selection),
                          ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 280,
                          mainAxisExtent: 184,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: packs.length,
                    itemBuilder: (context, index) {
                      final option = packs[index];
                      final pack = option.pack;
                      final isAvailable =
                          option.availability == PackAvailability.playable;

                      return AnimationConfiguration.staggeredGrid(
                        position: index,
                        duration: const Duration(milliseconds: 700),
                        columnCount: 2,
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          curve: Curves.easeOutCubic,
                          child: FadeInAnimation(
                            duration: const Duration(milliseconds: 700),
                            child: _PackCard(
                              key: ValueKey('pack-${pack.id}'),
                              packName: pack.name,
                              accent: accent,
                              assetCount: option.cards.length,
                              isAvailable: isAvailable,
                              availability: option.availability,
                              selected:
                                  isAvailable &&
                                  (selection?.packIds.contains(pack.id) ??
                                      false),
                              onTap:
                                  isAvailable &&
                                      selection?.mode !=
                                          PackSelectionMode.random
                                  ? () {
                                      controller!.selectPack(pack.id);
                                      if (selection?.mode ==
                                          PackSelectionMode.single) {
                                        _navigateToSetup(
                                          context,
                                          ref,
                                          ref.read(packSelectionProvider(id!)),
                                        );
                                      }
                                    }
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSetup(
    BuildContext context,
    WidgetRef ref,
    PackSelection selection,
  ) {
    final PackCardPool pool;
    try {
      pool = ref.read(selectPacksUseCaseProvider)(selection);
    } on PackSelectionException catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SelectedPacksSetup(pool: pool, topicName: topicName),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}

/// Pack selection card with icon, count badge, and lock overlay for empty packs
class _PackCard extends StatelessWidget {
  final String packName;
  final Color accent;
  final int assetCount;
  final bool isAvailable;
  final PackAvailability availability;
  final bool selected;
  final VoidCallback? onTap;

  const _PackCard({
    super.key,
    required this.packName,
    required this.accent,
    required this.assetCount,
    required this.isAvailable,
    required this.availability,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InteractiveScaleCard(
      onTap: onTap,
      glowColor: isAvailable ? theme.colorScheme.primary : Colors.grey,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ],
          ),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: selected ? 2 : 1.2,
          ),
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                    ),
                    child: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : isAvailable
                          ? Icons.play_arrow_rounded
                          : Icons.lock_rounded,
                      size: 26,
                      color: isAvailable
                          ? theme.colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Pack name
                  Text(
                    _displayName(packName),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isAvailable
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Asset count
                  Text(
                    switch (availability) {
                      PackAvailability.playable => '$assetCount items',
                      PackAvailability.downloadRequired => 'Download required',
                      PackAvailability.unavailable => 'Unavailable',
                    },
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isAvailable
                          ? theme.colorScheme.primary
                          : Colors.grey.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _displayName(String raw) {
    // Convert Pack_01 → Pack 01, or keep as-is for names like "Flags"
    return raw.replaceAll('_', ' ');
  }
}

/// AppBar for the Packs screen with topic name and accent color
class _PacksAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String topicName;
  final Color accent;

  const _PacksAppBar({required this.topicName, required this.accent});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: const AnimatedGlassAppBarBackground(),
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10.0),
        child: Center(
          child: GlassIconButton.icon(
            iconData: Icons.arrow_back_rounded,
            tooltip: 'Back to Topics',
            size: 38,
            iconSize: 20,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppConstants.getTopicIcon(topicName),
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                topicName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  letterSpacing: -0.2,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
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
              GameInfoDialog.show(context, initialTab: GameInfoTab.settings);
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
              GameInfoDialog.show(context, initialTab: GameInfoTab.howToPlay);
            },
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

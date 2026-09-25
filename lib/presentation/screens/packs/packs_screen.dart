import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/topic_pack_providers.dart';
import '../../widgets/animations/animated_glass_app_bar_background.dart';
import '../../widgets/animations/interactive_scale_card.dart';
import '../game/game_screen.dart';

/// Second screen: Pack selection grid for a chosen topic
class PacksScreen extends ConsumerWidget {
  final String topicName;

  const PacksScreen({super.key, required this.topicName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packs = ref.watch(packsProvider(topicName));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppConstants.getTopicColor(topicName);

    final topPadding =
        MediaQuery.paddingOf(context).top + kToolbarHeight + 24;

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
                          accent.withValues(alpha: 0.12),
                          theme.scaffoldBackgroundColor,
                        ]
                      : [
                          accent.withValues(alpha: 0.08),
                          theme.scaffoldBackgroundColor,
                        ],
                ),
              ),
            ),
          ),
          AnimationLimiter(
            child: GridView.builder(
              padding: EdgeInsets.fromLTRB(20, topPadding, 20, 32),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: packs.length,
              itemBuilder: (context, index) {
                final pack = packs[index];
                final assetCount = ref.watch(
                  packAssetCountProvider((topic: topicName, pack: pack)),
                );
                final isAvailable = assetCount > 0;

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
                        packName: pack,
                        accent: accent,
                        assetCount: assetCount,
                        isAvailable: isAvailable,
                        onTap: isAvailable
                            ? () => _navigateToGame(context, topicName, pack)
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
    );
  }

  void _navigateToGame(BuildContext context, String topic, String pack) {
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            GameScreen(topicName: topic, packName: pack),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
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
  }
}

/// Pack selection card with icon, count badge, and lock overlay for empty packs
class _PackCard extends StatelessWidget {
  final String packName;
  final Color accent;
  final int assetCount;
  final bool isAvailable;
  final VoidCallback? onTap;

  const _PackCard({
    required this.packName,
    required this.accent,
    required this.assetCount,
    required this.isAvailable,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InteractiveScaleCard(
      onTap: onTap,
      glowColor: isAvailable ? accent : Colors.grey,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isAvailable
                ? (isDark
                    ? [
                        accent.withValues(alpha: 0.15),
                        theme.colorScheme.surface.withValues(alpha: 0.92),
                      ]
                    : [
                        accent.withValues(alpha: 0.08),
                        theme.colorScheme.surface,
                      ])
                : [
                    theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    theme.colorScheme.surface.withValues(alpha: 0.8),
                  ],
          ),
          border: Border.all(
            color: isAvailable
                ? accent.withValues(alpha: isDark ? 0.35 : 0.2)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1.5,
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
                      color: isAvailable
                          ? accent.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      isAvailable
                          ? Icons.play_arrow_rounded
                          : Icons.lock_rounded,
                      size: 26,
                      color: isAvailable ? accent : Colors.grey,
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
                    isAvailable ? '$assetCount items' : 'Coming soon',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isAvailable
                          ? accent.withValues(alpha: 0.8)
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
      flexibleSpace: AnimatedGlassAppBarBackground(accentColor: accent),
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10.0),
        child: Center(
          child: IconButton(
            tooltip: 'Back to Topics',
            onPressed: () => Navigator.of(context).maybePop(),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
              fixedSize: const Size(38, 38),
            ),
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppConstants.getTopicIcon(topicName),
              size: 18,
              color: accent,
            ),
            const SizedBox(width: 8),
            Text(
              topicName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                letterSpacing: -0.2,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

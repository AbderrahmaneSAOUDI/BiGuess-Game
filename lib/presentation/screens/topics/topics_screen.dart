import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/topic_pack_providers.dart';
import '../../../providers/theme_controller.dart';
import '../../widgets/animations/animated_glass_app_bar_background.dart';
import '../../widgets/animations/interactive_scale_card.dart';
import '../packs/packs_screen.dart';

/// First screen: Topic selection dashboard (Anime, Geography, Movies…)
class TopicsScreen extends ConsumerWidget {
  const TopicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(topicsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeNotifierProvider);

    final topPadding =
        MediaQuery.paddingOf(context).top + kToolbarHeight + 24;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _TopicsAppBar(isDark: themeMode == ThemeMode.dark),
      body: Stack(
        children: [
          // Ambient radial background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.4),
                  radius: 1.3,
                  colors: isDark
                      ? [
                          theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          theme.scaffoldBackgroundColor,
                        ]
                      : [
                          theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.25),
                          theme.scaffoldBackgroundColor,
                        ],
                ),
              ),
            ),
          ),
          AnimationLimiter(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(20, topPadding, 20, 32),
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                final totalAssets =
                    ref.watch(topicAssetCountProvider(topic));
                final packs = ref.watch(packsProvider(topic));
                final accentColor =
                    AppConstants.topicColors[topic] ?? theme.colorScheme.primary;
                final icon = AppConstants.topicIcons[topic] ??
                    Icons.category_rounded;

                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 700),
                  child: SlideAnimation(
                    verticalOffset: 60.0,
                    curve: Curves.easeOutCubic,
                    child: FadeInAnimation(
                      duration: const Duration(milliseconds: 700),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 18.0),
                        child: _TopicCard(
                          topic: topic,
                          icon: icon,
                          accent: accentColor,
                          packCount: packs.length,
                          totalAssets: totalAssets,
                          onTap: () => _navigateToPacks(context, topic),
                        ),
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

  void _navigateToPacks(BuildContext context, String topic) {
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PacksScreen(topicName: topic),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

/// Premium topic card with gradient accent, icon, and metadata
class _TopicCard extends StatelessWidget {
  final String topic;
  final IconData icon;
  final Color accent;
  final int packCount;
  final int totalAssets;
  final VoidCallback onTap;

  const _TopicCard({
    required this.topic,
    required this.icon,
    required this.accent,
    required this.packCount,
    required this.totalAssets,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InteractiveScaleCard(
      onTap: onTap,
      glowColor: accent,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    accent.withValues(alpha: 0.18),
                    theme.colorScheme.surface.withValues(alpha: 0.9),
                  ]
                : [
                    accent.withValues(alpha: 0.12),
                    theme.colorScheme.surface,
                  ],
          ),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.35 : 0.25),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Row(
            children: [
              // Accent icon circle
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: 0.3),
                      accent.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, size: 30, color: accent),
              ),
              const SizedBox(width: 20),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      topic,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MetadataChip(
                          icon: Icons.folder_rounded,
                          label: '$packCount packs',
                          color: accent,
                        ),
                        const SizedBox(width: 10),
                        _MetadataChip(
                          icon: Icons.image_rounded,
                          label: '$totalAssets items',
                          color: accent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: accent.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetadataChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glassmorphic AppBar for the Topics screen
class _TopicsAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool isDark;

  const _TopicsAppBar({required this.isDark});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: const AnimatedGlassAppBarBackground(),
      leading: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                AppConstants.appIconPath,
                width: 26,
                height: 26,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        AppConstants.appTitle,
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
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
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 20,
                  color: isDark ? Colors.amberAccent : Colors.orangeAccent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

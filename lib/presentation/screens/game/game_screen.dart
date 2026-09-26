import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/models/game_state.dart';
import '../../../providers/game_controller.dart';
import '../../../providers/game_settings_controller.dart';
import '../../widgets/animations/animated_action_button.dart';
import '../../widgets/animations/animated_countdown.dart';
import '../../widgets/animations/animated_mystery_box.dart';
import '../../widgets/animations/animated_glass_app_bar_background.dart';
import '../../widgets/animations/animated_character_card.dart';
import '../../widgets/common/glass_icon_button.dart';
import '../../dialogs/info/game_info_dialog.dart';
import 'widgets/game_empty_state.dart';

/// Main gameplay duel screen for a selected topic + pack
class GameScreen extends ConsumerStatefulWidget {
  final String topicName;
  final String packName;

  const GameScreen({
    super.key,
    required this.topicName,
    required this.packName,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  ({String topic, String pack}) get _key =>
      (topic: widget.topicName, pack: widget.packName);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = ref.read(gameRoundProvider(_key));
        for (final asset in state.allImages.take(5)) {
          precacheImage(
            AssetImage(asset),
            context,
            onError: (_, __) {},
          );
        }
      }
    });
  }

  Widget _buildContent(
    BuildContext context,
    GameRoundState state,
    BoxConstraints constraints,
  ) {
    if (state.noImagesFound) {
      return const GameEmptyState(key: ValueKey('empty'));
    }

    if (state.isCountingDown) {
      return AnimatedCountdown(
        key: ValueKey('countdown_${state.countdown}'),
        countdown: state.countdown,
      );
    } else if (state.showPicture && state.currentImageAsset != null) {
      return _GameCharacterDisplay(
        key: ValueKey('character_${state.currentImageAsset}'),
        imageAsset: state.currentImageAsset!,
        characterName: state.correctAnswer,
        constraints: constraints,
      );
    } else {
      return AnimatedMysteryBox(
        key: const ValueKey('mystery'),
        onTap: state.isLoading || state.isCountingDown
            ? null
            : () => ref
                .read(gameRoundProvider(_key).notifier)
                .startCountdown(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(gameRoundProvider(_key));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _GameAppBar(
        topicName: widget.topicName,
        packName: widget.packName,
      ),
      body: Stack(
        children: [
          // Background ambient gradient
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.3),
                  radius: 1.2,
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

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Center(
                        child: RepaintBoundary(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(
                                    begin: 0.92,
                                    end: 1.0,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildContent(context, state, constraints),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  reverseDuration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.4),
                          end: Offset.zero,
                        ).animate(animation),
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.85,
                            end: 1.0,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: (state.showPicture &&
                          state.currentImageAsset != null &&
                          !state.noImagesFound)
                      ? Padding(
                          key: const ValueKey('refresh_action_button'),
                          padding:
                              const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedActionButton(
                                hasStarted: true,
                                isEnabled:
                                    !state.isLoading && !state.isCountingDown,
                                onPressed: () => ref
                                    .read(gameRoundProvider(_key).notifier)
                                    .startCountdown(),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                key: const ValueKey('image_disclaimer'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 13,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.45)
                                          : Colors.black.withValues(alpha: 0.45),
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        AppConstants.imageDisclaimer,
                                        key: const ValueKey('image_disclaimer_text'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w400,
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.45)
                                              : Colors.black.withValues(alpha: 0.45),
                                          letterSpacing: 0.15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('no_action_button'),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Responsive layout container for displaying the revealed character card
class _GameCharacterDisplay extends ConsumerWidget {
  final String imageAsset;
  final String? characterName;
  final BoxConstraints constraints;

  const _GameCharacterDisplay({
    super.key,
    required this.imageAsset,
    this.characterName,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showNameHint = ref.watch(showCharacterNameHintProvider);
    final bool hasName = characterName != null;
    final double nameReservedHeight = hasName ? 60.0 : 0.0;

    final double availableHeight =
        (constraints.maxHeight - nameReservedHeight - 6.0).clamp(0.0, double.infinity);
    final double effectiveContainerWidth =
        constraints.maxWidth > 0 ? constraints.maxWidth : 360.0;
    final double availableWidth = effectiveContainerWidth * 0.80;

    return AnimatedCharacterCard(
      key: ValueKey(imageAsset),
      imageAsset: imageAsset,
      characterName: characterName,
      showNameHint: showNameHint,
      onToggleName: () =>
          ref.read(showCharacterNameHintProvider.notifier).toggle(),
      maxWidth: availableWidth,
      maxHeight: availableHeight,
    );
  }
}

/// AppBar for the Game screen showing topic > pack breadcrumb
class _GameAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String topicName;
  final String packName;

  const _GameAppBar({
    required this.topicName,
    required this.packName,
  });

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
            tooltip: 'Back to Packs',
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
        child: Text(
          packName.replaceAll('_', ' '),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
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
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

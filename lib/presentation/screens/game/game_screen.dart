import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/game_state.dart';
import '../../controllers/game_controller.dart';
import '../../widgets/animations/animated_action_button.dart';
import '../../widgets/animations/animated_countdown.dart';
import '../../widgets/animations/animated_mystery_box.dart';
import 'widgets/game_app_bar.dart';
import 'widgets/game_character_display.dart';
import 'widgets/game_empty_state.dart';

export '../../../domain/models/character_algorithm.dart';
export '../../controllers/game_settings_controller.dart'
    show
        characterAlgorithmProvider,
        countdownDurationProvider,
        showCharacterNameHintProvider;

/// Main gameplay duel screen for a selected category
class GameScreen extends ConsumerStatefulWidget {
  final String categoryName;

  const GameScreen({
    super.key,
    required this.categoryName,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = ref.read(gameRoundProvider(widget.categoryName));
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

  Widget _buildContent(BuildContext context, GameRoundState state) {
    if (state.noImagesFound) {
      return const GameEmptyState(key: ValueKey('empty'));
    }

    if (state.isCountingDown) {
      return AnimatedCountdown(
        key: ValueKey('countdown_${state.countdown}'),
        countdown: state.countdown,
      );
    } else if (state.showPicture && state.currentImageAsset != null) {
      return GameCharacterDisplay(
        key: ValueKey('character_${state.currentImageAsset}'),
        imageAsset: state.currentImageAsset!,
        characterName: state.correctAnswer,
      );
    } else {
      return AnimatedMysteryBox(
        key: const ValueKey('mystery'),
        onTap: state.isLoading || state.isCountingDown
            ? null
            : () => ref
                .read(gameRoundProvider(widget.categoryName).notifier)
                .startCountdown(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(gameRoundProvider(widget.categoryName));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GameAppBar(categoryName: widget.categoryName),
      body: Stack(
        children: [
          // Background ambient gradient extending behind the glass AppBar
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
                  child: Center(
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
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              )),
                              child: child,
                            ),
                          );
                        },
                        child: _buildContent(context, state),
                      ),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  reverseDuration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.4),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        )),
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.85,
                            end: 1.0,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                          )),
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
                              const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                          child: AnimatedActionButton(
                            hasStarted: true,
                            isEnabled: !state.isLoading && !state.isCountingDown,
                            onPressed: () => ref
                                .read(gameRoundProvider(widget.categoryName)
                                    .notifier)
                                .startCountdown(),
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

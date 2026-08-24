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
      return const GameEmptyState();
    }

    if (state.isCountingDown) {
      return AnimatedCountdown(
        key: ValueKey(state.countdown),
        countdown: state.countdown,
      );
    } else if (state.showPicture && state.currentImageAsset != null) {
      return GameCharacterDisplay(
        imageAsset: state.currentImageAsset!,
        characterName: state.correctAnswer,
      );
    } else {
      return AnimatedMysteryBox(
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
    final notifier = ref.read(gameRoundProvider(widget.categoryName).notifier);

    return Scaffold(
      appBar: GameAppBar(categoryName: widget.categoryName),
      body: Stack(
        children: [
          // Background ambient gradient
          AnimatedContainer(
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

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: _buildContent(context, state),
                ),
              ),
              if (!state.noImagesFound)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                  child: AnimatedActionButton(
                    hasStarted: state.hasStarted,
                    isEnabled: !state.isLoading && !state.isCountingDown,
                    onPressed: notifier.startCountdown,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/game_state.dart';
import '../domain/models/game_session.dart';
import '../domain/use_cases/select_character_use_case.dart';
import 'game_settings_controller.dart';
import 'topic_pack_providers.dart';

/// Notifier managing the active game round state and countdown transitions.
/// Keyed by a record of (topic, pack) to support the new hierarchy.
class GameRoundNotifier
    extends
        AutoDisposeFamilyNotifier<
          GameRoundState,
          ({String topic, String pack})
        > {
  Timer? _countdownTimer;
  final GameContentSnapshot? configuredGame;
  int? _frozenCountdownDuration;
  CharacterAlgorithm? _frozenAlgorithm;

  GameRoundNotifier({this.configuredGame});

  @override
  GameRoundState build(({String topic, String pack}) arg) {
    ref.onDispose(() {
      _countdownTimer?.cancel();
    });

    final game = configuredGame;
    final assets = game == null
        ? ref.watch(packAssetsProvider(arg))
        : List<String>.unmodifiable(
            game.cards.map((card) => card.imageReference),
          );
    if (game != null) {
      _frozenCountdownDuration = ref.read(countdownDurationProvider);
      _frozenAlgorithm = ref.read(characterAlgorithmProvider);
    }

    if (assets.isEmpty) {
      return const GameRoundState(isLoading: false, noImagesFound: true);
    }

    return GameRoundState(
      isLoading: false,
      noImagesFound: false,
      allImages: assets,
      remainingImages: List<String>.from(assets),
      configuration: game?.configuration,
    );
  }

  void startCountdown() {
    if (state.isCountingDown || state.hasReachedRoundLimit) return;
    if (state.noImagesFound || state.allImages.isEmpty) {
      state = state.copyWith(showPicture: false);
      return;
    }

    _countdownTimer?.cancel();
    final countdownDuration =
        _frozenCountdownDuration ?? ref.read<int>(countdownDurationProvider);

    // Reset character name to hidden state when refreshing or drawing a card
    ref.read(showCharacterNameHintProvider.notifier).set(false);

    state = state.copyWith(
      isCountingDown: true,
      showPicture: false,
      clearCurrentAsset: true,
      clearCorrectAnswer: true,
      countdown: countdownDuration,
      hasStarted: true,
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countdown > 1) {
        state = state.copyWith(countdown: state.countdown - 1);
      } else {
        timer.cancel();
        _revealCharacter();
      }
    });
  }

  void _revealCharacter() {
    final algorithm =
        _frozenAlgorithm ??
        ref.read<CharacterAlgorithm>(characterAlgorithmProvider);
    final selectUseCase = SelectCharacterUseCase();

    final result = selectUseCase(
      allImages: state.allImages,
      remainingImages: state.remainingImages,
      algorithm: algorithm,
    );

    if (result.hasImages && result.assetPath != null) {
      // Imported images use opaque references; their names belong to Cards.
      final cards = configuredGame?.cards;
      final selected = cards?.firstWhere(
        (card) => card.imageReference == result.assetPath,
      );
      state = state.copyWith(
        isCountingDown: false,
        showPicture: true,
        currentImageAsset: result.assetPath,
        correctAnswer: selected?.name ?? result.characterName,
        remainingImages: result.updatedRemainingImages,
        roundsPlayed: state.roundsPlayed + 1,
      );
    } else {
      state = state.copyWith(
        isCountingDown: false,
        noImagesFound: true,
        showPicture: false,
      );
    }
  }

  void reset() {
    // Configured games must exit to Packs to configure another game.
    if (configuredGame != null) return;
    _countdownTimer?.cancel();
    state = GameRoundState(
      isLoading: false,
      noImagesFound: state.allImages.isEmpty,
      allImages: state.allImages,
      remainingImages: List<String>.from(state.allImages),
    );
  }
}

final gameRoundProvider = NotifierProvider.autoDispose
    .family<GameRoundNotifier, GameRoundState, ({String topic, String pack})>(
      GameRoundNotifier.new,
    );

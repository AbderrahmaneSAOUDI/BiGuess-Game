import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game_state.dart';
import 'category_controller.dart';
import 'game_settings_controller.dart';

/// Notifier managing the active game round state and countdown transitions
class GameRoundNotifier extends AutoDisposeFamilyNotifier<GameRoundState, String> {
  Timer? _countdownTimer;

  @override
  GameRoundState build(String arg) {
    ref.onDispose(() {
      _countdownTimer?.cancel();
    });

    final repo = ref.watch(categoryRepositoryProvider);
    final assets = repo.getAssetsForCategory(arg);

    if (assets.isEmpty) {
      return const GameRoundState(
        isLoading: false,
        noImagesFound: true,
      );
    }

    return GameRoundState(
      isLoading: false,
      noImagesFound: false,
      allImages: assets,
      remainingImages: List<String>.from(assets),
    );
  }

  void startCountdown() {
    if (state.isCountingDown) return;
    if (state.noImagesFound || state.allImages.isEmpty) {
      state = state.copyWith(showPicture: false);
      return;
    }

    _countdownTimer?.cancel();
    final countdownDuration = ref.read(countdownDurationProvider);

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
    final algorithm = ref.read(characterAlgorithmProvider);
    final selectUseCase = ref.read(selectCharacterUseCaseProvider);

    final result = selectUseCase(
      allImages: state.allImages,
      remainingImages: state.remainingImages,
      algorithm: algorithm,
    );

    if (result.hasImages && result.assetPath != null) {
      state = state.copyWith(
        isCountingDown: false,
        showPicture: true,
        currentImageAsset: result.assetPath,
        correctAnswer: result.characterName,
        remainingImages: result.updatedRemainingImages,
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
    _countdownTimer?.cancel();
    state = GameRoundState(
      isLoading: false,
      noImagesFound: state.allImages.isEmpty,
      allImages: state.allImages,
      remainingImages: List<String>.from(state.allImages),
    );
  }
}

final gameRoundProvider =
    NotifierProvider.autoDispose.family<GameRoundNotifier, GameRoundState, String>(
  GameRoundNotifier.new,
);

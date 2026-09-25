import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/character_algorithm.dart';

export '../../domain/models/character_algorithm.dart';

/// Character rotation algorithm notifier
class CharacterAlgorithmNotifier extends Notifier<CharacterAlgorithm> {
  @override
  CharacterAlgorithm build() => CharacterAlgorithm.nonRepeating;

  void setAlgorithm(CharacterAlgorithm algorithm) {
    state = algorithm;
  }
}

final characterAlgorithmProvider =
    NotifierProvider<CharacterAlgorithmNotifier, CharacterAlgorithm>(
  CharacterAlgorithmNotifier.new,
);

/// Countdown duration in seconds notifier
class CountdownDurationNotifier extends Notifier<int> {
  @override
  int build() => AppConstants.defaultCountdownSeconds;

  void setDuration(int seconds) {
    state = seconds;
  }
}

final countdownDurationProvider =
    NotifierProvider<CountdownDurationNotifier, int>(
  CountdownDurationNotifier.new,
);

/// Show character name hint notifier
class ShowCharacterNameHintNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() {
    state = !state;
  }

  void set(bool value) {
    state = value;
  }
}

final showCharacterNameHintProvider =
    NotifierProvider<ShowCharacterNameHintNotifier, bool>(
  ShowCharacterNameHintNotifier.new,
);

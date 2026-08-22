import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CharacterAlgorithm {
  random,
  nonRepeating,
}

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

class CountdownDurationNotifier extends Notifier<int> {
  @override
  int build() => 2;

  void setDuration(int seconds) {
    state = seconds;
  }
}

final countdownDurationProvider =
    NotifierProvider<CountdownDurationNotifier, int>(
      CountdownDurationNotifier.new,
    );

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


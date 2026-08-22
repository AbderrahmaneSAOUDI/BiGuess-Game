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

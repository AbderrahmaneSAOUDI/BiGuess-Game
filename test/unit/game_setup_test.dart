import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biguess/domain/models/card.dart';
import 'package:biguess/domain/models/difficulty.dart';
import 'package:biguess/domain/models/entitlement.dart';
import 'package:biguess/domain/models/game_setup.dart';
import 'package:biguess/domain/models/pack.dart';
import 'package:biguess/domain/models/topic.dart';
import 'package:biguess/providers/entitlement_provider.dart';

void main() {
  final cards = [
    for (final level in Difficulty.values)
      Card(
        id: 'card-${level.value}',
        packId: 'pack',
        name: 'Card ${level.value}',
        imageReference: 'assets/${level.value}.webp',
        difficulty: level,
      ),
  ];
  GameSetupContent content(List<Card>? installed) => GameSetupContent(
    topic: Topic(id: 'topic', name: 'Topic'),
    pack: Pack(id: 'pack', topicId: 'topic', name: 'Pack'),
    installedCards: installed,
  );

  test(
    'Free is the default; release ignores internal Pro environment define',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(entitlementProvider).isProTestEnabled, isFalse);
      for (final toggle in [false, true]) {
        final entitlement = Entitlement.fromEnvironment(
          isReleaseBuild: true,
          isProTestEnabled: toggle,
        );
        expect(entitlement.maxStoredPacks, 5);
        expect(entitlement.maxRounds, 10);
      }
      const debug = Entitlement.fromEnvironment(
        isReleaseBuild: false,
        isProTestEnabled: true,
      );
      expect(debug.maxStoredPacks, isNull);
      expect(debug.maxRounds, isNull);
      expect(debug.allowsRounds(100000), isTrue);
      expect(debug.allowsNewPack(100000), isTrue);
    },
  );

  test('default Easy and cumulative Medium/Hard filter all matching Cards', () {
    const defaults = GameSetup();
    expect(defaults.maximumDifficulty, Difficulty.easy);
    expect(defaults.rounds, 10);
    for (final level in Difficulty.values) {
      final setup = GameSetup(maximumDifficulty: level);
      expect(setup.eligibleCards(cards).length, level.value);
    }
  });

  test(
    'invalid rounds, missing installation and empty pools cannot freeze',
    () {
      for (final rounds in [-1, 0, 11]) {
        final setup = GameSetup(rounds: rounds);
        expect(
          setup.validate(
            entitlement: const Entitlement(),
            content: content(cards),
          ),
          rounds > 10
              ? GameSetupError.freeRoundLimit
              : GameSetupError.invalidRounds,
        );
        expect(
          () => setup.freeze(
            entitlement: const Entitlement(),
            content: content(cards),
          ),
          throwsStateError,
        );
      }
      for (final missing in [null, content(null)]) {
        expect(
          const GameSetup().validate(
            entitlement: const Entitlement(),
            content: missing,
          ),
          GameSetupError.packNotInstalled,
        );
      }
      for (final empty in [<Card>[], cards.skip(1).toList()]) {
        expect(
          const GameSetup().validate(
            entitlement: const Entitlement(),
            content: content(empty),
          ),
          GameSetupError.emptyEligiblePool,
        );
      }
    },
  );

  test('Pro removes limits and Start detaches settings/content from input', () {
    final input = List<Card>.from(cards);
    const draft = GameSetup(maximumDifficulty: Difficulty.medium, rounds: 1234);
    final snapshot = draft.freeze(
      entitlement: const Entitlement(isProTestEnabled: true),
      content: content(input),
    );
    input.clear();
    expect(snapshot.configuration.rounds, 1234);
    expect(snapshot.configuration.maximumDifficulty, Difficulty.medium);
    expect(snapshot.configuration.isPro, isTrue);
    expect(snapshot.configuration.topicId, 'topic');
    expect(snapshot.configuration.packIds, ['pack']);
    expect(snapshot.cards, cards.take(2));
    expect(() => snapshot.cards.clear(), throwsUnsupportedError);
  });
}

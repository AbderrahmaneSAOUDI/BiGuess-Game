import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biguess/domain/models/card.dart';
import 'package:biguess/domain/models/difficulty.dart';
import 'package:biguess/domain/models/game_session_configuration.dart';
import 'package:biguess/domain/models/game_session.dart';
import 'package:biguess/domain/models/pack.dart';
import 'package:biguess/domain/models/topic.dart';
import 'package:biguess/providers/game_session_controller.dart';
import 'package:biguess/providers/topic_pack_providers.dart';

Card card(
  String id, {
  String packId = 'pack',
  Difficulty difficulty = Difficulty.easy,
}) => Card(
  id: id,
  packId: packId,
  name: 'Original $id',
  imageReference: 'private/generation-1/$id.webp',
  difficulty: difficulty,
);

void main() {
  late ProviderContainer container;
  late GameSessionNotifier controller;
  late Topic topic;
  late List<Pack> packs;
  late List<Card> cards;

  GameSession getSession() => container.read(gameSessionProvider);

  GameSessionConfiguration configuration({
    int rounds = 3,
    bool isPro = false,
  }) => GameSessionConfiguration(
    topicId: 'topic',
    packIds: ['pack'],
    rounds: rounds,
    isPro: isPro,
  );

  void start({int rounds = 3, bool isPro = false}) {
    controller.configure(configuration(rounds: rounds, isPro: isPro));
    controller.start(
      topic: topic,
      installedPacks: packs,
      installedCards: cards,
    );
  }

  void finish() {
    while (getSession().phase == GameSessionPhase.active) {
      controller.nextRound();
    }
  }

  setUp(() {
    container = ProviderContainer(
      overrides: [
        gameSessionProvider.overrideWith(
          () => GameSessionNotifier(random: Random(13)),
        ),
        // Starting and advancing a session must never read the live repository.
        contentRepositoryProvider.overrideWith(
          (ref) => throw StateError('Live content is unavailable'),
        ),
      ],
    );
    addTearDown(container.dispose);
    controller = container.read(gameSessionProvider.notifier);
    topic = Topic(id: 'topic', name: 'Original Topic', published: true);
    packs = [
      Pack(
        id: 'pack',
        topicId: 'topic',
        name: 'Original Pack',
        published: true,
      ),
    ];
    cards = [card('one'), card('two'), card('three')];
  });

  group('Configuration', () {
    test('starts at Home and keeps configuration separate from play', () {
      expect(getSession().phase, GameSessionPhase.home);
      expect(getSession().roundNumber, 0);
      expect(getSession().assignedCard, isNull);
      final config = configuration();
      controller.configure(config);
      expect(getSession().phase, GameSessionPhase.configuring);
      expect(getSession().configuration, same(config));
      expect(getSession().snapshot, isNull);
      expect(getSession().completedRounds, 0);
      expect(getSession().retainsContent, isFalse);
      controller.configure(configuration(rounds: 2));
      expect(getSession().configuration!.rounds, 2);
    });

    test('defaults to Free and Easy; configuration copies selected IDs', () {
      final ids = ['pack'];
      final config = GameSessionConfiguration(
        topicId: 'topic',
        packIds: ids,
        rounds: 1,
      );
      ids.clear();
      expect(config.packIds, ['pack']);
      expect(config.maximumDifficulty, Difficulty.easy);
      expect(config.isPro, isFalse);
      expect(() => config.packIds.clear(), throwsUnsupportedError);
    });

    test('rejects invalid rounds, empty/duplicate Packs and invalid IDs', () {
      for (final rounds in [-1, 0, 11, 100]) {
        expect(() => configuration(rounds: rounds), throwsRangeError);
      }
      expect(() => configuration(rounds: 0, isPro: true), throwsRangeError);
      for (final ids in <List<String>>[
        [],
        ['pack', 'pack'],
        [''],
      ]) {
        expect(
          () => GameSessionConfiguration(
            topicId: 'topic',
            packIds: ids,
            rounds: 1,
          ),
          throwsArgumentError,
        );
      }
      expect(
        () =>
            GameSessionConfiguration(topicId: '', packIds: ['pack'], rounds: 1),
        throwsArgumentError,
      );
    });

    test('failed Start leaves configuration intact and can be retried', () {
      controller.configure(configuration());
      final before = getSession();
      for (final invalidCards in <List<Card>>[
        [],
        [card('hard', difficulty: Difficulty.hard)],
        [card('one'), card('one')],
      ]) {
        expect(
          () => controller.start(
            topic: topic,
            installedPacks: packs,
            installedCards: invalidCards,
          ),
          throwsArgumentError,
        );
        expect(getSession(), same(before));
      }
      controller.start(
        topic: topic,
        installedPacks: packs,
        installedCards: cards,
      );
      expect(getSession().phase, GameSessionPhase.active);
      expect(getSession().roundIndex, 0);
    });

    test('requires the selected installed Packs within exactly one Topic', () {
      final config = GameSessionConfiguration(
        topicId: 'topic',
        packIds: ['pack', 'second'],
        rounds: 1,
      );
      controller.configure(config);
      for (final invalidPacks in <List<Pack>>[
        [],
        packs,
        [...packs, Pack(id: 'second', topicId: 'other', name: 'Other Topic')],
        [
          ...packs,
          Pack(id: 'second', topicId: 'topic', name: 'Deleted', deleted: true),
        ],
        [packs.single, packs.single],
      ]) {
        expect(
          () => controller.start(
            topic: topic,
            installedPacks: invalidPacks,
            installedCards: cards,
          ),
          throwsArgumentError,
        );
        expect(getSession().phase, GameSessionPhase.configuring);
      }
      for (final invalidTopic in [
        Topic(id: 'other', name: 'Other'),
        Topic(id: 'topic', name: 'Deleted', deleted: true),
      ]) {
        expect(
          () => controller.start(
            topic: invalidTopic,
            installedPacks: packs,
            installedCards: cards,
          ),
          throwsArgumentError,
        );
      }
    });

    test('captures only selected Packs and cumulative eligible Cards', () {
      controller.configure(
        GameSessionConfiguration(
          topicId: 'topic',
          packIds: ['second', 'pack'],
          maximumDifficulty: Difficulty.medium,
          rounds: 3,
        ),
      );
      controller.start(
        topic: topic,
        installedPacks: [
          ...packs,
          Pack(id: 'second', topicId: 'topic', name: 'Second'),
          Pack(id: 'unselected', topicId: 'other', name: 'Unselected'),
        ],
        installedCards: [
          card('easy'),
          card('medium', packId: 'second', difficulty: Difficulty.medium),
          card('hard', difficulty: Difficulty.hard),
          card('outside', packId: 'unselected'),
        ],
      );
      final snapshot = getSession().snapshot!;
      expect(snapshot.packs.map((pack) => pack.id), ['second', 'pack']);
      expect(snapshot.cards.map((card) => card.id), ['easy', 'medium']);
    });
  });

  group('Round transitions', () {
    for (var rounds = 1; rounds <= 10; rounds++) {
      test('Free game assigns exactly $rounds rounds, then completes', () {
        start(rounds: rounds);
        final original = getSession();
        for (var index = 0; index < rounds; index++) {
          final session = getSession();
          expect(session.phase, GameSessionPhase.active);
          expect(session.roundIndex, index);
          expect(session.roundNumber, index + 1);
          expect(session.completedRounds, index);
          expect(session.snapshot, same(original.snapshot));
          expect(cards, contains(session.assignedCard));
          controller.nextRound();
        }
        final completed = getSession();
        expect(completed.phase, GameSessionPhase.completed);
        expect(completed.roundNumber, rounds);
        expect(completed.completedRounds, rounds);
        expect(completed.assignedCard, isNull);
        expect(completed.retainsContent, isTrue);
        expect(controller.nextRound, throwsStateError);
        expect(getSession(), same(completed));
        // Retained prior states cannot be modified by subsequent transitions.
        expect(original.phase, GameSessionPhase.active);
        expect(original.roundIndex, 0);
        expect(original.assignedCard, isNotNull);
      });
    }

    test('Pro supports a configured round count beyond ten', () {
      start(rounds: 25, isPro: true);
      finish();
      expect(getSession().completedRounds, 25);
    });

    test('uses the local deck across refills without shortening a session', () {
      start(rounds: 9);
      for (var cycle = 0; cycle < 3; cycle++) {
        final drawn = <String>[];
        for (var index = 0; index < cards.length; index++) {
          drawn.add(getSession().assignedCard!.id);
          controller.nextRound();
        }
        expect(drawn, unorderedEquals(cards.map((card) => card.id)));
      }
      expect(getSession().phase, GameSessionPhase.completed);
    });

    test(
      'out-of-order actions cannot skip setup or replace an active game',
      () {
        expect(controller.nextRound, throwsStateError);
        expect(controller.requestReplay, throwsStateError);
        expect(
          () => controller.start(
            topic: topic,
            installedPacks: packs,
            installedCards: cards,
          ),
          throwsStateError,
        );
        controller.configure(configuration());
        expect(controller.nextRound, throwsStateError);
        expect(controller.requestReplay, throwsStateError);
        controller.start(
          topic: topic,
          installedPacks: packs,
          installedCards: cards,
        );
        final active = getSession();
        expect(() => controller.configure(configuration()), throwsStateError);
        expect(controller.requestReplay, throwsStateError);
        expect(
          () => controller.start(
            topic: topic,
            installedPacks: packs,
            installedCards: cards,
          ),
          throwsStateError,
        );
        expect(getSession(), same(active));
      },
    );
  });

  group('Exit and replay routing', () {
    test('Free replay requires Home arrival before a fresh ten-round game', () {
      start(rounds: 10);
      finish();
      final completed = getSession();
      for (var tap = 0; tap < 3; tap++) {
        expect(controller.requestReplay(), GameReplayRoute.home);
        expect(getSession(), same(completed));
        expect(() => controller.configure(configuration()), throwsStateError);
        expect(
          () => controller.start(
            topic: topic,
            installedPacks: packs,
            installedCards: cards,
          ),
          throwsStateError,
        );
      }
      controller.returnHome();
      expect(getSession().completedRounds, 0);
      expect(getSession().roundIndex, isNull);
      expect(getSession().snapshot, isNull);
      start(rounds: 10);
      expect(getSession().roundIndex, 0);
      finish();
      expect(getSession().completedRounds, 10);
    });

    test('Pro replay immediately reuses frozen configuration and content', () {
      start(rounds: 11, isPro: true);
      final initial = getSession();
      finish();
      packs.clear();
      cards.clear();
      expect(controller.requestReplay(), GameReplayRoute.game);
      expect(getSession().phase, GameSessionPhase.active);
      expect(getSession().roundIndex, 0);
      expect(getSession().completedRounds, 0);
      expect(getSession().configuration, same(initial.configuration));
      expect(getSession().snapshot, same(initial.snapshot));
      finish();
      expect(getSession().completedRounds, 11);
    });

    for (final phase in GameSessionPhase.values) {
      test('exit is safe and idempotent from ${phase.name}', () {
        if (phase != GameSessionPhase.home) {
          controller.configure(configuration());
        }
        if (phase == GameSessionPhase.active ||
            phase == GameSessionPhase.completed) {
          controller.start(
            topic: topic,
            installedPacks: packs,
            installedCards: cards,
          );
          controller.nextRound();
          if (phase == GameSessionPhase.completed) finish();
        }
        controller.exit();
        controller.exit();
        expect(getSession().snapshot, isNull);
        expect(getSession().configuration, isNull);
        expect(getSession().assignedCard, isNull);
        expect(getSession().completedRounds, 0);
        expect(getSession().retainsContent, isFalse);
        expect(controller.nextRound, throwsStateError);
        expect(controller.requestReplay, throwsStateError);
        if (phase != GameSessionPhase.home) {
          expect(getSession().phase, GameSessionPhase.exited);
          expect(() => controller.configure(configuration()), throwsStateError);
        }
        controller.returnHome();
        controller.returnHome();
        start(rounds: 10);
        expect(getSession().roundIndex, 0);
      });
    }
  });

  group('Snapshot and lifecycle isolation', () {
    test(
      'input mutations and live-provider invalidation never change play',
      () {
        start(rounds: 6);
        final active = getSession();
        final snapshot = active.snapshot!;
        expect(() => snapshot.cards.clear(), throwsUnsupportedError);
        expect(() => snapshot.packs.clear(), throwsUnsupportedError);
        expect(
          () => snapshot.configuration.packIds.clear(),
          throwsUnsupportedError,
        );
        cards
          ..clear()
          ..add(card('remote-replacement'));
        packs
          ..clear()
          ..add(
            Pack(id: 'pack', topicId: 'topic', name: 'Removed', deleted: true),
          );
        container.invalidate(contentRepositoryProvider);
        expect(getSession(), same(active));
        expect(snapshot.topic.name, 'Original Topic');
        expect(snapshot.packs.single.name, 'Original Pack');
        expect(snapshot.packs.single.published, isTrue);
        for (var index = 0; index < 6; index++) {
          expect(getSession().snapshot, same(snapshot));
          expect(snapshot.cards, contains(getSession().assignedCard));
          expect(getSession().assignedCard!.id, isNot('remote-replacement'));
          controller.nextRound();
        }
        expect(getSession().phase, GameSessionPhase.completed);
      },
    );

    test(
      'state survives route listener gaps but never a new ProviderScope',
      () {
        start();
        controller.nextRound();
        final listener = container.listen(gameSessionProvider, (_, _) {});
        listener.close();
        expect(getSession().roundIndex, 1);
        final freshContainer = ProviderContainer();
        addTearDown(freshContainer.dispose);
        expect(
          freshContainer.read(gameSessionProvider).phase,
          GameSessionPhase.home,
        );
        expect(freshContainer.read(gameSessionProvider).snapshot, isNull);
      },
    );
  });
}

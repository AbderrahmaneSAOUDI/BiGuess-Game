import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:biguess/domain/models/card.dart';
import 'package:biguess/domain/models/difficulty.dart';
import 'package:biguess/domain/use_cases/card_selection_engine.dart';

Card card(
  String id, {
  String packId = 'pack-a',
  Difficulty difficulty = Difficulty.easy,
}) => Card(
  id: id,
  packId: packId,
  name: 'Shared display name',
  imageReference: 'opaque:shared-image',
  difficulty: difficulty,
);

List<String?> drawCards(CardSelectionEngine engine, int count) =>
    List.generate(count, (_) => engine.draw());

void main() {
  group('Cumulative difficulty', () {
    final cards = [
      card('easy-a'),
      card('medium-a', difficulty: Difficulty.medium),
      card('hard-a', difficulty: Difficulty.hard),
      card('easy-b', packId: 'pack-b'),
      card('medium-b', packId: 'pack-b', difficulty: Difficulty.medium),
      card('hard-b', packId: 'pack-b', difficulty: Difficulty.hard),
    ];
    final expected = {
      Difficulty.easy: ['easy-a', 'easy-b'],
      Difficulty.medium: ['easy-a', 'easy-b', 'medium-a', 'medium-b'],
      Difficulty.hard: [
        'easy-a',
        'easy-b',
        'medium-a',
        'medium-b',
        'hard-a',
        'hard-b',
      ],
    };

    for (final difficulty in Difficulty.values) {
      test('${difficulty.name} includes every level up to the selection', () {
        final engine = CardSelectionEngine(
          cards: cards,
          difficulty: difficulty,
          random: Random(12),
        );
        final ids = expected[difficulty]!;
        for (var cycle = 0; cycle < 3; cycle++) {
          expect(drawCards(engine, ids.length), unorderedEquals(ids));
        }
      });
    }

    test('defaults to Easy', () {
      final engine = CardSelectionEngine(cards: cards, random: Random(12));
      expect(drawCards(engine, 2), unorderedEquals(expected[Difficulty.easy]!));
    });
  });

  group('Empty and singleton pools', () {
    test('empty input keeps returning null', () {
      final engine = CardSelectionEngine(cards: [], random: Random(2));
      expect(engine.eligibleCardIds, isEmpty);
      expect(drawCards(engine, 5), everyElement(isNull));
    });

    test('no eligible Cards keeps returning null', () {
      final engine = CardSelectionEngine(
        cards: [
          card('medium', difficulty: Difficulty.medium),
          card('hard', difficulty: Difficulty.hard),
        ],
        random: Random(2),
      );
      expect(engine.eligibleCardIds, isEmpty);
      expect(drawCards(engine, 5), everyElement(isNull));
    });

    test('one eligible Card can be drawn through repeated refills', () {
      final engine = CardSelectionEngine(
        cards: [
          card('only'),
          card('hard', difficulty: Difficulty.hard),
        ],
        random: Random(2),
      );
      expect(drawCards(engine, 10), everyElement('only'));
    });
  });

  test(
    'N Cards appear exactly once per cycle and reshuffle after exhaustion',
    () {
      final cards = List.generate(12, (index) => card('card-$index'));
      final engine = CardSelectionEngine(cards: cards, random: Random(42));
      final cycles = List.generate(6, (_) => drawCards(engine, cards.length));

      for (final cycle in cycles) {
        expect(cycle, unorderedEquals(cards.map((card) => card.id)));
      }
      expect(
        cycles.map((cycle) => cycle.join(',')).toSet().length,
        greaterThan(1),
      );
    },
  );

  test(
    'merges Cards from multiple Packs without partitioning the draw pool',
    () {
      final packs = [
        [card('a-1'), card('a-2')],
        [card('b-1', packId: 'pack-b'), card('b-2', packId: 'pack-b')],
        <Card>[],
      ];
      final engine = CardSelectionEngine(
        cards: packs.expand((cards) => cards),
        random: Random(42),
      );
      for (var cycle = 0; cycle < 3; cycle++) {
        expect(
          drawCards(engine, 4),
          unorderedEquals(['a-1', 'a-2', 'b-1', 'b-2']),
        );
      }
    },
  );

  test('deduplicates eligible IDs within and across Packs on every refill', () {
    final engine = CardSelectionEngine(
      cards: [
        card('shared', difficulty: Difficulty.hard),
        card('shared'),
        card('shared'),
        card('shared', packId: 'pack-b'),
        card('other', packId: 'pack-b'),
      ],
      random: Random(42),
    );
    expect(engine.eligibleCardIds, unorderedEquals(['shared', 'other']));
    for (var cycle = 0; cycle < 4; cycle++) {
      expect(drawCards(engine, 2), unorderedEquals(['shared', 'other']));
    }
  });

  test('distinct IDs sharing a name and image remain separate Cards', () {
    final engine = CardSelectionEngine(
      cards: [card('first'), card('second')],
      random: Random(42),
    );
    expect(drawCards(engine, 2), unorderedEquals(['first', 'second']));
  });

  test(
    'matching seeds reproduce draws across refills; different seeds vary',
    () {
      final cards = List.generate(10, (index) => card('card-$index'));
      final first = CardSelectionEngine(cards: cards, random: Random(7));
      final second = CardSelectionEngine(cards: cards, random: Random(7));
      final different = CardSelectionEngine(cards: cards, random: Random(71));
      final draws = drawCards(first, 40);

      expect(drawCards(second, 40), draws);
      expect(drawCards(different, 40), isNot(draws));
    },
  );

  test(
    'devices can draw the same ID and never consume another device deck',
    () {
      final cards = List.generate(5, (index) => card('card-$index'));
      final deviceA = CardSelectionEngine(cards: cards, random: Random(19));
      final deviceB = CardSelectionEngine(cards: cards, random: Random(19));
      final independent = CardSelectionEngine(cards: cards, random: Random(19));
      final expected = drawCards(independent, 20);

      expect(deviceA.draw(), expected.first);
      expect(deviceB.draw(), expected.first);
      expect(drawCards(deviceA, 19), expected.skip(1));
      expect(drawCards(deviceB, 19), expected.skip(1));
    },
  );

  test(
    'input changes cannot alter the captured IDs, even after exhaustion',
    () {
      final cards = [card('first'), card('second'), card('third')];
      final engine = CardSelectionEngine(cards: cards, random: Random(42));
      final firstDraw = engine.draw();

      cards
        ..clear()
        ..add(card('replacement'));

      expect([
        firstDraw,
        ...drawCards(engine, 2),
      ], unorderedEquals(['first', 'second', 'third']));
      expect(
        drawCards(engine, 3),
        unorderedEquals(['first', 'second', 'third']),
      );
      expect(() => engine.eligibleCardIds.clear(), throwsUnsupportedError);
    },
  );
}

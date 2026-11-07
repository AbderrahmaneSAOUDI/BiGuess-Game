import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biguess/domain/models/card.dart';
import 'package:biguess/domain/models/difficulty.dart';
import 'package:biguess/domain/models/pack.dart';
import 'package:biguess/domain/models/pack_selection.dart';
import 'package:biguess/domain/models/topic.dart';
import 'package:biguess/domain/repositories/content_repository.dart';
import 'package:biguess/domain/use_cases/select_packs_use_case.dart';
import 'package:biguess/providers/pack_selection_controller.dart';
import 'package:biguess/providers/topic_pack_providers.dart';

Card _card(String packId, String id, {Difficulty level = Difficulty.easy}) =>
    Card(
      id: id,
      packId: packId,
      name: 'Identity $id',
      imageReference: 'local/$id.webp',
      difficulty: level,
    );

class _SelectionRepository implements ContentRepository {
  bool leakOtherTopic = false;
  List<Topic> topics = [
    Topic(id: 'topic-one', name: 'Shapes', published: true),
    Topic(id: 'topic-two', name: 'Colors', published: true),
  ];
  List<Pack> packs = [
    Pack(id: 'a', topicId: 'topic-one', name: 'Same label', published: true),
    Pack(id: 'b', topicId: 'topic-one', name: 'Same label', published: true),
    Pack(id: 'remote', topicId: 'topic-one', name: 'Download', published: true),
    Pack(id: 'draft', topicId: 'topic-one', name: 'Draft'),
    Pack(id: 'small', topicId: 'topic-one', name: 'Too small', published: true),
    Pack(id: 'empty', topicId: 'topic-one', name: 'Empty', published: true),
    Pack(
      id: 'deleted',
      topicId: 'topic-one',
      name: 'Deleted',
      published: true,
      deleted: true,
    ),
    Pack(
      id: 'other',
      topicId: 'topic-two',
      name: 'Same label',
      published: true,
    ),
  ];
  final Map<String, List<Card>> installed = {
    'a': [_card('a', 'a-1'), _card('a', 'a-2', level: Difficulty.hard)],
    'b': [_card('b', 'b-1'), _card('b', 'b-2', level: Difficulty.medium)],
    'small': [_card('small', 'small-1')],
    'empty': [],
    'deleted': [_card('deleted', 'deleted-1'), _card('deleted', 'deleted-2')],
    'other': [_card('other', 'other-1'), _card('other', 'other-2')],
  };

  @override
  List<Topic> getTopics() => List.unmodifiable(topics);

  @override
  List<Pack> getPacksForTopic(String topicId) => List.unmodifiable(
    packs.where(
      (pack) =>
          pack.topicId == topicId ||
          (leakOtherTopic && topicId == 'topic-one' && pack.id == 'other'),
    ),
  );

  // Cached metadata intentionally contains Cards even for uninstalled Packs.
  @override
  List<Card> getCardsForPack(String packId) => [
    _card(packId, 'cached-$packId-1'),
    _card(packId, 'cached-$packId-2'),
  ];

  @override
  List<Card>? getInstalledCardsForPack(String packId) => installed[packId];
}

void main() {
  late _SelectionRepository repository;
  late SelectPacksUseCase select;

  setUp(() {
    repository = _SelectionRepository();
    select = SelectPacksUseCase(repository, random: Random(42));
  });

  test(
    'single resolves IDs despite duplicate labels and captures all local Cards',
    () {
      final pool = select(PackSelection(topicId: 'topic-one', packIds: ['b']));
      expect(pool.topicId, 'topic-one');
      expect(pool.packs.map((pack) => pack.id), ['b']);
      expect(pool.cards, repository.installed['b']);
      expect(pool.cards.map((card) => card.difficulty), [
        Difficulty.easy,
        Difficulty.medium,
      ]);
      expect(pool.cards.map((card) => card.id), isNot(contains('cached-b-1')));
    },
  );

  test(
    'multiple merges exactly the selected Packs, retaining all difficulties',
    () {
      final pool = select(
        PackSelection(
          topicId: 'topic-one',
          mode: PackSelectionMode.multiple,
          packIds: ['b', 'a'],
        ),
      );
      expect(pool.packs.map((pack) => pack.id), ['b', 'a']);
      expect(pool.cards, [
        ...repository.installed['b']!,
        ...repository.installed['a']!,
      ]);
      expect(pool.cards.map((card) => card.id).toSet().length, 4);
      expect(
        pool.cards.every((card) => ['a', 'b'].contains(card.packId)),
        isTrue,
      );
      expect(() => pool.cards.clear(), throwsUnsupportedError);
      expect(() => pool.packs.clear(), throwsUnsupportedError);
      repository.installed['a']!.clear();
      expect(
        pool.cards.length,
        4,
        reason: 'The selected pool must be detached.',
      );
    },
  );

  test('manual selection rejects cross-Topic, unknown and nonplayable IDs', () {
    for (final ids in [
      ['other'],
      ['a', 'other'],
      ['missing'],
      ['remote'],
      ['draft'],
      ['small'],
      ['empty'],
      ['deleted'],
    ]) {
      expect(
        () => select(
          PackSelection(
            topicId: 'topic-one',
            mode: PackSelectionMode.multiple,
            packIds: ids,
          ),
        ),
        throwsA(isA<PackSelectionException>()),
        reason: 'Rejected Pack IDs: $ids',
      );
    }
    expect(
      () => select(PackSelection(topicId: 'missing', packIds: ['a'])),
      throwsA(isA<PackSelectionException>()),
    );
  });

  test('empty single and multiple configurations cannot start', () {
    for (final mode in [PackSelectionMode.single, PackSelectionMode.multiple]) {
      expect(
        () => select(PackSelection(topicId: 'topic-one', mode: mode)),
        throwsA(isA<PackSelectionException>()),
      );
    }
  });

  test(
    'a repository returning a foreign Pack cannot bypass the Topic invariant',
    () {
      repository.leakOtherTopic = true;
      expect(
        select
            .options('topic-one')
            .singleWhere((option) => option.pack.id == 'other')
            .availability,
        PackAvailability.unavailable,
      );
      expect(
        () => select(PackSelection(topicId: 'topic-one', packIds: ['other'])),
        throwsA(isA<PackSelectionException>()),
      );
      final pool = select(
        PackSelection(
          topicId: 'topic-one',
          mode: PackSelectionMode.random,
          randomCount: 99,
        ),
      );
      expect(pool.packs.map((pack) => pack.id).toSet(), {'a', 'b'});
    },
  );

  test(
    'availability distinguishes download-required and unavailable local Packs',
    () {
      final options = {
        for (final option in select.options('topic-one'))
          option.pack.id: option.availability,
      };
      expect(options, {
        'a': PackAvailability.playable,
        'b': PackAvailability.playable,
        'remote': PackAvailability.downloadRequired,
        'draft': PackAvailability.unavailable,
        'small': PackAvailability.unavailable,
        'empty': PackAvailability.unavailable,
        'deleted': PackAvailability.unavailable,
      });
      expect(select.options('missing'), isEmpty);
    },
  );

  test(
    'invalid Card relations and duplicate IDs make a local Pack unavailable',
    () {
      repository.installed['a'] = [_card('a', 'a-1'), _card('other', 'a-2')];
      repository.installed['b'] = [
        _card('b', 'duplicate'),
        _card('b', 'duplicate'),
      ];
      expect(
        select
            .options('topic-one')
            .where((option) => ['a', 'b'].contains(option.pack.id))
            .map((option) => option.availability),
        everyElement(PackAvailability.unavailable),
      );
    },
  );

  test('duplicate Card IDs across selected Packs are rejected', () {
    repository.installed['b'] = [_card('b', 'a-1'), _card('b', 'b-2')];
    expect(
      () => select(
        PackSelection(
          topicId: 'topic-one',
          mode: PackSelectionMode.multiple,
          packIds: ['a', 'b'],
        ),
      ),
      throwsA(isA<PackSelectionException>()),
    );
  });

  test(
    'random is seeded, stays in one Topic, and samples only local playable Packs',
    () {
      final selection = PackSelection(
        topicId: 'topic-one',
        mode: PackSelectionMode.random,
        randomCount: 1,
      );
      final first = SelectPacksUseCase(repository, random: Random(27))(
        selection,
      );
      final repeated = SelectPacksUseCase(repository, random: Random(27))(
        selection,
      );
      expect(first.packs, repeated.packs);
      expect(first.packs.length, 1);
      expect(first.packs.single.topicId, 'topic-one');
      expect(['a', 'b'], contains(first.packs.single.id));
      expect(first.cards, repository.installed[first.packs.single.id]);

      final seen = <String>{};
      for (var seed = 0; seed < 30; seed++) {
        final pool = SelectPacksUseCase(repository, random: Random(seed))(
          selection,
        );
        seen.add(pool.packs.single.id);
      }
      expect(seen, {'a', 'b'});
    },
  );

  test('random count clamps to eligible Packs and never repeats a Pack', () {
    for (final count in [2, 99]) {
      final pool = select(
        PackSelection(
          topicId: 'topic-one',
          mode: PackSelectionMode.random,
          randomCount: count,
        ),
      );
      expect(pool.packs.map((pack) => pack.id).toSet(), {'a', 'b'});
      expect(pool.packs.length, 2);
      expect(pool.cards.map((card) => card.id).toSet(), {
        'a-1',
        'a-2',
        'b-1',
        'b-2',
      });
    }
  });

  test('random handles exactly one eligible Pack and no eligible Packs', () {
    repository.installed.remove('b');
    final selection = PackSelection(
      topicId: 'topic-one',
      mode: PackSelectionMode.random,
      randomCount: 4,
    );
    expect(select(selection).packs.map((pack) => pack.id), ['a']);
    repository.installed.remove('a');
    expect(() => select(selection), throwsA(isA<PackSelectionException>()));
    expect(
      () => select(
        PackSelection(topicId: 'missing', mode: PackSelectionMode.random),
      ),
      throwsA(isA<PackSelectionException>()),
    );
  });

  test('a deleted Topic cannot contribute local Packs to any mode', () {
    repository.topics[0] = Topic(
      id: 'topic-one',
      name: 'Shapes',
      published: true,
      deleted: true,
    );
    expect(
      select.options('topic-one').map((option) => option.availability),
      everyElement(PackAvailability.unavailable),
    );
    expect(
      () => select(
        PackSelection(topicId: 'topic-one', mode: PackSelectionMode.random),
      ),
      throwsA(isA<PackSelectionException>()),
    );
  });

  test(
    'serialized IDs continue to resolve after Topic and Pack labels change',
    () {
      final original = PackSelection(
        topicId: 'topic-one',
        mode: PackSelectionMode.multiple,
        packIds: ['a', 'b'],
        randomCount: 2,
      );
      final encoded = jsonEncode(original.toJson());
      final restored = PackSelection.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      repository.topics[0] = Topic(
        id: 'topic-one',
        name: 'Renamed',
        published: true,
      );
      repository.packs[0] = Pack(
        id: 'a',
        topicId: 'topic-one',
        name: 'Renamed Pack',
        published: true,
      );
      expect(encoded, isNot(contains('Shapes')));
      expect(encoded, isNot(contains('Same label')));
      expect(restored.topicId, original.topicId);
      expect(restored.mode, original.mode);
      expect(restored.packIds, original.packIds);
      expect(restored.randomCount, 2);
      expect(select(restored).packs.first.name, 'Renamed Pack');
    },
  );

  test(
    'invalid selection cardinality, IDs and serialized values are rejected',
    () {
      for (final build in <PackSelection Function()>[
        () => PackSelection(topicId: ''),
        () => PackSelection(topicId: 'topic-one', packIds: ['']),
        () => PackSelection(topicId: 'topic-one', packIds: ['a', 'b']),
        () => PackSelection(
          topicId: 'topic-one',
          mode: PackSelectionMode.multiple,
          packIds: ['a', 'a'],
        ),
        () => PackSelection(
          topicId: 'topic-one',
          mode: PackSelectionMode.random,
          packIds: ['a'],
        ),
        () => PackSelection(topicId: 'topic-one', randomCount: 0),
      ]) {
        expect(build, throwsArgumentError);
      }
      final valid = PackSelection(topicId: 'topic-one').toJson();
      for (final patch in [
        {'mode': 'unknown'},
        {
          'packIds': ['a', 7],
        },
        {'packIds': 'a'},
        {'randomCount': 1.5},
        {'randomCount': 0},
      ]) {
        expect(
          () => PackSelection.fromJson({...valid, ...patch}),
          throwsArgumentError,
        );
      }
    },
  );

  test('selection copies caller IDs and exposes immutable IDs', () {
    final ids = ['a'];
    final selection = PackSelection(topicId: 'topic-one', packIds: ids);
    ids.clear();
    expect(selection.packIds, ['a']);
    expect(() => selection.packIds.clear(), throwsUnsupportedError);
  });

  test(
    'controller prunes unavailable and missing IDs without changing another Topic',
    () {
      final container = ProviderContainer(
        overrides: [contentRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final one = container.read(packSelectionProvider('topic-one').notifier);
      final two = container.read(packSelectionProvider('topic-two').notifier);
      one.setMode(PackSelectionMode.multiple);
      one.selectPack('a');
      one.selectPack('b');
      two.selectPack('other');
      expect(container.read(packSelectionProvider('topic-one')).packIds, [
        'a',
        'b',
      ]);

      repository.installed.remove('b');
      container.invalidate(packOptionsProvider('topic-one'));
      container.read(packOptionsProvider('topic-one'));
      final remaining = container.read(packSelectionProvider('topic-one'));
      expect(remaining.mode, PackSelectionMode.multiple);
      expect(remaining.packIds, ['a']);
      expect(select(remaining).packs.map((pack) => pack.id), ['a']);
      expect(container.read(packSelectionProvider('topic-two')).packIds, [
        'other',
      ]);

      repository.packs.removeWhere((pack) => pack.id == 'a');
      container.invalidate(packOptionsProvider('topic-one'));
      container.read(packOptionsProvider('topic-one'));
      final empty = container.read(packSelectionProvider('topic-one'));
      expect(empty.packIds, isEmpty);
      expect(() => select(empty), throwsA(isA<PackSelectionException>()));
      expect(container.read(packSelectionProvider('topic-two')).packIds, [
        'other',
      ]);
    },
  );

  test(
    'controller preserves single/multiple mode rules and isolates Topics',
    () {
      final container = ProviderContainer(
        overrides: [contentRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final one = container.read(packSelectionProvider('topic-one').notifier);
      final two = container.read(packSelectionProvider('topic-two').notifier);

      one.selectPack('a');
      one.selectPack('b');
      expect(container.read(packSelectionProvider('topic-one')).packIds, ['b']);
      one.setMode(PackSelectionMode.multiple);
      one.selectPack('a');
      expect(container.read(packSelectionProvider('topic-one')).packIds, [
        'b',
        'a',
      ]);
      one.selectPack('b');
      expect(container.read(packSelectionProvider('topic-one')).packIds, ['a']);
      one.selectPack('b');
      one.setMode(PackSelectionMode.single);
      expect(container.read(packSelectionProvider('topic-one')).packIds, ['a']);

      two.selectPack('other');
      expect(
        () => one.selectPack('other'),
        throwsA(isA<PackSelectionException>()),
      );
      expect(
        () => one.selectPack('remote'),
        throwsA(isA<PackSelectionException>()),
      );
      expect(container.read(packSelectionProvider('topic-one')).packIds, ['a']);
      expect(container.read(packSelectionProvider('topic-two')).packIds, [
        'other',
      ]);
      expect(
        container.read(packSelectionProvider('topic-two')).topicId,
        'topic-two',
      );

      one.setMode(PackSelectionMode.random);
      one.setRandomCount(2);
      final randomState = container.read(packSelectionProvider('topic-one'));
      expect(randomState.packIds, isEmpty);
      expect(randomState.randomCount, 2);
      expect(() => one.selectPack('a'), throwsA(isA<PackSelectionException>()));
      expect(select(randomState).packs.map((pack) => pack.id).toSet(), {
        'a',
        'b',
      });
      expect(container.read(packSelectionProvider('topic-two')).packIds, [
        'other',
      ]);
    },
  );
}

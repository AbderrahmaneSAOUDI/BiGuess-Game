import 'dart:math';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/domain/models/card.dart';
import 'package:gdg_guess_game/domain/models/difficulty.dart';
import 'package:gdg_guess_game/domain/models/pack.dart';
import 'package:gdg_guess_game/domain/models/topic.dart';
import 'package:gdg_guess_game/domain/repositories/content_repository.dart';
import 'package:gdg_guess_game/domain/use_cases/select_packs_use_case.dart';
import 'package:gdg_guess_game/presentation/screens/game/game_configuration_screen.dart';
import 'package:gdg_guess_game/presentation/screens/game/game_screen.dart';
import 'package:gdg_guess_game/presentation/screens/packs/packs_screen.dart';
import 'package:gdg_guess_game/providers/game_controller.dart';
import 'package:gdg_guess_game/providers/pack_selection_controller.dart';
import 'package:gdg_guess_game/providers/topic_pack_providers.dart';

class _Repository implements ContentRepository {
  final bool local;
  final removed = <String>{};
  _Repository({this.local = true});

  @override
  List<Topic> getTopics() => [
    Topic(id: 'topic', name: 'Shapes', published: true),
    Topic(id: 'other', name: 'Other', published: true),
  ];

  @override
  List<Pack> getPacksForTopic(String id) => [
    if (id == 'topic') ...[
      Pack(id: 'one', topicId: id, name: 'Paper Shapes', published: true),
      Pack(id: 'two', topicId: id, name: 'More Shapes', published: true),
      Pack(id: 'remote', topicId: id, name: 'Remote Shapes', published: true),
      Pack(id: 'draft', topicId: id, name: 'Draft Shapes'),
    ] else if (id == 'other')
      Pack(id: 'foreign', topicId: id, name: 'Foreign', published: true),
  ];

  @override
  List<Card> getCardsForPack(String id) => [
    for (var i = 0; i < 2; i++)
      Card(
        id: '$id-$i',
        packId: id,
        name: '$id $i',
        imageReference: i == 0
            ? 'assets/logos/biguess-icon.webp'
            : 'assets/logos/biguess_logo.webp',
        difficulty: Difficulty.easy,
      ),
  ];

  @override
  List<Card>? getInstalledCardsForPack(String id) =>
      local && !removed.contains(id) && ['one', 'two', 'foreign'].contains(id)
      ? getCardsForPack(id)
      : null;
}

Future<_Repository> _mount(
  WidgetTester tester, {
  bool local = true,
  bool compact = false,
}) async {
  tester.view.physicalSize = compact
      ? const Size(320, 640)
      : const Size(480, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = _Repository(local: local);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        contentRepositoryProvider.overrideWithValue(repository),
        selectPacksUseCaseProvider.overrideWithValue(
          SelectPacksUseCase(repository, random: Random(4)),
        ),
      ],
      child: const MaterialApp(
        home: PacksScreen(topicName: 'Shapes', topicId: 'topic'),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  return repository;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _startAndCheck(
  WidgetTester tester,
  String label,
  List<String> packIds,
) async {
  expect(find.byType(GameConfigurationScreen), findsOneWidget);
  expect(find.text('${packIds.length * 2} eligible cards'), findsOneWidget);
  await _tap(tester, find.text('Start Game'));
  expect(find.byType(GameScreen), findsOneWidget);
  final container = ProviderScope.containerOf(
    tester.element(find.byType(GameScreen)),
  );
  final state = container.read(
    gameRoundProvider((topic: 'Shapes', pack: label)),
  );
  expect(state.configuration!.topicId, 'topic');
  expect(state.configuration!.packIds, unorderedEquals(packIds));
  expect(state.allImages, hasLength(packIds.length * 2));
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  testWidgets('returning from the game refreshes retained Pack availability', (
    tester,
  ) async {
    final repository = await _mount(tester);
    await _tap(tester, find.text('Multiple'));
    await _tap(tester, find.byKey(const ValueKey('pack-one')));
    await _tap(tester, find.byKey(const ValueKey('pack-two')));
    await _tap(tester, find.byKey(const ValueKey('packs-continue')));
    await _tap(tester, find.text('Start Game'));
    expect(find.byType(GameScreen), findsOneWidget);
    repository.removed.add('two');
    await _tap(tester, find.byTooltip('Back to Packs'));
    expect(find.text('1 packs selected in this Topic.'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('packs-continue')));
    await _startAndCheck(tester, 'Paper Shapes', ['one']);
  });

  testWidgets('Start rechecks every selected Pack after local removal', (
    tester,
  ) async {
    final repository = await _mount(tester);
    await _tap(tester, find.text('Multiple'));
    await _tap(tester, find.byKey(const ValueKey('pack-one')));
    await _tap(tester, find.byKey(const ValueKey('pack-two')));
    await _tap(tester, find.byKey(const ValueKey('packs-continue')));
    repository.removed.add('two');
    await _tap(tester, find.text('Start Game'));
    expect(find.byType(GameScreen), findsNothing);
    expect(find.byType(GameConfigurationScreen), findsOneWidget);
    expect(
      find.text('Download at least one Pack before starting.'),
      findsOneWidget,
    );
    await _tap(tester, find.byTooltip('Back'));
    expect(find.text('1 packs selected in this Topic.'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('packs-continue')));
    await _startAndCheck(tester, 'Paper Shapes', ['one']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('single mode opens setup with the selected ID', (tester) async {
    await _mount(tester);
    await _tap(tester, find.byKey(const ValueKey('pack-one')));
    await _startAndCheck(tester, 'Paper Shapes', ['one']);
  });

  testWidgets(
    'multiple mode merges complete local pools through setup and game',
    (tester) async {
      await _mount(tester);
      await _tap(tester, find.text('Multiple'));
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('packs-continue')))
            .onPressed,
        isNull,
      );
      await _tap(tester, find.byKey(const ValueKey('pack-one')));
      await _tap(tester, find.byKey(const ValueKey('pack-two')));
      await _tap(tester, find.byKey(const ValueKey('packs-continue')));
      await _startAndCheck(tester, '2 selected packs', ['one', 'two']);
    },
  );

  testWidgets('random mode only selects playable packs within the Topic', (
    tester,
  ) async {
    await _mount(tester);
    await _tap(tester, find.text('Random'));
    await _tap(tester, find.byTooltip('More random packs'));
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('random-pack-count'))).data,
      '2',
    );
    await _tap(tester, find.byKey(const ValueKey('packs-continue')));
    await _startAndCheck(tester, '2 selected packs', ['one', 'two']);
  });

  testWidgets(
    'download-required and unavailable packs stay disabled on compact screens',
    (tester) async {
      await _mount(tester, compact: true);
      for (final entry in {
        'remote': 'Download required',
        'draft': 'Unavailable',
      }.entries) {
        final card = find.byKey(ValueKey('pack-${entry.key}'));
        await tester.scrollUntilVisible(card, 150);
        await tester.pump(const Duration(seconds: 1));
        expect(
          find.descendant(of: card, matching: find.text(entry.value)),
          findsOneWidget,
        );
        await _tap(tester, card);
        expect(find.byType(GameConfigurationScreen), findsNothing);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('no local packs disables random continuation', (tester) async {
    await _mount(tester, local: false);
    await _tap(tester, find.text('Random'));
    expect(
      find.text('No locally playable packs available in this Topic.'),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('random-pack-count'))).data,
      '0',
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('packs-continue')))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}

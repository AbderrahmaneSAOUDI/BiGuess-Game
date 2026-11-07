import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biguess/domain/models/card.dart' as domain;
import 'package:biguess/domain/models/difficulty.dart';
import 'package:biguess/domain/models/entitlement.dart';
import 'package:biguess/presentation/screens/game/game_configuration_screen.dart';
import 'package:biguess/presentation/screens/game/game_screen.dart';
import 'package:biguess/presentation/screens/packs/packs_screen.dart';
import 'package:biguess/providers/entitlement_provider.dart';
import 'package:biguess/domain/models/game_session.dart';
import 'package:biguess/providers/game_session_controller.dart';
import 'package:biguess/providers/game_settings_controller.dart';
import 'package:biguess/providers/topic_pack_providers.dart';

import '../support/test_content_repository.dart';

class _SetupRepository extends TestContentRepository {
  bool installed = true;
  List<domain.Card> cards = [
    for (final level in Difficulty.values)
      domain.Card(
        id: 'c-${level.value}',
        packId: 'p-72',
        name: 'Card ${level.value}',
        imageReference: [
          'assets/logos/biguess-icon.webp',
          'assets/logos/biguess_logo.webp',
          'assets/images/Geography/Flags/Algeria.webp',
        ][level.value - 1],
        difficulty: level,
      ),
  ];

  @override
  List<domain.Card> getCardsForPack(String packId) =>
      packId == 'p-72' ? List.unmodifiable(cards) : const [];

  @override
  List<domain.Card>? getInstalledCardsForPack(String packId) =>
      installed ? getCardsForPack(packId) : null;
}

void main() {
  late ProviderContainer container;
  late _SetupRepository repository;

  Future<void> mount(WidgetTester tester, {bool packs = false}) async {
    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: packs
              ? const PacksScreen(topicName: 'Shapes')
              : const GameConfigurationScreen(
                  topicName: 'Shapes',
                  packName: 'Paper Shapes',
                ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  FilledButton startButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Start Game'),
  );

  Future<void> selectDifficulty(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButtonFormField<Difficulty>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  setUp(() {
    repository = _SetupRepository();
    container = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWithValue(repository),
        entitlementProvider.overrideWithValue(const Entitlement()),
      ],
    );
    addTearDown(container.dispose);
    container.read(countdownDurationProvider.notifier).setDuration(1);
  });

  testWidgets('Pack → setup defaults → Start → game → back to Packs', (
    tester,
  ) async {
    await mount(tester, packs: true);
    await tester.tap(find.text('Paper Shapes'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(GameConfigurationScreen), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '10',
    );
    expect(find.text('1 eligible cards'), findsOneWidget);
    expect(startButton(tester).onPressed, isNotNull);
    await tester.tap(find.text('Start Game'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.byType(GameConfigurationScreen), findsNothing);
    final active = ProviderScope.containerOf(
      tester.element(find.byType(GameScreen)),
    );
    final state = active.read(gameSessionProvider);
    expect(state.configuration!.rounds, 10);
    expect(state.configuration!.maximumDifficulty, Difficulty.easy);
    expect(state.snapshot!.cards, [repository.cards.first]);
    await tester.tap(find.byTooltip('Back to Packs'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PacksScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Free rejects invalid rounds; Pro test toggle accepts large values',
    (tester) async {
      await mount(tester);
      for (final text in ['', '0', '-1', '1.5', 'abc', '11', '1000']) {
        await tester.enterText(find.byType(TextField), text);
        await tester.pump();
        expect(startButton(tester).onPressed, isNull, reason: text);
      }
      container.updateOverrides([
        contentRepositoryProvider.overrideWithValue(repository),
        entitlementProvider.overrideWithValue(
          const Entitlement(isProTestEnabled: true),
        ),
      ]);
      await tester.pump();
      expect(startButton(tester).onPressed, isNotNull);
      await tester.ensureVisible(find.text('Start Game'));
      await tester.tap(find.text('Start Game'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final active = ProviderScope.containerOf(
        tester.element(find.byType(GameScreen)),
      );
      expect(active.read(gameSessionProvider).configuration!.rounds, 1000);
      expect(active.read(gameSessionProvider).configuration!.isPro, isTrue);
      for (var round = 0; round < 11; round++) {
        await tester.tap(find.text('Next Round'));
        await tester.pump();
      }
      expect(active.read(gameSessionProvider).roundNumber, 12);
      expect(active.read(gameSessionProvider).phase, GameSessionPhase.active);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty difficulty pool and uninstalled Pack cannot start', (
    tester,
  ) async {
    repository.cards = repository.cards.skip(1).toList();
    await mount(tester);
    expect(startButton(tester).onPressed, isNull);
    expect(find.textContaining('No cards match'), findsOneWidget);
    await selectDifficulty(tester, 'Medium');
    expect(find.text('1 eligible cards'), findsOneWidget);
    expect(startButton(tester).onPressed, isNotNull);
    await selectDifficulty(tester, 'Hard');
    expect(find.text('2 eligible cards'), findsOneWidget);
    final uninstalled = _SetupRepository()..installed = false;
    container.updateOverrides([
      contentRepositoryProvider.overrideWithValue(uninstalled),
      entitlementProvider.overrideWithValue(const Entitlement()),
    ]);
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Download at least one Pack'), findsOneWidget);
    expect(startButton(tester).onPressed, isNull);
  });

  testWidgets('setup remains usable on a compact screen with large text', (
    tester,
  ) async {
    await mount(tester);
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pump();
    await tester.ensureVisible(find.text('Start Game'));
    await tester.pump();
    expect(startButton(tester).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Start freezes settings/content and exact draw cap survives changes',
    (tester) async {
      await mount(tester, packs: true);
      await tester.tap(find.text('Paper Shapes'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await selectDifficulty(tester, 'Medium');
      await tester.enterText(find.byType(TextField), '2');
      await tester.pump();
      await tester.ensureVisible(find.text('Start Game'));
      await tester.tap(find.text('Start Game'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final active = ProviderScope.containerOf(
        tester.element(find.byType(GameScreen)),
      );
      final frozen = active.read(gameSessionProvider);
      container.read(countdownDurationProvider.notifier).setDuration(9);
      container
          .read(characterAlgorithmProvider.notifier)
          .setAlgorithm(CharacterAlgorithm.random);
      container.updateOverrides([
        contentRepositoryProvider.overrideWithValue(
          _SetupRepository()..cards = [],
        ),
        entitlementProvider.overrideWithValue(
          const Entitlement(isProTestEnabled: true),
        ),
      ]);
      await tester.pump();
      expect(
        active.read(gameSessionProvider).configuration,
        same(frozen.configuration),
      );
      expect(active.read(gameSessionProvider).snapshot, same(frozen.snapshot));
      expect(frozen.roundNumber, 1);
      expect(frozen.assignedCard, isNotNull);
      await tester.tap(find.text('Next Round'));
      await tester.pump();
      expect(active.read(gameSessionProvider).roundNumber, 2);
      expect(
        active.read(gameSessionProvider).assignedCard!.id,
        isNot(frozen.assignedCard!.id),
      );
      await tester.tap(find.text('Finish Game'));
      await tester.pump();
      expect(
        active.read(gameSessionProvider).phase,
        GameSessionPhase.completed,
      );
      expect(active.read(gameSessionProvider).completedRounds, 2);
      expect(find.text('Game complete'), findsOneWidget);
      expect(find.text('Return to Packs'), findsOneWidget);
      await tester.tap(find.text('Return to Packs'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(PacksScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

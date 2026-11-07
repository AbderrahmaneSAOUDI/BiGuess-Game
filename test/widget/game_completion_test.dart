import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biguess/domain/models/card.dart' as domain;
import 'package:biguess/domain/models/difficulty.dart';
import 'package:biguess/domain/models/entitlement.dart';
import 'package:biguess/domain/models/game_session.dart';
import 'package:biguess/presentation/screens/game/game_configuration_screen.dart';
import 'package:biguess/presentation/screens/game/game_screen.dart';
import 'package:biguess/presentation/screens/packs/packs_screen.dart';
import 'package:biguess/presentation/widgets/animations/animated_character_card.dart';
import 'package:biguess/presentation/widgets/animations/animated_countdown.dart';
import 'package:biguess/presentation/widgets/animations/animated_mystery_box.dart';
import 'package:biguess/providers/entitlement_provider.dart';
import 'package:biguess/providers/game_session_controller.dart';
import 'package:biguess/providers/game_settings_controller.dart';
import 'package:biguess/providers/topic_pack_providers.dart';

import '../support/test_content_repository.dart';

class _Repository extends TestContentRepository {
  bool installed = true;

  @override
  List<domain.Card> getCardsForPack(String packId) => [
    if (packId == 'p-72')
      for (var i = 0; i < 3; i++)
        domain.Card(
          id: 'card-$i',
          packId: packId,
          name: 'Identity $i',
          // Shared bytes prove that selection/name identity comes from Cards.
          imageReference: 'assets/logos/biguess-icon.webp',
          difficulty: Difficulty.easy,
        ),
  ];

  @override
  List<domain.Card>? getInstalledCardsForPack(String packId) =>
      installed ? getCardsForPack(packId) : null;
}

void main() {
  late ProviderContainer container;
  late _Repository repository;

  setUp(() {
    repository = _Repository();
    container = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWithValue(repository),
        entitlementProvider.overrideWithValue(const Entitlement()),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pump();
  }

  Future<void> openSetup(WidgetTester tester) async {
    await tap(tester, 'Paper Shapes');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(GameConfigurationScreen), findsOneWidget);
  }

  Future<void> start(WidgetTester tester, int rounds) async {
    await tester.enterText(find.byType(TextField), '$rounds');
    await tester.pump();
    await tap(tester, 'Start Game');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Round 1 of $rounds'), findsOneWidget);
    expect(find.byType(AnimatedCharacterCard), findsOneWidget);
    expect(find.byType(AnimatedCountdown), findsNothing);
    expect(find.byType(AnimatedMysteryBox), findsNothing);
  }

  Future<void> mount(WidgetTester tester, {bool pro = false}) async {
    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (pro) {
      container.updateOverrides([
        contentRepositoryProvider.overrideWithValue(repository),
        entitlementProvider.overrideWithValue(
          const Entitlement(isProTestEnabled: true),
        ),
      ]);
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PacksScreen(topicName: 'Shapes')),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await openSetup(tester);
  }

  Future<void> finish(WidgetTester tester, int rounds) async {
    for (var round = 1; round <= rounds; round++) {
      expect(find.text('Round $round of $rounds'), findsOneWidget);
      expect(find.text('Game complete'), findsNothing);
      expect(find.byType(AnimatedCharacterCard), findsOneWidget);
      await tap(tester, round == rounds ? 'Finish Game' : 'Next Round');
      expect(find.byType(AnimatedCountdown), findsNothing);
    }
    expect(find.text('Game complete'), findsOneWidget);
    expect(find.byType(AnimatedCharacterCard), findsNothing);
    expect(find.text('Next Round'), findsNothing);
    expect(find.text('Finish Game'), findsNothing);
    final session = container.read(gameSessionProvider);
    expect(session.phase, GameSessionPhase.completed);
    expect(session.completedRounds, rounds);
    expect(session.assignedCard, isNull);
  }

  for (final rounds in [1, 3, 10]) {
    testWidgets('Free completes $rounds rounds and resets only through Packs', (
      tester,
    ) async {
      await mount(tester);
      await start(tester, rounds);
      await finish(tester, rounds);
      expect(find.text('Replay'), findsNothing);
      expect(find.text('Return to Packs'), findsOneWidget);
      final controller = container.read(gameSessionProvider.notifier);
      final completed = container.read(gameSessionProvider);
      expect(controller.requestReplay(), GameReplayRoute.home);
      expect(container.read(gameSessionProvider), same(completed));
      expect(
        () => controller.configure(completed.configuration!),
        throwsStateError,
      );
      await tap(tester, 'Return to Packs');
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PacksScreen), findsOneWidget);
      expect(container.read(gameSessionProvider).phase, GameSessionPhase.home);
      expect(container.read(gameSessionProvider).retainsContent, isFalse);
      await openSetup(tester);
      // A new Free game gets the full ten rounds, even after playing ten.
      await start(tester, 10);
      expect(container.read(gameSessionProvider).completedRounds, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Pro test replay instantly reuses frozen settings and content', (
    tester,
  ) async {
    await mount(tester, pro: true);
    await start(tester, 11);
    final original = container.read(gameSessionProvider).snapshot!;
    await finish(tester, 11);
    expect(find.text('Replay'), findsOneWidget);
    repository.installed = false;
    container.updateOverrides([
      contentRepositoryProvider.overrideWithValue(repository),
      entitlementProvider.overrideWithValue(const Entitlement()),
    ]);
    container.read(countdownDurationProvider.notifier).setDuration(9);
    container.read(showCharacterNameHintProvider.notifier).set(true);
    await tester.pump();
    await tap(tester, 'Replay');
    expect(find.byType(GameConfigurationScreen), findsNothing);
    expect(find.text('Round 1 of 11'), findsOneWidget);
    expect(find.byType(AnimatedCharacterCard), findsOneWidget);
    final replay = container.read(gameSessionProvider);
    expect(replay.snapshot, same(original));
    expect(replay.configuration, same(original.configuration));
    expect(replay.completedRounds, 0);
    expect(container.read(showCharacterNameHintProvider), isFalse);
    await finish(tester, 11);
    await tap(tester, 'Return to Packs');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PacksScreen), findsOneWidget);
    expect(container.read(gameSessionProvider).phase, GameSessionPhase.home);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'round advance is immediate, resets hints and ignores stale taps',
    (tester) async {
      await mount(tester);
      container.read(countdownDurationProvider.notifier).setDuration(9);
      await start(tester, 3);
      final first = container.read(gameSessionProvider);
      final next = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Next Round'),
      );
      container.read(showCharacterNameHintProvider.notifier).set(true);
      next.onPressed!();
      next.onPressed!();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Round 2 of 3'), findsOneWidget);
      expect(container.read(gameSessionProvider).roundNumber, 2);
      expect(
        container.read(gameSessionProvider).assignedCard!.id,
        isNot(first.assignedCard!.id),
      );
      expect(container.read(showCharacterNameHintProvider), isFalse);
      expect(find.byType(AnimatedCountdown), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final completed in [false, true]) {
    testWidgets(
      'system Back clears ${completed ? 'completed' : 'active'} game',
      (tester) async {
        await mount(tester);
        await start(tester, 1);
        if (completed) await finish(tester, 1);
        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(PacksScreen), findsOneWidget);
        expect(
          container.read(gameSessionProvider).phase,
          GameSessionPhase.home,
        );
        expect(container.read(gameSessionProvider).snapshot, isNull);
        await openSetup(tester);
        await start(tester, 10);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('completion fits a compact screen with large text', (
    tester,
  ) async {
    await mount(tester, pro: true);
    await start(tester, 1);
    await finish(tester, 1);
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pump();
    expect(find.text('Replay'), findsOneWidget);
    expect(find.text('Return to Packs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

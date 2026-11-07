import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biguess/domain/models/card.dart' as domain;
import 'package:biguess/domain/models/difficulty.dart';
import 'package:biguess/presentation/screens/game/game_configuration_screen.dart';
import 'package:biguess/presentation/screens/game/game_screen.dart';
import 'package:biguess/presentation/widgets/animations/animated_character_card.dart';
import 'package:biguess/presentation/widgets/animations/animated_countdown.dart';
import 'package:biguess/presentation/widgets/animations/animated_mystery_box.dart';
import 'package:biguess/providers/game_session_controller.dart';
import 'package:biguess/providers/game_settings_controller.dart';
import 'package:biguess/providers/topic_pack_providers.dart';

import '../support/test_content_repository.dart';

class _Repository extends TestContentRepository {
  @override
  List<domain.Card> getCardsForPack(String packId) => [
    for (var i = 0; i < 2; i++)
      domain.Card(
        id: 'identity-$i',
        packId: 'p-72',
        name: 'Identity $i — 星',
        // Shared images must not merge distinct Cards or filename-derived names.
        imageReference: 'assets/logos/biguess-icon.webp',
        difficulty: Difficulty.easy,
      ),
  ];
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWithValue(_Repository()),
        gameSessionProvider.overrideWith(
          () => GameSessionNotifier(random: Random(4)),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> start(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(480, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: GameConfigurationScreen(
            topicName: 'Shapes',
            packName: 'Paper Shapes',
          ),
        ),
      ),
    );
    await tester.tap(find.text('Start Game'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets(
    'Start immediately displays session identity without a countdown',
    (tester) async {
      await start(tester);
      final state = container.read(gameSessionProvider);
      final card = state.assignedCard!;
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text(card.name), findsOneWidget);
      expect(find.byType(AnimatedCountdown), findsNothing);
      expect(find.byType(AnimatedMysteryBox), findsNothing);
      expect(find.text('Show Name'), findsNothing);
      expect(
        tester
            .widget<AnimatedCharacterCard>(find.byType(AnimatedCharacterCard))
            .imageAsset,
        card.imageReference,
      );

      await tester.tap(find.byType(AnimatedCharacterCard));
      await tester.tap(find.byKey(const ValueKey('identity_name')));
      await tester.pump();
      expect(container.read(gameSessionProvider), same(state));
      expect(find.text(card.name), findsOneWidget);

      // A double dispatch before a rebuild spends exactly one round.
      final advance = tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Next Round'))
          .onPressed!;
      advance();
      advance();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      final next = container.read(gameSessionProvider);
      expect(next.roundNumber, 2);
      expect(next.assignedCard!.id, isNot(card.id));
      expect(find.text(next.assignedCard!.name), findsOneWidget);
      expect(find.text(card.name), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'session settings expose appearance without legacy game controls',
    (tester) async {
      await start(tester);
      final frozen = container.read(gameSessionProvider);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Countdown Duration'), findsNothing);
      expect(find.text('Character Algorithm'), findsNothing);
      expect(find.text('Show Character Name On Reveal'), findsNothing);
      container.read(showCharacterNameHintProvider.notifier).set(false);
      expect(container.read(gameSessionProvider), same(frozen));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'orientation changes and large text retain the current identity',
    (tester) async {
      await start(tester);
      final frozen = container.read(gameSessionProvider);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final size in [const Size(320, 568), const Size(568, 320)]) {
        tester.view.physicalSize = size;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text(frozen.assignedCard!.name), findsOneWidget);
        expect(container.read(gameSessionProvider), same(frozen));
        final name = find.byKey(const ValueKey('identity_name'));
        await tester.ensureVisible(name);
        await tester.pump();
        expect(name.hitTestable(), findsOneWidget);
        final next = find.widgetWithText(FilledButton, 'Next Round');
        await tester.ensureVisible(next);
        await tester.pump();
        expect(next.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

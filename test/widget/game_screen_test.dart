import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/presentation/screens/game/game_screen.dart';
import 'package:gdg_guess_game/presentation/widgets/animations/animated_character_card.dart';
import 'package:gdg_guess_game/presentation/widgets/animations/animated_countdown.dart';
import 'package:gdg_guess_game/providers/topic_pack_providers.dart';

void main() {
  testWidgets('AnimatedCharacterCard mounts and renders without layout errors', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: AnimatedCharacterCard(
              imageAsset: 'assets/logos/biguess-icon.webp',
              characterName: 'Gon',
              showNameHint: true,
              maxWidth: 300,
              maxHeight: 400,
            ),
          ),
        ),
      ),
    );

    // Pump initial frame
    await tester.pump();
    expect(find.byType(AnimatedCharacterCard), findsOneWidget);

    // Animate shimmer and flip
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 1000));

    expect(tester.takeException(), isNull);
  });

  testWidgets('AnimatedCountdown renders and animates properly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: AnimatedCountdown(countdown: 3),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('3'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('GameScreen renders with overridden pack assets and starts countdown', (tester) async {
    const key = (topic: 'Anime', pack: 'TestPack');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          packAssetsProvider(key).overrideWithValue([
            'assets/logos/biguess-icon.webp',
          ]),
        ],
        child: const MaterialApp(
          home: GameScreen(
            topicName: 'Anime',
            packName: 'TestPack',
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('TestPack'), findsOneWidget);

    // Mystery box is visible, tap it to start countdown
    final mysteryFinder = find.byKey(const ValueKey('mystery'));
    expect(mysteryFinder, findsOneWidget);
    await tester.tap(mysteryFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify countdown starts without throwing _debugRelayoutBoundaryAlreadyMarkedNeedsLayout
    expect(tester.takeException(), isNull);
  });
}

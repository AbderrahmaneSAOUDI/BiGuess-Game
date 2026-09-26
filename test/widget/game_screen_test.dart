import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/presentation/screens/game/game_screen.dart';
import 'package:gdg_guess_game/presentation/widgets/animations/animated_character_card.dart';
import 'package:gdg_guess_game/presentation/widgets/animations/animated_countdown.dart';
import 'package:gdg_guess_game/providers/game_controller.dart';
import 'package:gdg_guess_game/providers/game_settings_controller.dart';
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

  testWidgets('AnimatedCharacterCard all-in-one toggle button toggles visibility without moving card', (tester) async {
    bool toggled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AnimatedCharacterCard(
              imageAsset: 'assets/logos/biguess-icon.webp',
              characterName: 'Killua',
              showNameHint: true,
              onToggleName: () => toggled = true,
              maxWidth: 300,
              maxHeight: 400,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Killua'), findsOneWidget);
    final toggleBtn = find.byKey(const ValueKey('toggle_name_button'));
    expect(toggleBtn, findsOneWidget);

    await tester.tap(toggleBtn);
    expect(toggled, isTrue);
  });

  testWidgets('AnimatedCharacterCard renders Show Name button when hint is hidden', (tester) async {
    bool toggled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AnimatedCharacterCard(
              imageAsset: 'assets/logos/biguess-icon.webp',
              characterName: 'Killua',
              showNameHint: false,
              onToggleName: () => toggled = true,
              maxWidth: 300,
              maxHeight: 400,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Killua'), findsNothing);
    final showBtn = find.byKey(const ValueKey('show_name_button'));
    expect(showBtn, findsOneWidget);
    expect(find.text('Show Name'), findsOneWidget);

    await tester.tap(showBtn);
    expect(toggled, isTrue);
  });

  testWidgets('AnimatedCharacterCard card does not move when toggling showNameHint', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Consumer(
                builder: (context, ref, child) {
                  final showHint = ref.watch(showCharacterNameHintProvider);
                  return AnimatedCharacterCard(
                    imageAsset: 'assets/logos/biguess-icon.webp',
                    characterName: 'Killua',
                    showNameHint: showHint,
                    onToggleName: () =>
                        ref.read(showCharacterNameHintProvider.notifier).toggle(),
                    maxWidth: 300,
                    maxHeight: 400,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final cardContainerFinder = find.byType(AnimatedCharacterCard);
    final initialTopLeft = tester.getTopLeft(cardContainerFinder);

    // Initially hidden, tap show name button to reveal name
    final showBtn = find.byKey(const ValueKey('show_name_button'));
    await tester.tap(showBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final revealedTopLeft = tester.getTopLeft(cardContainerFinder);
    expect(revealedTopLeft.dy, equals(initialTopLeft.dy));

    // Tap toggle button to hide name
    final toggleBtn = find.byKey(const ValueKey('toggle_name_button'));
    await tester.tap(toggleBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final hiddenTopLeft = tester.getTopLeft(cardContainerFinder);
    expect(hiddenTopLeft.dy, equals(initialTopLeft.dy));
  });

  test('startCountdown resets showCharacterNameHintProvider to false', () {
    const key = (topic: 'Anime', pack: 'TestPack');
    final container = ProviderContainer(
      overrides: [
        packAssetsProvider(key).overrideWithValue([
          'assets/logos/biguess-icon.webp',
        ]),
      ],
    );

    // Explicitly set name hint to true (revealed)
    container.read(showCharacterNameHintProvider.notifier).set(true);
    expect(container.read(showCharacterNameHintProvider), isTrue);

    // Trigger startCountdown (refresh)
    container.read(gameRoundProvider(key).notifier).startCountdown();

    // Verify it resets back to hidden state (false)
    expect(container.read(showCharacterNameHintProvider), isFalse);

    container.dispose();
  });
}

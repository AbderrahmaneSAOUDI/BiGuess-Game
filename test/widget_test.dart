import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/main.dart';
import 'package:gdg_guess_game/screens/categories_screen.dart';
import 'package:gdg_guess_game/screens/game_screen.dart';
import 'package:gdg_guess_game/utils/asset_loader.dart';
import 'package:gdg_guess_game/widgets/animations/animated_character_card.dart';
import 'package:gdg_guess_game/widgets/animations/animated_countdown.dart';
import 'package:gdg_guess_game/widgets/animations/animated_mystery_box.dart';
import 'package:gdg_guess_game/widgets/animations/animated_particle_burst.dart';
import 'package:gdg_guess_game/widgets/animations/interactive_scale_card.dart';

void main() {
  group('AssetLoader Unit Tests', () {
    test('extractCharacterName correctly parses filenames without extension', () {
      expect(
        AssetLoader.extractCharacterName('assets/images/naruto/Itachi UCHIHA.webp'),
        'Itachi UCHIHA',
      );
      expect(
        AssetLoader.extractCharacterName('assets/images/one_piece/Monkey D. Luffy.png'),
        'Monkey D. Luffy',
      );
      expect(
        AssetLoader.extractCharacterName('assets/images/attack_on_titan/Levi ACKERMAN.jpg'),
        'Levi ACKERMAN',
      );
      expect(
        AssetLoader.extractCharacterName(''),
        null,
      );
    });
  });

  group('Riverpod Providers Unit Tests', () {
    test('ThemeNotifier toggles themeMode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeNotifierProvider), ThemeMode.dark);
      container.read(themeNotifierProvider.notifier).toggleTheme();
      expect(container.read(themeNotifierProvider), ThemeMode.light);
      container.read(themeNotifierProvider.notifier).toggleTheme();
      expect(container.read(themeNotifierProvider), ThemeMode.dark);
    });

    test('CharacterAlgorithmNotifier updates algorithm', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(characterAlgorithmProvider),
        CharacterAlgorithm.nonRepeating,
      );
      container
          .read(characterAlgorithmProvider.notifier)
          .setAlgorithm(CharacterAlgorithm.random);
      expect(
        container.read(characterAlgorithmProvider),
        CharacterAlgorithm.random,
      );
    });

    test('CountdownDurationNotifier updates countdown', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(countdownDurationProvider), 2);
      container.read(countdownDurationProvider.notifier).setDuration(5);
      expect(container.read(countdownDurationProvider), 5);
    });

    test('ShowCharacterNameHintNotifier toggles hint', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(showCharacterNameHintProvider), true);
      container.read(showCharacterNameHintProvider.notifier).toggle();
      expect(container.read(showCharacterNameHintProvider), false);
      container.read(showCharacterNameHintProvider.notifier).set(true);
      expect(container.read(showCharacterNameHintProvider), true);
    });
  });

  group('BiGuess Game Animations Widget Tests', () {
    testWidgets('AnimatedCountdown renders count number and ready text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCountdown(countdown: 3),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('3'), findsOneWidget);
      expect(find.text('GET READY...'), findsOneWidget);
    });

    testWidgets('AnimatedMysteryBox renders with prompt and icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedMysteryBox(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Click Start to Reveal'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
    });

    testWidgets('AnimatedParticleBurst renders child properly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedParticleBurst(
              child: Text('Particle Test'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Particle Test'), findsOneWidget);
    });

    testWidgets('InteractiveScaleCard responds to tap', (
      WidgetTester tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveScaleCard(
              onTap: () => tapped = true,
              child: const Text('Scale Card'),
            ),
          ),
        ),
      );

      expect(find.text('Scale Card'), findsOneWidget);
      await tester.tap(find.text('Scale Card'));
      expect(tapped, isTrue);
    });

    testWidgets('AnimatedCharacterCard renders character name and badge', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCharacterCard(
              imageAsset: 'assets/images/naruto/Naruto UZUMAKI.webp',
              characterName: 'Naruto UZUMAKI',
              showNameHint: true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Naruto UZUMAKI'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    });
  });

  group('BiGuess Game Integration Widget Tests', () {
    testWidgets('App renders CategoriesScreen with GDG title and initial categories', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: BiGuessApp()));
      await tester.pumpAndSettle();

      expect(find.text('GDG Ghardaia'), findsOneWidget);
      expect(find.text('Attack on Titan'), findsOneWidget);
      expect(find.text('Black Clover'), findsOneWidget);
    });

    testWidgets('Theme toggling switches light/dark mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: BiGuessApp()));
      await tester.pumpAndSettle();

      final themeButton = find.byType(IconButton).last;
      expect(themeButton, findsOneWidget);

      await tester.tap(themeButton);
      await tester.pumpAndSettle();

      expect(find.byType(CategoriesScreen), findsOneWidget);
    });

    testWidgets('Settings button opens GameInfoDialog on Settings tab', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: BiGuessApp()));
      await tester.pumpAndSettle();

      final settingsButton = find.byIcon(Icons.settings_rounded);
      expect(settingsButton, findsOneWidget);

      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      expect(find.byType(GameInfoDialog), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Character Algorithm'), findsOneWidget);
      expect(find.text('Countdown Duration'), findsOneWidget);
    });

    testWidgets('Info dialog opens and shows How to Play, About Game, and Developers tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: BiGuessApp()));
      await tester.pumpAndSettle();

      final infoButton = find.byIcon(Icons.info_outline_rounded);
      expect(infoButton, findsOneWidget);

      await tester.tap(infoButton);
      await tester.pumpAndSettle();

      expect(find.byType(GameInfoDialog), findsOneWidget);
      expect(find.text('How to Play'), findsOneWidget);
      expect(find.text('About Game'), findsOneWidget);
      expect(find.text('Developers'), findsOneWidget);
    });

    testWidgets('Tapping a category navigates to GameScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: BiGuessApp()));
      await tester.pumpAndSettle();

      final categoryCard = find.text('Attack on Titan');
      expect(categoryCard, findsOneWidget);

      await tester.tap(categoryCard);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('Attack on Titan'), findsWidgets);
    });
  });
}

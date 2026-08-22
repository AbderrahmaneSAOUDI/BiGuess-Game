import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/main.dart';
import 'package:gdg_guess_game/screens/categories_screen.dart';
import 'package:gdg_guess_game/screens/game_screen.dart';
import 'package:gdg_guess_game/utils/asset_loader.dart';

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

  group('BiGuess Game Widget Tests', () {
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

      final settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget);

      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      expect(find.byType(GameInfoDialog), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Character Algorithm'), findsOneWidget);
      expect(find.text('Countdown Timer Duration'), findsOneWidget);
    });

    testWidgets('Info dialog opens and shows How to Play, About Game, and Developers tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: BiGuessApp()));
      await tester.pumpAndSettle();

      final infoButton = find.byIcon(Icons.info_outline);
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


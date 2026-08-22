import 'package:flutter/material.dart';
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

  group('BiGuess Game Widget Tests', () {
    testWidgets('App renders CategoriesScreen with GDG title and initial categories', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const BiGuessApp());
      await tester.pumpAndSettle();

      expect(find.text('GDG Ghardaia'), findsOneWidget);
      expect(find.text('Attack on Titan'), findsOneWidget);
      expect(find.text('Black Clover'), findsOneWidget);
    });

    testWidgets('Theme toggling switches light/dark mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const BiGuessApp());
      await tester.pumpAndSettle();

      final themeButton = find.byType(IconButton).last;
      expect(themeButton, findsOneWidget);

      await tester.tap(themeButton);
      await tester.pumpAndSettle();

      expect(find.byType(CategoriesScreen), findsOneWidget);
    });

    testWidgets('Info dialog opens and shows game rules & developer tabs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const BiGuessApp());
      await tester.pumpAndSettle();

      final infoButton = find.byIcon(Icons.info_outline);
      expect(infoButton, findsOneWidget);

      await tester.tap(infoButton);
      await tester.pumpAndSettle();

      expect(find.byType(RulesContactDialog), findsOneWidget);
      expect(find.text('About the game'), findsOneWidget);
      expect(find.text('About the developers'), findsOneWidget);
      expect(find.text('What is BiGuess Game?'), findsOneWidget);
    });

    testWidgets('Tapping a category navigates to GameScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const BiGuessApp());
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

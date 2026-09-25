import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/main.dart';

void main() {
  testWidgets('BiGuessApp smoke test renders topics screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BiGuessApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BiGuess'), findsWidgets);
    expect(find.text('Anime'), findsOneWidget);
    expect(find.text('Geography'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/main.dart';

void main() {
  testWidgets('BiGuessApp smoke test renders home page', (WidgetTester tester) async {
    await tester.pumpWidget(const BiGuessApp());

    expect(find.text('BiGuess'), findsWidgets);
    expect(find.text('Clean Slate - Ready to start from scratch'), findsOneWidget);
  });
}

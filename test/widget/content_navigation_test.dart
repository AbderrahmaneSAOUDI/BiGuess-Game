import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/domain/repositories/content_repository.dart';
import 'package:gdg_guess_game/main.dart';
import 'package:gdg_guess_game/presentation/controllers/update_controller.dart';
import 'package:gdg_guess_game/presentation/screens/game/game_screen.dart';
import 'package:gdg_guess_game/presentation/screens/game/game_configuration_screen.dart';
import 'package:gdg_guess_game/domain/models/difficulty.dart';
import 'package:gdg_guess_game/presentation/screens/packs/packs_screen.dart';
import 'package:gdg_guess_game/presentation/widgets/animations/animated_character_card.dart';
import 'package:gdg_guess_game/providers/game_settings_controller.dart';
import 'package:gdg_guess_game/providers/topic_pack_providers.dart';
import 'package:gdg_guess_game/services/ota_installer_service.dart';
import 'package:gdg_guess_game/services/shorebird_patch_service.dart';
import 'package:gdg_guess_game/services/version_service.dart';

import '../support/test_content_repository.dart';

/// Keep content navigation tests independent of update services and the network.
class _NoUpdates extends UpdateController {
  _NoUpdates()
    : super(
        versionService: const VersionService(),
        otaInstaller: OtaInstallerService(),
        shorebirdPatch: ShorebirdPatchService(),
      );

  @override
  Future<void> checkForUpdates({bool silent = false}) async {}
}

class _OneSecondCountdown extends CountdownDurationNotifier {
  @override
  int build() => 1;
}

Future<void> mountApp(
  WidgetTester tester, {
  ContentRepository? repository,
}) async {
  tester.view.physicalSize = const Size(480, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        updateControllerProvider.overrideWith((ref) => _NoUpdates()),
        if (repository != null)
          contentRepositoryProvider.overrideWithValue(repository),
        countdownDurationProvider.overrideWith(_OneSecondCountdown.new),
      ],
      child: const BiGuessApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

Future<void> navigateToText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  testWidgets(
    'both bundled topics navigate through all seven packs to gameplay',
    (tester) async {
      await mountApp(tester);
      for (final entry in {
        'Anime': [
          'Attack on Titan',
          'Black Clover',
          'Demon Slayer',
          'Hunter X Hunter',
          'Naruto',
          'One Piece',
        ],
        'Geography': ['Flags'],
      }.entries) {
        await navigateToText(tester, entry.key);
        expect(find.byType(PacksScreen), findsOneWidget);
        for (final pack in entry.value) {
          await navigateToText(tester, pack);
          expect(find.byType(GameConfigurationScreen), findsOneWidget);
          await tester.tap(find.text('Start Game'));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(find.byType(GameScreen), findsOneWidget);
          expect(find.byKey(const ValueKey('mystery')), findsOneWidget);
          expect(find.text(pack), findsOneWidget);
          await tester.tap(find.byTooltip('Back to Packs'));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
        }
        await tester.tap(find.byTooltip('Back to Topics'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'repository swap drives existing screens, empty state and reveal',
    (tester) async {
      final repository = TestContentRepository();
      await mountApp(tester, repository: repository);
      expect(find.text('Anime'), findsNothing);
      expect(find.text('Shapes'), findsOneWidget);
      expect(find.text('2 packs'), findsOneWidget);
      expect(find.text('2 items'), findsOneWidget);
      await navigateToText(tester, 'Shapes');
      expect(find.text('Paper Shapes'), findsOneWidget);
      expect(find.text('Unavailable'), findsOneWidget);
      // Empty drafts retain the disabled navigation behavior.
      await tester.tap(find.text('Empty Draft'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(PacksScreen), findsOneWidget);
      expect(find.byType(GameScreen), findsNothing);
      await navigateToText(tester, 'Paper Shapes');
      // This replacement repository has Medium/Hard Cards and no Easy Cards.
      await tester.tap(find.byType(DropdownButtonFormField<Difficulty>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hard').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start Game'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const ValueKey('mystery')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      final displayed = tester.widget<AnimatedCharacterCard>(
        find.byType(AnimatedCharacterCard),
      );
      expect(
        repository.getCardsForPack('p-72').map((card) => card.imageReference),
        contains(displayed.imageAsset),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

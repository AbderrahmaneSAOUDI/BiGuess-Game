import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/domain/models/card.dart' as domain;
import 'package:gdg_guess_game/domain/models/pack.dart';
import 'package:gdg_guess_game/domain/models/topic.dart';
import 'package:gdg_guess_game/domain/repositories/content_repository.dart';
import 'package:gdg_guess_game/main.dart';
import 'package:gdg_guess_game/presentation/controllers/update_controller.dart';
import 'package:gdg_guess_game/presentation/screens/game/game_screen.dart';
import 'package:gdg_guess_game/presentation/screens/game/game_configuration_screen.dart';
import 'package:gdg_guess_game/domain/models/difficulty.dart';
import 'package:gdg_guess_game/presentation/screens/packs/packs_screen.dart';
import 'package:gdg_guess_game/presentation/widgets/animations/animated_character_card.dart';
import 'package:gdg_guess_game/providers/game_settings_controller.dart';
import 'package:gdg_guess_game/providers/game_session_controller.dart';
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

class _RepeatedLabelsRepository implements ContentRepository {
  bool renamed = false;

  @override
  List<Topic> getTopics() => [
    Topic(id: 'first-topic', name: 'Same Topic'),
    Topic(id: 'second-topic', name: renamed ? 'Renamed Topic' : 'Same Topic'),
  ];

  @override
  List<Pack> getPacksForTopic(String topicId) => [
    for (final id
        in topicId == 'first-topic'
            ? ['first-pack']
            : ['second-one', 'second-two'])
      Pack(id: id, topicId: topicId, name: 'Same Pack'),
  ];

  @override
  List<domain.Card> getCardsForPack(String packId) => [
    for (var index = 0; index < (packId == 'second-two' ? 3 : 2); index++)
      domain.Card(
        id: '$packId-$index',
        packId: packId,
        name: '$packId identity $index',
        imageReference: 'assets/logos/biguess-icon.webp',
        difficulty: Difficulty.easy,
      ),
  ];

  @override
  List<domain.Card>? getInstalledCardsForPack(String packId) =>
      getCardsForPack(packId);
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
  testWidgets('duplicate labels retain their own counts and selected IDs', (
    tester,
  ) async {
    final repository = _RepeatedLabelsRepository();
    await mountApp(tester, repository: repository);
    final first = find.byKey(const ValueKey('topic-first-topic'));
    final second = find.byKey(const ValueKey('topic-second-topic'));
    expect(
      find.descendant(of: first, matching: find.text('2 items')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: second, matching: find.text('2 packs')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: second, matching: find.text('5 items')),
      findsOneWidget,
    );
    await tester.tap(second);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.widget<PacksScreen>(find.byType(PacksScreen)).topicId,
      'second-topic',
    );
    // A retained route label can become stale; the selected IDs still drive Start.
    repository.renamed = true;
    await tester.tap(find.byKey(const ValueKey('pack-second-two')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('3 eligible cards'), findsOneWidget);
    await tester.tap(find.text('Start Game'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameScreen)),
    );
    final session = container.read(gameSessionProvider);
    expect(session.configuration!.topicId, 'second-topic');
    expect(session.configuration!.packIds, ['second-two']);
    expect(session.snapshot!.topic.name, 'Renamed Topic');
    expect(session.snapshot!.cards.map((card) => card.packId).toSet(), {
      'second-two',
    });
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

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
          expect(find.byType(AnimatedCharacterCard), findsOneWidget);
          expect(find.text('Round 1 of 10'), findsOneWidget);
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/domain/models/remote_version.dart';
import 'package:gdg_guess_game/domain/models/sem_ver.dart';
import 'package:gdg_guess_game/domain/models/update_decision.dart';
import 'package:gdg_guess_game/main.dart';
import 'package:gdg_guess_game/presentation/widgets/common/glass_icon_button.dart';
import 'package:gdg_guess_game/providers/game_providers.dart';
import 'package:gdg_guess_game/screens/categories_screen.dart';
import 'package:gdg_guess_game/screens/game_screen.dart';
import 'package:gdg_guess_game/services/version_service.dart';
import 'package:gdg_guess_game/utils/asset_loader.dart';
import 'package:gdg_guess_game/widgets/animations/animated_character_card.dart';
import 'package:gdg_guess_game/widgets/animations/animated_countdown.dart';
import 'package:gdg_guess_game/widgets/animations/animated_glass_app_bar_background.dart';
import 'package:gdg_guess_game/widgets/animations/animated_mystery_box.dart';
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

    test('appVersionProvider returns a valid version string', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final version = await container.read(appVersionProvider.future);
      expect(version, isNotEmpty);
    });
  });

  group('SemVer & VersionService Unit Tests', () {
    test('SemVer parses standard versions and build numbers', () {
      final v1 = SemVer.parse('0.30.2');
      expect(v1.major, 0);
      expect(v1.minor, 30);
      expect(v1.patch, 2);
      expect(v1.buildNumber, 0);

      final v2 = SemVer.parse('1.2.3+15');
      expect(v2.major, 1);
      expect(v2.minor, 2);
      expect(v2.patch, 3);
      expect(v2.buildNumber, 15);

      final v3 = SemVer.parse('v2.0.0', 5);
      expect(v3.major, 2);
      expect(v3.minor, 0);
      expect(v3.patch, 0);
      expect(v3.buildNumber, 5);
    });

    test('SemVer comparisons work accurately', () {
      final local = SemVer.parse('0.30.2');
      final same = SemVer.parse('0.30.2');
      final newerPatch = SemVer.parse('0.30.3');
      final newerMinor = SemVer.parse('0.31.0');
      final older = SemVer.parse('0.30.1');

      expect(local == same, isTrue);
      expect(local >= same, isTrue);
      expect(local < newerPatch, isTrue);
      expect(local < newerMinor, isTrue);
      expect(local > older, isTrue);
    });

    test('VersionService returns UpdateNone when local matches remote with native changes', () {
      const service = VersionService();
      final local = SemVer.parse('0.30.5+6');
      final remote = RemoteVersion.fromJson({
        'latest_version': '0.30.5',
        'build_number': 6,
        'min_required_version': '0.30.0',
        'has_native_changes': true,
        'apk_url': 'https://example.com/app.apk',
        'release_notes': 'Notes',
      });

      final decision = service.evaluateUpdate(local, remote);
      expect(decision, isA<UpdateNone>());
    });

    test('VersionService returns UpdateShorebirdPatch when local matches remote without native changes', () {
      const service = VersionService();
      final local = SemVer.parse('0.30.5+6');
      final remote = RemoteVersion.fromJson({
        'latest_version': '0.30.5',
        'build_number': 6,
        'min_required_version': '0.30.0',
        'has_native_changes': false,
        'apk_url': 'https://example.com/app.apk',
        'release_notes': 'Notes',
      });

      final decision = service.evaluateUpdate(local, remote);
      expect(decision, isA<UpdateShorebirdPatch>());
    });

    test('VersionService returns UpdateFullApk when remote has newer native build number', () {
      const service = VersionService();
      final local = SemVer.parse('0.30.5+6');
      final remote = RemoteVersion.fromJson({
        'latest_version': '0.30.5',
        'build_number': 7,
        'min_required_version': '0.30.0',
        'has_native_changes': true,
        'apk_url': 'https://example.com/app.apk',
        'release_notes': 'Native hotfix',
      });

      final decision = service.evaluateUpdate(local, remote);
      expect(decision, isA<UpdateFullApk>());
    });

    test('VersionService returns UpdateFullApk when remote has newer minor or native changes', () {
      const service = VersionService();
      final local = SemVer.parse('0.30.0');
      final remote = RemoteVersion.fromJson({
        'latest_version': '0.30.2',
        'build_number': 5,
        'min_required_version': '0.30.1',
        'has_native_changes': true,
        'apk_urls': {
          'arm64-v8a': 'https://example.com/arm64.apk',
        },
        'apk_url': 'https://example.com/default.apk',
        'release_notes': 'Native update',
      });

      final decision = service.evaluateUpdate(
        local,
        remote,
        deviceAbis: ['arm64-v8a'],
      );

      expect(decision, isA<UpdateFullApk>());
      final fullApk = decision as UpdateFullApk;
      expect(fullApk.mandatory, isTrue); // local 0.30.0 < min 0.30.1
      expect(fullApk.apkUrl, 'https://example.com/arm64.apk');
    });

    test('VersionService returns UpdateShorebirdPatch for patch bump without native changes', () {
      const service = VersionService();
      final local = SemVer.parse('0.30.0');
      final remote = RemoteVersion.fromJson({
        'latest_version': '0.30.1',
        'build_number': 2,
        'min_required_version': '0.28.0',
        'has_native_changes': false,
        'apk_url': 'https://example.com/app.apk',
        'release_notes': 'Patch update',
      });

      final decision = service.evaluateUpdate(local, remote);
      expect(decision, isA<UpdateShorebirdPatch>());
    });
  });

  group('BiGuess Game Animations Widget Tests', () {
    testWidgets('AnimatedCountdown renders count number', (
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

      expect(find.text('Tap to Reveal'), findsOneWidget);
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);
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

    testWidgets('AnimatedCharacterCard renders character name without icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCharacterCard(
              imageAsset: 'assets/images/naruto/Naruto UZUMAKI.webp',
              characterName: 'Naruto UZUMAKI',
              showNameHint: true,
              cardSize: 320.0,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Naruto UZUMAKI'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);

      final textWidget = tester.widget<Text>(find.text('Naruto UZUMAKI'));
      expect(textWidget.style?.fontSize, 22.0);
    });

    testWidgets('AnimatedGlassAppBarBackground renders with backdrop filter and glass decor', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 80,
              child: AnimatedGlassAppBarBackground(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AnimatedGlassAppBarBackground), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('GlassIconButton renders and triggers onPressed callback on tap', (
      WidgetTester tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassIconButton.icon(
              iconData: Icons.star_rounded,
              tooltip: 'Star',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byType(GlassIconButton), findsOneWidget);

      await tester.tap(find.byType(GlassIconButton));
      expect(tapped, isTrue);
    });
  });

  group('BiGuess Game Integration Widget Tests', () {
    testWidgets('App renders CategoriesScreen with BiGuess title and initial categories', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: BiGuessApp(home: CategoriesScreen())));
      await tester.pumpAndSettle();

      expect(find.text('BiGuess'), findsOneWidget);
      expect(find.text('Attack on Titan'), findsOneWidget);
      expect(find.text('Black Clover'), findsOneWidget);
    });

    testWidgets('Theme toggling switches light/dark mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: BiGuessApp(home: CategoriesScreen())));
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
      await tester.pumpWidget(const ProviderScope(child: BiGuessApp(home: CategoriesScreen())));
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
      await tester.pumpWidget(const ProviderScope(child: BiGuessApp(home: CategoriesScreen())));
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
      await tester.pumpWidget(const ProviderScope(child: BiGuessApp(home: CategoriesScreen())));
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

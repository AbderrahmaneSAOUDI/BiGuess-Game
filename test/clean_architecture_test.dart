import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/core/constants/app_constants.dart';
import 'package:gdg_guess_game/core/theme/app_colors.dart';
import 'package:gdg_guess_game/core/theme/app_theme.dart';
import 'package:gdg_guess_game/data/datasources/asset_manifest_data_source.dart';
import 'package:gdg_guess_game/data/repositories/category_repository_impl.dart';
import 'package:gdg_guess_game/domain/models/category.dart';
import 'package:gdg_guess_game/domain/models/character_algorithm.dart';
import 'package:gdg_guess_game/domain/models/developer_info.dart';
import 'package:gdg_guess_game/domain/models/game_state.dart';
import 'package:gdg_guess_game/domain/use_cases/select_character_use_case.dart';
import 'package:gdg_guess_game/presentation/controllers/game_controller.dart';
import 'package:gdg_guess_game/presentation/dialogs/info/tabs/about_game_tab.dart';
import 'package:gdg_guess_game/presentation/dialogs/info/tabs/developers_tab.dart';
import 'package:gdg_guess_game/presentation/dialogs/info/tabs/how_to_play_tab.dart';
import 'package:gdg_guess_game/presentation/dialogs/info/tabs/settings_tab.dart';
import 'package:gdg_guess_game/presentation/dialogs/info/widgets/developer_card.dart';
import 'package:gdg_guess_game/presentation/dialogs/info/widgets/info_dialog_header.dart';
import 'package:gdg_guess_game/presentation/screens/game/widgets/game_app_bar.dart';
import 'package:gdg_guess_game/presentation/screens/game/widgets/game_empty_state.dart';

void main() {
  group('Domain Entities & Models', () {
    test('GameCategory map conversion & equality', () {
      const cat = GameCategory(
        name: 'Naruto',
        path: 'assets/images/naruto',
        logoPath: 'assets/logos/Naruto Uzumaki.webp',
      );

      final map = cat.toMap();
      expect(map['name'], 'Naruto');
      expect(map['path'], 'assets/images/naruto');
      expect(map['logo_path'], 'assets/logos/Naruto Uzumaki.webp');

      final fromMapCat = GameCategory.fromMap(map);
      expect(fromMapCat, equals(cat));
      expect(fromMapCat.hashCode, equals(cat.hashCode));
    });

    test('GameRoundState copyWith handles state modifications', () {
      const state = GameRoundState();
      expect(state.isLoading, isTrue);
      expect(state.isCountingDown, isFalse);
      expect(state.countdown, 0);

      final updated = state.copyWith(
        isLoading: false,
        isCountingDown: true,
        countdown: 3,
        currentImageAsset: 'assets/images/naruto/Sasuke.webp',
        correctAnswer: 'Sasuke',
      );

      expect(updated.isLoading, isFalse);
      expect(updated.isCountingDown, isTrue);
      expect(updated.countdown, 3);
      expect(updated.currentImageAsset, 'assets/images/naruto/Sasuke.webp');
      expect(updated.correctAnswer, 'Sasuke');

      final cleared = updated.copyWith(
        clearCurrentAsset: true,
        clearCorrectAnswer: true,
      );
      expect(cleared.currentImageAsset, isNull);
      expect(cleared.correctAnswer, isNull);
    });

    test('DeveloperProfile & DeveloperLink model instantiation', () {
      const link = DeveloperLink(
        label: 'GitHub',
        icon: Icons.code,
        url: 'https://github.com',
      );
      const dev = DeveloperProfile(
        name: 'Test Dev',
        role: 'Maintainer',
        bio: 'Dev bio',
        accentColor: Colors.blue,
        links: [link],
      );

      expect(dev.name, 'Test Dev');
      expect(dev.links.length, 1);
      expect(dev.links.first.url, 'https://github.com');
    });
  });

  group('Data Layer & Repositories', () {
    test('CategoryRepositoryImpl returns configured categories', () {
      const repo = CategoryRepositoryImpl();
      final categories = repo.getCategories();

      expect(categories, isNotEmpty);
      expect(categories.length, AppConstants.categories.length);
      expect(categories.any((c) => c.name == 'Naruto'), isTrue);
    });

    test('CategoryRepositoryImpl extracts character names correctly', () {
      const repo = CategoryRepositoryImpl();
      expect(
        repo.extractCharacterName('assets/images/naruto/Kakashi HATAKE.webp'),
        'Kakashi HATAKE',
      );
      expect(
        repo.extractCharacterName('assets/images/attack_on_titan/Eren YAEGER.png'),
        'Eren YAEGER',
      );
      expect(repo.extractCharacterName(''), isNull);
    });

    test('AssetManifestDataSource returns assets for known category', () {
      const dataSource = AssetManifestDataSource();
      final aotAssets = dataSource.getAssetsForCategory('Attack on Titan');
      expect(aotAssets, isNotEmpty);
    });
  });

  group('Use Cases - SelectCharacterUseCase', () {
    const repo = CategoryRepositoryImpl();

    test('Returns empty result when image pool is empty', () {
      final useCase = SelectCharacterUseCase(repository: repo);
      final result = useCase(
        allImages: [],
        remainingImages: [],
        algorithm: CharacterAlgorithm.random,
      );

      expect(result.hasImages, isFalse);
      expect(result.assetPath, isNull);
      expect(result.characterName, isNull);
    });

    test('Random algorithm selects from all images', () {
      final deterministicRandom = Random(42);
      final useCase = SelectCharacterUseCase(
        repository: repo,
        random: deterministicRandom,
      );

      final images = [
        'assets/images/naruto/Naruto.webp',
        'assets/images/naruto/Sasuke.webp',
        'assets/images/naruto/Sakura.webp',
      ];

      final result = useCase(
        allImages: images,
        remainingImages: [],
        algorithm: CharacterAlgorithm.random,
      );

      expect(result.hasImages, isTrue);
      expect(images.contains(result.assetPath), isTrue);
      expect(result.characterName, isNotNull);
    });

    test('Non-repeating algorithm rotates through all images without repeat', () {
      final deterministicRandom = Random(0);
      final useCase = SelectCharacterUseCase(
        repository: repo,
        random: deterministicRandom,
      );

      final images = [
        'assets/images/test/Char1.webp',
        'assets/images/test/Char2.webp',
        'assets/images/test/Char3.webp',
      ];

      List<String> pool = List<String>.from(images);
      final selectedNames = <String>[];

      for (int i = 0; i < images.length; i++) {
        final res = useCase(
          allImages: images,
          remainingImages: pool,
          algorithm: CharacterAlgorithm.nonRepeating,
        );
        expect(res.hasImages, isTrue);
        expect(selectedNames.contains(res.characterName!), isFalse);
        selectedNames.add(res.characterName!);
        pool = res.updatedRemainingImages;
      }

      expect(selectedNames.length, 3);
      expect(pool.isEmpty, isTrue);

      // When pool is exhausted, next call recycles pool automatically
      final recycleRes = useCase(
        allImages: images,
        remainingImages: pool,
        algorithm: CharacterAlgorithm.nonRepeating,
      );
      expect(recycleRes.hasImages, isTrue);
      expect(recycleRes.updatedRemainingImages.length, 2);
    });
  });

  group('Presentation Layer - Theme & AppConstants', () {
    test('AppTheme builds valid light and dark ThemeData with GoogleSans font', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.textTheme.bodyMedium?.fontFamily, 'GoogleSans');
    });

    test('AppColors defines semantic countdown palette', () {
      expect(AppColors.countdownCritical, const Color(0xFFFF3366));
      expect(AppColors.countdownWarning, const Color(0xFFFF9900));
      expect(AppColors.countdownAlert, const Color(0xFFFFD700));
    });
  });

  group('Presentation Layer - Isolated Component Widget Tests', () {
    testWidgets('InfoDialogHeader displays title and triggers close callback', (
      WidgetTester tester,
    ) async {
      bool closed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfoDialogHeader(onClose: () => closed = true),
          ),
        ),
      );

      expect(find.text('BiGuess Game'), findsOneWidget);
      expect(find.text('Game Center & Rules'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(closed, isTrue);
    });

    testWidgets('GameAppBar displays category title and action buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              appBar: GameAppBar(categoryName: 'Demon Slayer'),
            ),
          ),
        ),
      );

      expect(find.text('Demon Slayer'), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    testWidgets('GameEmptyState displays fallback coming soon text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameEmptyState(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Coming soon'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('SettingsTab renders in isolation with radio options and chip buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SettingsTab(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Character Algorithm'), findsOneWidget);
      expect(find.text('Non-Repeating (Fair Rotation)'), findsOneWidget);
      expect(find.text('Countdown Duration'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Reset All Settings to Default'), findsOneWidget);
    });

    testWidgets('HowToPlayTab renders in isolation with steps and example bubbles', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HowToPlayTab(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Step-by-Step Gameplay'), findsOneWidget);
      expect(find.text('Pick a Category & Tap Start'), findsOneWidget);
      expect(find.text('Example Question Exchange'), findsOneWidget);
    });

    testWidgets('AboutGameTab renders branding, badges, and offline features', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AboutGameTab(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BiGuess Game'), findsOneWidget);
      expect(find.text('18+'), findsOneWidget);
      expect(find.text('300+'), findsOneWidget);
      expect(find.text('2P'), findsOneWidget);
      expect(find.text('100% Offline'), findsOneWidget);
    });

    testWidgets('DevelopersTab renders developer profile cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DevelopersTab(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Abderrahmane SAOUDI'), findsOneWidget);
      expect(find.text('Anas Oussama DJRIBIE'), findsOneWidget);
      expect(find.text('Lead Developer & UI/UX Designer'), findsOneWidget);
    });

    testWidgets('DeveloperCard renders social action chips', (
      WidgetTester tester,
    ) async {
      const dev = DeveloperProfile(
        name: 'Jane Doe',
        role: 'Flutter Expert',
        bio: 'Building awesome apps',
        accentColor: Colors.purple,
        links: [
          DeveloperLink(
            label: 'Portfolio',
            icon: Icons.public,
            url: 'https://example.com',
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DeveloperCard(profile: dev),
          ),
        ),
      );

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('Flutter Expert'), findsOneWidget);
      expect(find.text('Portfolio'), findsOneWidget);
    });
  });

  group('Presentation Layer - GameRoundNotifier AutoDispose & State Reset', () {
    test('gameRoundProvider initializes fresh state and auto-disposes on leave', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Listen to Naruto category provider
      final sub = container.listen(
        gameRoundProvider('Naruto'),
        (_, __) {},
        fireImmediately: true,
      );

      final initialState = container.read(gameRoundProvider('Naruto'));
      expect(initialState.hasStarted, isFalse);
      expect(initialState.showPicture, isFalse);
      expect(initialState.currentImageAsset, isNull);
      expect(initialState.allImages, isNotEmpty);

      // Start countdown / game round
      container.read(gameRoundProvider('Naruto').notifier).startCountdown();
      final inProgressState = container.read(gameRoundProvider('Naruto'));
      expect(inProgressState.isCountingDown, isTrue);
      expect(inProgressState.hasStarted, isTrue);

      // Simulate leaving the game screen (unsubscribing/disposing provider)
      sub.close();

      // Wait a microtask turn for autoDispose cleanup
      await Future<void>.delayed(Duration.zero);

      // Next time the user opens the category screen, state is fresh and ready
      final freshState = container.read(gameRoundProvider('Naruto'));
      expect(freshState.hasStarted, isFalse);
      expect(freshState.showPicture, isFalse);
      expect(freshState.isCountingDown, isFalse);
      expect(freshState.currentImageAsset, isNull);
      expect(freshState.remainingImages.length, freshState.allImages.length);
    });
  });
}

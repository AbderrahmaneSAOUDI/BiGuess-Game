import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/data/local/local_content_runtime.dart';
import 'package:gdg_guess_game/domain/models/difficulty.dart';
import 'package:gdg_guess_game/main.dart';
import 'package:gdg_guess_game/presentation/images/content_image_loader.dart';
import 'package:gdg_guess_game/presentation/widgets/animations/animated_character_card.dart';
import 'package:gdg_guess_game/providers/content_image_provider.dart';
import 'package:gdg_guess_game/providers/game_controller.dart';
import 'package:gdg_guess_game/providers/game_session_controller.dart';
import 'package:gdg_guess_game/providers/game_settings_controller.dart';
import 'package:gdg_guess_game/providers/topic_pack_providers.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

class _RejectHttp extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Offline gate forbids every HTTP client');
  }
}

class _FastCountdown extends CountdownDurationNotifier {
  @override
  int build() => 1;
}

Future<void> _decode(ContentImageLoader loader, String reference) async {
  final result = Completer<ImageInfo>();
  final stream = loader.imageFor(reference).resolve(const ImageConfiguration());
  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      stream.removeListener(listener);
      result.complete(info);
    },
    onError: (Object error, StackTrace? trace) {
      stream.removeListener(listener);
      result.completeError(error, trace);
    },
  );
  stream.addListener(listener);
  final info = await result.future.timeout(const Duration(seconds: 15));
  expect(info.image.width, 8);
  expect(info.image.height, 8);
  info.dispose();
}

void main() {
  final network = _RejectHttp();
  testWidgets(
    'offline imported SQL Pack survives restart and all rounds',
    (tester) async => HttpOverrides.runWithHttpOverrides(() async {
      const phase = String.fromEnvironment('offlineGatePhase');
      const gateRoot = String.fromEnvironment('offlineGateRoot');
      final directory = (await tester.runAsync(
        () async => gateRoot.isEmpty
            ? Directory.systemTemp.createTemp('biguess-offline-')
            : Directory(gateRoot).create(recursive: true),
      ))!;
      if (gateRoot.isEmpty) {
        addTearDown(() => directory.delete(recursive: true));
      }
      // Prove that the request observer is active before checking zero attempts.
      expect(HttpClient.new, throwsStateError);
      expect(network.attempts, 1);
      network.attempts = 0;
      tester.view.physicalSize = const Size(480, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final source = File(p.join(directory.path, 'input.biguesspack'));
      if (phase != 'restart') {
        await tester.runAsync(
          () => File(
            'test/fixtures/local_pack/colors.biguesspack',
          ).copy(source.path),
        );
      } else {
        expect(await tester.runAsync(source.exists), isFalse);
        expect(
          await tester.runAsync(
            () => File(
              p.join(directory.path, LocalContentRuntime.databaseName),
            ).exists(),
          ),
          isTrue,
        );
      }

      Future<void> play({
        required bool import,
        required int rounds,
        required bool hard,
        bool kill = false,
      }) async {
        final runtime = (await tester.runAsync(
          () => LocalContentRuntime.open(
            supportDirectory: directory,
            importFile: import ? source : null,
          ),
        ))!;
        expect(runtime.failure, isNull);
        expect(runtime.usesSqlite, isTrue);
        final loader = ContentImageLoader(
          openStore: () async => runtime.store!,
        );
        await tester.runAsync(() async {
          for (final card in runtime.repository.getInstalledCardsForPack(
            'fixture-pack',
          )!) {
            await _decode(loader, card.imageReference);
          }
        });
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              localContentRuntimeProvider.overrideWithValue(runtime),
              contentImageLoaderProvider.overrideWithValue(loader),
              countdownDurationProvider.overrideWith(_FastCountdown.new),
            ],
            child: const BiGuessApp(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        final scope = ProviderScope.containerOf(
          tester.element(find.byType(BiGuessApp)),
        );
        expect(scope.read(automaticUpdateChecksProvider), isFalse);
        await tester.tap(find.text('Colors'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        await tester.tap(find.text('Original colors'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Game Setup'), findsOneWidget);
        if (hard) {
          await tester.tap(find.byType(DropdownButtonFormField<Difficulty>));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Hard').last);
          await tester.pumpAndSettle();
        }
        expect(find.text('${hard ? 2 : 1} eligible cards'), findsOneWidget);
        await tester.enterText(find.byType(TextField), '$rounds');
        await tester.tap(find.text('Start Game'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        final legacyReveal = find
            .byKey(const ValueKey('mystery'))
            .evaluate()
            .isNotEmpty;
        if (legacyReveal) {
          await tester.tap(find.byKey(const ValueKey('mystery')));
        }
        final seen = <String>{};
        for (var round = 1; round <= rounds; round++) {
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          await tester.pump(const Duration(seconds: 1));
          final card = tester.widget<AnimatedCharacterCard>(
            find.byType(AnimatedCharacterCard),
          );
          final identity =
              card.characterName ??
              tester
                  .widget<Text>(find.byKey(const ValueKey('identity_name')))
                  .data!;
          expect(identity, hard ? isIn(['Red', 'Blue']) : 'Red');
          expect(card.imageAsset, startsWith('biguess-pack:'));
          seen.add(identity);
          expect(
            find
                .byType(RawImage)
                .evaluate()
                .any((e) => (e.widget as RawImage).image != null),
            isTrue,
          );
          final gameScope = ProviderScope.containerOf(
            tester.element(find.byType(AnimatedCharacterCard)),
          );
          if (legacyReveal) {
            final state = gameScope.read(
              gameRoundProvider((topic: 'Colors', pack: 'Original colors')),
            );
            expect(state.roundsPlayed, round);
            expect(state.hasReachedRoundLimit, round == rounds);
          } else {
            final session = gameScope.read(gameSessionProvider);
            expect(session.roundNumber, round);
            expect(find.text('Round $round of $rounds'), findsOneWidget);
          }
          expect(network.attempts, 0);
          if (kill) {
            await tester.runAsync(() async {
              final pending = File(p.join(directory.path, 'ready.pending'));
              await pending.writeAsString(
                jsonEncode({'pid': pid, 'round': round}),
                flush: true,
              );
              await pending.rename(
                p.join(directory.path, 'ready-to-kill.json'),
              );
              // The external harness SIGKILLs this actual flutter_tester process.
              await Completer<void>().future;
            });
          }
          if (round < rounds) {
            await tester.tap(
              find.text(legacyReveal ? 'Refresh' : 'Next Round'),
            );
          }
        }
        if (hard) expect(seen, {'Red', 'Blue'});
        if (!legacyReveal) {
          await tester.tap(find.text('Finish Game'));
          await tester.pump();
          expect(find.text('Game complete'), findsOneWidget);
        }
        expect(find.text('Return to Packs'), findsOneWidget);
        await tester.tap(find.text('Return to Packs'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Original colors'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        runtime.close();
        PaintingBinding.instance.imageCache
          ..clear()
          ..clearLiveImages();
      }

      await play(
        import: phase != 'restart',
        rounds: 10,
        hard: true,
        kill: phase == 'seed',
      );
      if (phase != 'seed') {
        await tester.runAsync(() async {
          if (await source.exists()) await source.delete();
        });
        await play(import: false, rounds: 3, hard: false);
        await tester.runAsync(() async {
          final database = sqlite3.open(
            p.join(directory.path, LocalContentRuntime.databaseName),
          );
          expect(
            database.select('PRAGMA integrity_check').single.values.single,
            'ok',
          );
          expect(database.select('PRAGMA foreign_key_check'), isEmpty);
          expect(
            database.select('SELECT * FROM installed_cards'),
            hasLength(2),
          );
          database.close();
        });
        expect(network.attempts, 0);
        debugPrint(
          'OFFLINE GATE PASS: SQL/private images, 10 + 3 rounds, zero HTTP clients, integrity ok',
        );
      }
    }, network),
  );
}

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/data/local/local_pack_file.dart';
import 'package:gdg_guess_game/data/local/local_pack_store.dart';
import 'package:gdg_guess_game/data/repositories/sqlite_content_repository.dart';
import 'package:gdg_guess_game/domain/models/card.dart';
import 'package:gdg_guess_game/domain/models/difficulty.dart';
import 'package:gdg_guess_game/domain/models/game_session.dart';
import 'package:gdg_guess_game/domain/models/game_session_configuration.dart';
import 'package:gdg_guess_game/domain/models/pack.dart';
import 'package:gdg_guess_game/domain/models/topic.dart';
import 'package:gdg_guess_game/providers/game_session_controller.dart';

void main() {
  late ProviderContainer container;
  late GameSessionNotifier controller;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        gameSessionProvider.overrideWith(
          () => GameSessionNotifier(random: Random(13)),
        ),
      ],
    );
    addTearDown(container.dispose);
    controller = container.read(gameSessionProvider.notifier);
  });

  test('installed updates, unpublishing and tombstones cannot alter play', () {
    final repository = SqliteContentRepository.open(':memory:');
    final topic = Topic(id: 'topic', name: 'Original Topic', published: true);
    final pack = Pack(
      id: 'pack',
      topicId: 'topic',
      name: 'Original Pack',
      published: true,
    );
    final originalCards = [
      for (final id in ['one', 'two', 'three'])
        Card(
          id: id,
          packId: pack.id,
          name: 'Original $id',
          imageReference: 'private/generation-1/$id.webp',
          difficulty: Difficulty.easy,
        ),
    ];
    repository.putContent(topics: [topic], packs: [pack], cards: originalCards);
    repository.setInstalledPack(
      InstalledPackState(
        packId: pack.id,
        revision: 1,
        installedAt: DateTime.utc(2026),
      ),
    );
    controller.configure(
      GameSessionConfiguration(
        topicId: topic.id,
        packIds: [pack.id],
        rounds: 10,
      ),
    );
    List<Card> eligible() => repository.getEligibleCards(
      topicId: topic.id,
      packIds: [pack.id],
      maximumDifficulty: Difficulty.easy,
      includeUnpublished: false,
    );
    controller.start(
      topic: repository.getTopics().single,
      installedPacks: repository.getPacksForTopic(topic.id),
      installedCards: eligible(),
    );
    final active = container.read(gameSessionProvider);
    final snapshot = active.snapshot!;
    repository.putContent(
      packs: [
        Pack(id: pack.id, topicId: topic.id, name: 'Changed', revision: 2),
      ],
      cards: [
        Card(
          id: 'one',
          packId: pack.id,
          name: 'Remote replacement',
          imageReference: 'private/generation-2/changed.webp',
          difficulty: Difficulty.hard,
        ),
      ],
    );
    // Even activation of a newer installed revision cannot modify this game.
    repository.setInstalledPack(
      InstalledPackState(
        packId: pack.id,
        revision: 2,
        installedAt: DateTime.utc(2026),
      ),
    );
    repository.putContent(
      topics: [Topic(id: topic.id, name: 'Unpublished', revision: 2)],
    );
    for (final entry in {
      ContentEntityType.topic: topic.id,
      ContentEntityType.pack: pack.id,
      ContentEntityType.card: 'one',
    }.entries) {
      repository.recordDeletion(
        ContentDeletionMarker(
          entityType: entry.key,
          entityId: entry.value,
          revision: 3,
        ),
      );
    }
    expect(eligible(), isEmpty);
    expect(repository.getDeletionMarkers(pendingOnly: true), hasLength(3));
    expect(container.read(gameSessionProvider), same(active));
    // Model deleted metadata too; no per-round availability checks may occur.
    repository.putContent(
      topics: [
        Topic(id: topic.id, name: 'Deleted', deleted: true, revision: 3),
      ],
      packs: [
        Pack(
          id: pack.id,
          topicId: topic.id,
          name: 'Deleted',
          deleted: true,
          revision: 3,
        ),
      ],
    );
    expect(eligible(), isEmpty);
    repository.close();

    for (var round = 0; round < 10; round++) {
      final session = container.read(gameSessionProvider);
      expect(session.roundIndex, round);
      expect(session.snapshot, same(snapshot));
      expect(originalCards, contains(session.assignedCard));
      expect(snapshot.topic, topic);
      expect(snapshot.packs.single, pack);
      controller.nextRound();
    }
    expect(
      container.read(gameSessionProvider).phase,
      GameSessionPhase.completed,
    );
    expect(snapshot.cards, originalCards);
    controller.returnHome();
    expect(container.read(gameSessionProvider).retainsContent, isFalse);
  });

  test(
    'an installed Pack replacement preserves active names and image bytes',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'biguess-session-',
      );
      addTearDown(() => temporary.delete(recursive: true));
      final store = LocalPackStore(
        Directory('${temporary.path}/private-packs'),
      );
      final source = File('test/fixtures/local_pack/colors.biguesspack');
      final original = await store.install(source);
      // Capture the generation resources through the installer's stable public
      // contract, independent of loose files versus protected image packaging.
      final resources =
          (await original.directory.list(recursive: true).toList())
              .whereType<File>();
      final beforeBytes = {
        for (final file in resources) file.path: await file.readAsBytes(),
      };
      controller.configure(
        GameSessionConfiguration(
          topicId: original.manifest.topic.id,
          packIds: [original.manifest.pack.id],
          maximumDifficulty: Difficulty.hard,
          rounds: 10,
        ),
      );
      controller.start(
        topic: original.manifest.topic,
        installedPacks: [original.manifest.pack],
        installedCards: original.cards,
      );
      final snapshot = container.read(gameSessionProvider).snapshot!;

      final archive = ZipDecoder().decodeBytes(await source.readAsBytes());
      final manifest =
          jsonDecode(utf8.decode(archive.find('manifest.json')!.content))
              as Map<String, dynamic>;
      (manifest['pack'] as Map<String, dynamic>)['revision'] = 2;
      final firstCard =
          (manifest['cards'] as List<dynamic>).first as Map<String, dynamic>;
      firstCard['name'] = 'Remote replacement';
      firstCard['id'] = 'replacement-id';
      final rights =
          (manifest['provenance'] as Map<String, dynamic>)['cardRights']
              as List<dynamic>;
      (rights.first as Map<String, dynamic>)['id'] = 'replacement-id';
      final update = Archive();
      for (final entry in archive.files) {
        final bytes = entry.name == 'manifest.json'
            ? utf8.encode(LocalPackManifest.canonicalJson(manifest))
            : entry.content;
        update.add(
          ArchiveFile(entry.name, bytes.length, bytes)
            ..compression = CompressionType.none
            ..mode = 0x81a4,
        );
      }
      final updateFile = File('${temporary.path}/update.biguesspack');
      await updateFile.writeAsBytes(ZipEncoder().encodeBytes(update));
      final next = await store.install(updateFile);
      expect(next.cards.first.name, 'Remote replacement');
      expect(next.directory.path, isNot(original.directory.path));
      expect(
        next.cards.map((card) => card.id),
        isNot(contains(original.cards.first.id)),
      );

      for (var round = 0; round < 10; round++) {
        final session = container.read(gameSessionProvider);
        final assigned = session.assignedCard!;
        expect(session.snapshot, same(snapshot));
        expect(original.cards, contains(assigned));
        for (final entry in beforeBytes.entries) {
          expect(await File(entry.key).readAsBytes(), entry.value);
        }
        controller.nextRound();
      }
      expect(container.read(gameSessionProvider).completedRounds, 10);
      expect(snapshot.cards.map((card) => card.name), ['Red', 'Blue']);
      controller.exit();
      expect(container.read(gameSessionProvider).retainsContent, isFalse);
    },
  );
}

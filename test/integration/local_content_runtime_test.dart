import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/data/local/local_content_runtime.dart';
import 'package:gdg_guess_game/data/repositories/legacy_manifest_content_repository.dart';
import 'package:gdg_guess_game/data/repositories/sqlite_content_repository.dart';
import 'package:gdg_guess_game/domain/models/card.dart';
import 'package:gdg_guess_game/domain/models/difficulty.dart';
import 'package:gdg_guess_game/domain/models/pack.dart';
import 'package:gdg_guess_game/domain/models/topic.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('biguess-runtime-');
  });
  tearDown(() => directory.delete(recursive: true));

  Future<LocalContentRuntime> seed() => LocalContentRuntime.open(
    supportDirectory: directory,
    importFile: File('test/fixtures/local_pack/colors.biguesspack'),
  );

  test(
    'verified private files project into SQL and reopen without import',
    () async {
      var runtime = await seed();
      expect(runtime.failure, isNull);
      expect(runtime.usesSqlite, isTrue);
      final original = runtime.repository.getInstalledCardsForPack(
        'fixture-pack',
      );
      expect(original!.map((card) => card.name), ['Red', 'Blue']);
      expect(
        original.every((c) => c.imageReference.startsWith('biguess-pack:')),
        isTrue,
      );
      runtime.close();
      runtime = await LocalContentRuntime.open(supportDirectory: directory);
      addTearDown(runtime.close);
      expect(runtime.failure, isNull);
      expect(
        runtime.repository.getInstalledCardsForPack('fixture-pack'),
        original,
      );
      final database = sqlite3.open(
        p.join(directory.path, LocalContentRuntime.databaseName),
      );
      expect(
        database.select('PRAGMA integrity_check').single.values.single,
        'ok',
      );
      expect(database.select('PRAGMA foreign_key_check'), isEmpty);
      database.close();
    },
  );

  test(
    'empty storage and explicit rollback retain playable legacy content',
    () async {
      final empty = await LocalContentRuntime.open(supportDirectory: directory);
      expect(empty.repository, isA<LegacyManifestContentRepository>());
      expect(empty.repository.getTopics(), isNotEmpty);
      empty.close();
      final installed = await seed();
      installed.close();
      final rollback = await LocalContentRuntime.open(
        supportDirectory: directory,
        useLegacy: true,
      );
      expect(rollback.repository, isA<LegacyManifestContentRepository>());
      expect(
        rollback.repository.getTopics().map((t) => t.name),
        contains('Anime'),
      );
      rollback.close();
      final restored = await LocalContentRuntime.open(
        supportDirectory: directory,
      );
      expect(restored.usesSqlite, isTrue);
      restored.close();
    },
  );

  test('startup replaces stale projected Cards from committed files', () async {
    var runtime = await seed();
    final sql = runtime.repository as SqliteContentRepository;
    final original = sql.getInstalledCardsForPack('fixture-pack');
    sql.putContent(
      cards: [
        Card(
          id: 'unverified-cache-only',
          packId: 'fixture-pack',
          name: 'Ghost',
          imageReference: 'https://invalid.example/never-fetch.png',
          difficulty: Difficulty.easy,
        ),
      ],
    );
    expect(sql.getCardsForPack('fixture-pack'), hasLength(3));
    runtime.close();
    runtime = await LocalContentRuntime.open(supportDirectory: directory);
    addTearDown(runtime.close);
    expect(runtime.failure, isNull);
    expect(runtime.repository.getCardsForPack('fixture-pack'), original);
    expect(
      runtime.repository.getInstalledCardsForPack('fixture-pack'),
      original,
    );
  });

  test(
    'corrupt images fall back without rewriting files or SQL metadata',
    () async {
      final initial = await seed();
      final pack = (await initial.store!.readAllInstalled()).single;
      initial.close();
      final databaseFile = File(
        p.join(directory.path, LocalContentRuntime.databaseName),
      );
      final before = await databaseFile.readAsBytes();
      final images = File(p.join(pack.directory.path, 'images.bgpack'));
      await images.writeAsBytes([1, 2, 3]);
      final fallback = await LocalContentRuntime.open(
        supportDirectory: directory,
      );
      expect(fallback.failure, isA<FormatException>());
      expect(fallback.usesSqlite, isFalse);
      expect(await images.readAsBytes(), [1, 2, 3]);
      expect(await databaseFile.readAsBytes(), before);
      fallback.close();
    },
  );

  test(
    'unsupported SQL remains intact and never triggers automatic reset',
    () async {
      final initial = await seed();
      initial.close();
      final databasePath = p.join(
        directory.path,
        LocalContentRuntime.databaseName,
      );
      final future = sqlite3.open(databasePath);
      future.userVersion = 999;
      future.close();
      final fallback = await LocalContentRuntime.open(
        supportDirectory: directory,
      );
      expect(fallback.failure, isStateError);
      expect(fallback.usesSqlite, isFalse);
      final preserved = sqlite3.open(databasePath);
      expect(preserved.userVersion, 999);
      expect(preserved.select('SELECT * FROM installed_cards'), hasLength(2));
      preserved.close();
      fallback.close();
    },
  );

  test(
    'projection rollback preserves the previous installed snapshot',
    () async {
      final runtime = await seed();
      addTearDown(runtime.close);
      final repository = runtime.repository as SqliteContentRepository;
      final original = repository.getInstalledCardsForPack('fixture-pack');
      final database = sqlite3.open(
        p.join(directory.path, LocalContentRuntime.databaseName),
      );
      database.execute(
        '''CREATE TRIGGER fail_projection BEFORE INSERT ON installed_cards
      BEGIN SELECT RAISE(ABORT, 'Simulated full disk'); END''',
      );
      database.close();
      expect(
        () => repository.replaceInstalledContent(
          topics: [Topic(id: 'new-topic', name: 'New')],
          packs: [Pack(id: 'new-pack', topicId: 'new-topic', name: 'New')],
          cards: [
            Card(
              id: 'new-card',
              packId: 'new-pack',
              name: 'New',
              imageReference: 'assets/new.webp',
              difficulty: Difficulty.easy,
            ),
          ],
          projectedAt: DateTime.utc(2026),
        ),
        throwsA(isA<SqliteException>()),
      );
      expect(repository.getTopics().single.id, 'fixture-topic');
      expect(repository.getInstalledCardsForPack('fixture-pack'), original);
    },
  );
}

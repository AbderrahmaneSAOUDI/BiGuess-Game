import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gdg_guess_game/data/database/content_database.dart';
import 'package:gdg_guess_game/data/repositories/legacy_manifest_content_repository.dart';
import 'package:gdg_guess_game/data/repositories/sqlite_content_repository.dart';
import 'package:gdg_guess_game/domain/models/card.dart';
import 'package:gdg_guess_game/domain/models/difficulty.dart';
import 'package:gdg_guess_game/domain/models/pack.dart';
import 'package:gdg_guess_game/domain/models/topic.dart';
import 'package:sqlite3/sqlite3.dart';

class _NoNetwork extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw StateError('Network is disabled in local repository tests');
}

void main() {
  late Directory directory;
  late String databasePath;
  HttpOverrides? previousOverrides;

  setUp(() {
    previousOverrides = HttpOverrides.current;
    HttpOverrides.global = _NoNetwork();
    directory = Directory.systemTemp.createTempSync('biguess-sqlite-');
    databasePath = '${directory.path}/content.sqlite';
  });

  tearDown(() {
    HttpOverrides.global = previousOverrides;
    directory.deleteSync(recursive: true);
  });

  void createV1() {
    final database = sqlite3.open(databasePath);
    try {
      database.execute(
        File('test/fixtures/database/content_v1.sql').readAsStringSync(),
      );
    } finally {
      database.close();
    }
  }

  void seed(SqliteContentRepository repository) {
    repository.putContent(
      topics: [
        Topic(id: 'topic', name: 'Étoiles 星'),
        Topic(id: 'other-topic', name: 'Other'),
      ],
      packs: [
        Pack(id: 'pack', topicId: 'topic', name: 'Shapes', revision: 3),
        Pack(id: 'uninstalled', topicId: 'topic', name: 'Not installed'),
        Pack(id: 'other-pack', topicId: 'other-topic', name: 'Other'),
        Pack(
          id: 'deleted-pack',
          topicId: 'topic',
          name: 'Deleted',
          deleted: true,
        ),
      ],
      cards: [
        Card(
          id: 'z',
          packId: 'pack',
          name: 'Square',
          imageReference: 'assets/星/Square.webp',
          difficulty: Difficulty.easy,
        ),
        Card(
          id: 'a',
          packId: 'pack',
          name: 'Star',
          imageReference: 'private/star.webp',
          difficulty: Difficulty.hard,
        ),
        Card(
          id: 'm',
          packId: 'pack',
          name: '100%_shape',
          imageReference: 'private/medium.webp',
          difficulty: Difficulty.medium,
        ),
        for (final packId in ['uninstalled', 'other-pack', 'deleted-pack'])
          Card(
            id: 'card-$packId',
            packId: packId,
            name: 'Elsewhere',
            imageReference: 'elsewhere.webp',
            difficulty: Difficulty.easy,
          ),
      ],
    );
    for (final packId in ['pack', 'other-pack', 'deleted-pack']) {
      repository.setInstalledPack(
        InstalledPackState(
          packId: packId,
          revision: packId == 'pack' ? 3 : 1,
          installedAt: DateTime.utc(2026, 11, 6),
        ),
      );
    }
  }

  test('creates, reopens and restarts a real offline database', () {
    var repository = SqliteContentRepository.open(databasePath);
    seed(repository);
    final cards = repository.getCardsForPack('pack');
    expect(cards.map((card) => card.id), ['z', 'a', 'm']);
    expect(() => cards.clear(), throwsUnsupportedError);
    repository.close();

    repository = SqliteContentRepository.open(databasePath);
    addTearDown(repository.close);
    expect(repository.getTopics().first.name, 'Étoiles 星');
    expect(repository.getCardsForPack('pack'), cards);
    expect(repository.getPacksForTopic('missing'), isEmpty);
    expect(repository.getCardsForPack('missing'), isEmpty);
    final installed = repository.getInstalledPack('pack')!;
    expect(installed.revision, 3);
    expect(installed.installedAt, DateTime.utc(2026, 11, 6));
    expect(repository.getInstalledPack('missing'), isNull);

    final observer = ContentDatabase.open(databasePath);
    addTearDown(observer.close);
    expect(observer.userVersion, ContentDatabase.schemaVersion);
    expect(observer.select('PRAGMA integrity_check').single.values, ['ok']);
    expect(observer.select('PRAGMA foreign_keys').single.values, [1]);
  });

  test('literal prefix search and installed cumulative one-topic selection', () {
    final repository = SqliteContentRepository.open(databasePath);
    addTearDown(repository.close);
    seed(repository);
    expect(repository.searchTopics('Étoiles').single.id, 'topic');
    expect(repository.searchPacks('sha').single.id, 'pack');
    expect(repository.searchCards('s', packId: 'pack').map((c) => c.id), [
      'z',
      'a',
    ]);
    expect(repository.searchCards('100%_').single.id, 'm');
    expect(repository.searchCards("' OR 1=1 --"), isEmpty);
    expect(repository.searchCards('Else', packId: 'pack'), isEmpty);
    expect(repository.searchCards('Else').length, 3);
    expect(
      repository.getEligibleCards(
        topicId: 'topic',
        packIds: ['pack'],
        maximumDifficulty: Difficulty.hard,
        includeUnpublished: false,
      ),
      isEmpty,
    );
    final ids = ['pack', 'pack', 'uninstalled', 'other-pack', 'deleted-pack'];
    for (final level in Difficulty.values) {
      final cards = repository.getEligibleCards(
        topicId: 'topic',
        packIds: ids,
        maximumDifficulty: level,
        includeUnpublished: true,
      );
      expect(cards.length, level.value);
      expect(cards.every((c) => c.packId == 'pack'), isTrue);
      expect(cards.every((c) => c.difficulty.value <= level.value), isTrue);
    }
    expect(
      repository.getEligibleCards(
        topicId: 'topic',
        packIds: [],
        maximumDifficulty: Difficulty.hard,
        includeUnpublished: true,
      ),
      isEmpty,
    );
    // Names/metadata upserts do not reorder content or change its technical ID.
    repository.putContent(
      packs: [Pack(id: 'pack', topicId: 'topic', name: 'Renamed', revision: 4)],
    );
    expect(repository.getPacksForTopic('topic').first.name, 'Renamed');
    expect(repository.getCardsForPack('pack').map((c) => c.id), [
      'z',
      'a',
      'm',
    ]);
    repository.putContent(
      topics: [
        Topic(id: 'topic', name: 'Étoiles 星', published: true, revision: 2),
      ],
      packs: [
        Pack(
          id: 'pack',
          topicId: 'topic',
          name: 'Renamed',
          published: true,
          revision: 4,
        ),
      ],
    );
    expect(
      repository
          .getEligibleCards(
            topicId: 'topic',
            packIds: ['pack'],
            maximumDifficulty: Difficulty.hard,
            includeUnpublished: false,
          )
          .length,
      3,
    );
    repository.putContent(
      topics: [
        Topic(
          id: 'topic',
          name: 'Étoiles 星',
          published: true,
          deleted: true,
          revision: 3,
        ),
      ],
    );
    expect(
      repository.getEligibleCards(
        topicId: 'topic',
        packIds: ['pack'],
        maximumDifficulty: Difficulty.hard,
        includeUnpublished: true,
      ),
      isEmpty,
    );
  });

  test('relationships, checks and primary keys are enforced by SQLite', () {
    final repository = SqliteContentRepository.open(databasePath);
    seed(repository);
    repository.close();
    final database = ContentDatabase.open(databasePath);
    addTearDown(database.close);
    for (final sql in [
      "INSERT INTO packs VALUES ('orphan', 'missing', 'Orphan', 0, 0, 1)",
      "INSERT INTO cards VALUES ('orphan', 'missing', 'Orphan', 'a.webp', 1)",
      "INSERT INTO installed_packs VALUES ('missing', 1, 0)",
      "INSERT INTO topics VALUES ('topic', 'Duplicate', 0, 0, 1)",
      "UPDATE cards SET difficulty = 4 WHERE id = 'z'",
      "UPDATE cards SET name = ' ' WHERE id = 'z'",
      "UPDATE cards SET image_reference = '' WHERE id = 'z'",
      "UPDATE topics SET published = 2 WHERE id = 'topic'",
      "UPDATE topics SET revision = 0 WHERE id = 'topic'",
      "UPDATE topics SET revision = 'oops' WHERE id = 'topic'",
      "UPDATE packs SET revision = 3.5 WHERE id = 'pack'",
      "UPDATE packs SET revision = 2 WHERE id = 'pack'",
      "UPDATE installed_packs SET installed_at = -1 WHERE pack_id = 'pack'",
      "UPDATE installed_packs SET installed_at = 'oops' WHERE pack_id = 'pack'",
      "UPDATE installed_packs SET revision = 4 WHERE pack_id = 'pack'",
      "INSERT INTO installed_packs VALUES ('uninstalled', 2, 0)",
      "DELETE FROM topics WHERE id = 'topic'",
      "DELETE FROM packs WHERE id = 'pack'",
      "INSERT INTO deletion_markers VALUES ('invalid', 'x', 1, 0)",
      "INSERT INTO deletion_markers VALUES ('pack', 'x', 'oops', 0)",
    ]) {
      expect(
        () => database.execute(sql),
        throwsA(isA<SqliteException>()),
        reason: sql,
      );
    }
    expect(database.select('PRAGMA foreign_key_check'), isEmpty);
  });

  test('failed metadata batch rolls back all earlier writes', () {
    final repository = SqliteContentRepository.open(databasePath);
    addTearDown(repository.close);
    seed(repository);
    expect(
      () => repository.putContent(
        topics: [Topic(id: 'new', name: 'New')],
        packs: [Pack(id: 'bad', topicId: 'missing', name: 'Invalid')],
      ),
      throwsA(isA<SqliteException>()),
    );
    expect(repository.getTopics().map((t) => t.id), ['topic', 'other-topic']);
    for (final revision in [0, 4]) {
      expect(
        () => repository.setInstalledPack(
          InstalledPackState(
            packId: 'pack',
            revision: revision,
            installedAt: DateTime.utc(2026),
          ),
        ),
        throwsA(anything),
      );
    }
    repository.setInstalledPack(
      InstalledPackState(
        packId: 'pack',
        revision: 3,
        installedAt: DateTime.utc(2026),
      ),
    );
    expect(
      () => repository.setInstalledPack(
        InstalledPackState(
          packId: 'pack',
          revision: 2,
          installedAt: DateTime.utc(2026),
        ),
      ),
      throwsStateError,
    );
    expect(repository.getInstalledPack('pack')!.revision, 3);
  });

  test('tombstones survive restart without deleting active content', () {
    var repository = SqliteContentRepository.open(databasePath);
    seed(repository);
    final marker = ContentDeletionMarker(
      entityType: ContentEntityType.pack,
      entityId: 'pack',
      revision: 4,
    );
    repository.recordDeletion(marker);
    repository.close();
    repository = SqliteContentRepository.open(databasePath);
    addTearDown(repository.close);
    expect(repository.getDeletionMarkers(pendingOnly: true).single.revision, 4);
    expect(
      repository
          .getEligibleCards(
            topicId: 'topic',
            packIds: ['pack'],
            maximumDifficulty: Difficulty.hard,
            includeUnpublished: true,
          )
          .length,
      3,
    );
    repository.acknowledgeDeletion(marker);
    repository.recordDeletion(marker);
    repository.recordDeletion(
      ContentDeletionMarker(
        entityType: ContentEntityType.pack,
        entityId: 'pack',
        revision: 3,
      ),
    );
    expect(repository.getDeletionMarkers(pendingOnly: true), isEmpty);
    repository.recordDeletion(
      ContentDeletionMarker(
        entityType: ContentEntityType.pack,
        entityId: 'pack',
        revision: 5,
      ),
    );
    repository.acknowledgeDeletion(marker);
    expect(repository.getDeletionMarkers(pendingOnly: true).single.revision, 5);
    // Deletion evidence may refer to a target already absent from this device.
    repository.recordDeletion(
      ContentDeletionMarker(
        entityType: ContentEntityType.card,
        entityId: 'absent',
        revision: 1,
      ),
    );
    expect(repository.getDeletionMarkers().length, 2);
    expect(repository.getCardsForPack('pack').length, 3);
  });

  test(
    'v1 upgrades preserve content, installation, revisions and image paths',
    () {
      createV1();
      final repository = SqliteContentRepository.open(databasePath);
      expect(repository.getTopics().single.revision, 2);
      expect(
        repository.getCardsForPack('pack').single.imageReference,
        'assets/images/星/Square.webp',
      );
      expect(repository.getInstalledPack('pack')!.revision, 3);
      expect(repository.getDeletionMarkers(), isEmpty);
      repository.close();
      final restarted = SqliteContentRepository.open(databasePath);
      addTearDown(restarted.close);
      expect(restarted.getCardsForPack('pack').single.name, 'Square');

      final database = ContentDatabase.open(databasePath);
      addTearDown(database.close);
      expect(database.userVersion, ContentDatabase.schemaVersion);
      for (final query in [
        "SELECT * FROM cards WHERE pack_id = 'pack' AND difficulty <= 2",
        "SELECT * FROM cards WHERE name LIKE 'Squ%'",
        "SELECT * FROM cards WHERE pack_id = 'pack' AND name LIKE 'Squ%'",
        "SELECT * FROM packs WHERE topic_id = 'topic'",
        "SELECT * FROM packs WHERE name LIKE 'Sha%'",
        "SELECT * FROM topics WHERE name LIKE 'Éto%'",
      ]) {
        final plan = database.select('EXPLAIN QUERY PLAN $query');
        expect(
          plan.map((row) => row['detail']).join(' '),
          contains('USING INDEX'),
          reason: query,
        );
      }
    },
  );

  test('failed upgrades roll back DDL and user_version; retry is safe', () {
    createV1();
    var raw = sqlite3.open(databasePath);
    raw.execute('CREATE INDEX packs_topic ON packs(name)');
    raw.close();
    expect(
      () => SqliteContentRepository.open(databasePath),
      throwsA(isA<SqliteException>()),
    );
    raw = sqlite3.open(databasePath);
    expect(raw.userVersion, 1);
    expect(
      raw.select(
        "SELECT name FROM sqlite_master WHERE name = 'deletion_markers'",
      ),
      isEmpty,
    );
    expect(raw.select('SELECT * FROM cards').length, 1);
    raw.execute('DROP INDEX packs_topic');
    raw.close();
    final repository = SqliteContentRepository.open(databasePath);
    addTearDown(repository.close);
    expect(repository.getCardsForPack('pack').single.name, 'Square');
  });

  test('newer schemas are refused without downgrading or clearing data', () {
    createV1();
    var raw = sqlite3.open(databasePath);
    raw.userVersion = ContentDatabase.schemaVersion + 1;
    raw.close();
    expect(() => SqliteContentRepository.open(databasePath), throwsStateError);
    raw = sqlite3.open(databasePath);
    addTearDown(raw.close);
    expect(raw.userVersion, ContentDatabase.schemaVersion + 1);
    expect(raw.select('SELECT * FROM cards').length, 1);
  });

  test('upgrade rejects broken relationships without losing rows', () {
    createV1();
    var raw = sqlite3.open(databasePath);
    raw.execute("UPDATE cards SET pack_id = 'missing'");
    raw.close();
    expect(() => SqliteContentRepository.open(databasePath), throwsStateError);
    raw = sqlite3.open(databasePath);
    addTearDown(raw.close);
    expect(raw.userVersion, 1);
    expect(raw.select('SELECT * FROM cards').single['pack_id'], 'missing');
    expect(
      raw.select(
        "SELECT name FROM sqlite_master WHERE name = 'deletion_markers'",
      ),
      isEmpty,
    );
  });

  test('all bundled metadata round trips without loss or path changes', () {
    final legacy = LegacyManifestContentRepository();
    var repository = SqliteContentRepository.open(databasePath);
    final topics = legacy.getTopics();
    final packs = topics.expand((t) => legacy.getPacksForTopic(t.id)).toList();
    final cards = packs.expand((p) => legacy.getCardsForPack(p.id)).toList();
    repository.putContent(topics: topics, packs: packs, cards: cards);
    repository.close();
    repository = SqliteContentRepository.open(databasePath);
    addTearDown(repository.close);
    expect(repository.getTopics(), topics);
    for (final topic in topics) {
      expect(
        repository.getPacksForTopic(topic.id),
        legacy.getPacksForTopic(topic.id),
      );
    }
    for (final pack in packs) {
      expect(
        repository.getCardsForPack(pack.id),
        legacy.getCardsForPack(pack.id),
      );
    }
    expect(cards, isNotEmpty);
  });
}

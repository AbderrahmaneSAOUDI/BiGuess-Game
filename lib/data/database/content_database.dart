import 'package:sqlite3/sqlite3.dart';

/// Versioned native SQLite store. The caller owns and must close the connection.
/// No network, image-file operations, or mutable game state belong here.
abstract final class ContentDatabase {
  static const schemaVersion = 3;

  static Database open(String path) {
    final database = sqlite3.open(path);
    try {
      database.execute('PRAGMA foreign_keys = ON');
      database.execute('PRAGMA busy_timeout = 5000');
      // Read the version under the migration lock, including on a fresh file.
      database.execute('BEGIN EXCLUSIVE');
      try {
        final oldVersion = database.userVersion;
        if (oldVersion > schemaVersion) {
          throw StateError(
            'Content database version $oldVersion is newer than '
            'supported version $schemaVersion',
          );
        }
        for (var version = oldVersion; version < schemaVersion; version++) {
          if (version == 2 &&
              database.select('''SELECT 1 FROM installed_packs i
                JOIN packs p ON p.id = i.pack_id
                WHERE i.revision != p.revision LIMIT 1''').isNotEmpty) {
            // Earlier schemas did not retain old Card revisions. Never relabel
            // cached Cards as an older installed revision during the upgrade.
            throw StateError(
              'Restore installed content before upgrading: cached and installed '
              'Pack revisions differ',
            );
          }
          for (final sql in _migrations[version]) {
            database.execute(sql);
          }
          database.userVersion = version + 1;
        }
        if (database.select('PRAGMA foreign_key_check').isNotEmpty) {
          throw StateError('Content database has broken relationships');
        }
        database.execute('COMMIT');
      } catch (_) {
        database.execute('ROLLBACK');
        rethrow;
      }
      return database;
    } catch (_) {
      database.close();
      rethrow;
    }
  }

  // Append migrations; never change a shipped version or recreate a user's DB.
  static const _migrations = [
    [
      '''CREATE TABLE topics (
        id TEXT NOT NULL PRIMARY KEY CHECK(length(trim(id)) > 0),
        name TEXT NOT NULL CHECK(length(name) > 0 AND name = trim(name)),
        published INTEGER NOT NULL CHECK(published IN (0, 1)),
        deleted INTEGER NOT NULL CHECK(deleted IN (0, 1)),
        revision INTEGER NOT NULL CHECK(typeof(revision) = 'integer' AND revision >= 1)
      )''',
      '''CREATE TABLE packs (
        id TEXT NOT NULL PRIMARY KEY CHECK(length(trim(id)) > 0),
        topic_id TEXT NOT NULL REFERENCES topics(id) ON DELETE RESTRICT,
        name TEXT NOT NULL CHECK(length(name) > 0 AND name = trim(name)),
        published INTEGER NOT NULL CHECK(published IN (0, 1)),
        deleted INTEGER NOT NULL CHECK(deleted IN (0, 1)),
        revision INTEGER NOT NULL CHECK(typeof(revision) = 'integer' AND revision >= 1)
      )''',
      '''CREATE TABLE cards (
        id TEXT NOT NULL PRIMARY KEY CHECK(length(trim(id)) > 0),
        pack_id TEXT NOT NULL REFERENCES packs(id) ON DELETE RESTRICT,
        name TEXT NOT NULL CHECK(length(name) > 0 AND name = trim(name)),
        image_reference TEXT NOT NULL
          CHECK(length(image_reference) > 0 AND image_reference = trim(image_reference)),
        difficulty INTEGER NOT NULL CHECK(difficulty IN (1, 2, 3))
      )''',
      '''CREATE TABLE installed_packs (
        pack_id TEXT NOT NULL PRIMARY KEY REFERENCES packs(id) ON DELETE RESTRICT,
        revision INTEGER NOT NULL CHECK(typeof(revision) = 'integer' AND revision >= 1),
        installed_at INTEGER NOT NULL CHECK(typeof(installed_at) = 'integer' AND installed_at >= 0)
      )''',
    ],
    [
      // No foreign key: tombstones must survive removal of their target records.
      '''CREATE TABLE deletion_markers (
        entity_type TEXT NOT NULL CHECK(entity_type IN ('topic', 'pack', 'card')),
        entity_id TEXT NOT NULL CHECK(length(trim(entity_id)) > 0),
        revision INTEGER NOT NULL CHECK(typeof(revision) = 'integer' AND revision >= 1),
        applied INTEGER NOT NULL DEFAULT 0 CHECK(applied IN (0, 1)),
        PRIMARY KEY(entity_type, entity_id)
      )''',
      'CREATE INDEX packs_topic ON packs(topic_id)',
      'CREATE INDEX cards_pack_difficulty ON cards(pack_id, difficulty)',
      'CREATE INDEX topics_name ON topics(name COLLATE NOCASE)',
      'CREATE INDEX packs_name ON packs(name COLLATE NOCASE)',
      'CREATE INDEX cards_name ON cards(name COLLATE NOCASE)',
      'CREATE INDEX cards_pack_name ON cards(pack_id, name COLLATE NOCASE)',
      'CREATE INDEX deletion_markers_pending ON deletion_markers(applied)',
      '''CREATE TRIGGER topics_revision BEFORE UPDATE OF revision ON topics
        WHEN NEW.revision < OLD.revision
        BEGIN SELECT RAISE(ABORT, 'Topic revision cannot go backwards'); END''',
      '''CREATE TRIGGER packs_revision BEFORE UPDATE OF revision ON packs
        WHEN NEW.revision < OLD.revision
        BEGIN SELECT RAISE(ABORT, 'Pack revision cannot go backwards'); END''',
      '''CREATE TRIGGER installed_revision_insert BEFORE INSERT ON installed_packs
        WHEN NEW.revision > (SELECT revision FROM packs WHERE id = NEW.pack_id)
        BEGIN SELECT RAISE(ABORT, 'Unknown installed revision'); END''',
      '''CREATE TRIGGER installed_revision_update BEFORE UPDATE ON installed_packs
        WHEN NEW.revision < OLD.revision OR
          NEW.revision > (SELECT revision FROM packs WHERE id = NEW.pack_id)
        BEGIN SELECT RAISE(ABORT, 'Invalid installed revision'); END''',
    ],
    [
      '''CREATE TABLE installed_cards (
        id TEXT NOT NULL CHECK(length(trim(id)) > 0),
        pack_id TEXT NOT NULL REFERENCES installed_packs(pack_id) ON DELETE CASCADE,
        name TEXT NOT NULL CHECK(length(name) > 0 AND name = trim(name)),
        image_reference TEXT NOT NULL
          CHECK(length(image_reference) > 0 AND image_reference = trim(image_reference)),
        difficulty INTEGER NOT NULL CHECK(difficulty IN (1, 2, 3)),
        PRIMARY KEY(pack_id, id)
      )''',
      'CREATE INDEX installed_cards_pack_difficulty ON installed_cards(pack_id, difficulty)',
      '''INSERT INTO installed_cards
        SELECT c.* FROM cards c JOIN installed_packs i ON i.pack_id = c.pack_id
        ORDER BY c.rowid''',
    ],
  ];
}

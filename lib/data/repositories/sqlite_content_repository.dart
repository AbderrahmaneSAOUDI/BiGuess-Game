import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../domain/models/card.dart';
import '../../domain/models/content_validation.dart';
import '../../domain/models/difficulty.dart';
import '../../domain/models/pack.dart';
import '../../domain/models/topic.dart';
import '../../domain/repositories/content_repository.dart';
import '../database/content_database.dart';

enum ContentEntityType { topic, pack, card }

/// Operational metadata, separate from the gameplay Card model.
final class InstalledPackState {
  final String packId;
  final int revision;
  final DateTime installedAt;

  InstalledPackState({
    required String packId,
    required int revision,
    required this.installedAt,
  }) : packId = ContentValidation.id(packId, 'packId'),
       revision = ContentValidation.revision(revision);
}

final class ContentDeletionMarker {
  final ContentEntityType entityType;
  final String entityId;
  final int revision;
  final bool applied;

  ContentDeletionMarker({
    required this.entityType,
    required String entityId,
    required int revision,
    this.applied = false,
  }) : entityId = ContentValidation.id(entityId, 'entityId'),
       revision = ContentValidation.revision(revision);
}

/// Native local content store.
/// Reads preserve insertion order and return immutable values. Materialize an
/// in-memory game snapshot before play; do not query/write storage on each draw.
final class SqliteContentRepository implements ContentRepository {
  final Database _database;

  SqliteContentRepository.open(String databasePath)
    : _database = ContentDatabase.open(databasePath);

  /// Uses app-private support storage. Explicit paths allow isolated disk tests.
  static Future<SqliteContentRepository> openDefault() async {
    final directory = await getApplicationSupportDirectory();
    await Directory(directory.path).create(recursive: true);
    return SqliteContentRepository.open(
      path.join(directory.path, 'biguess_content.sqlite'),
    );
  }

  void close() => _database.close();

  /// Upsert cached metadata in one transaction, preserving existing order.
  /// Installed Card snapshots and their image references remain unchanged.
  /// This does not import files, install Packs, remove absent rows, or publish.
  /// Card changes are versioned by their containing Pack's revision.
  void putContent({
    Iterable<Topic> topics = const [],
    Iterable<Pack> packs = const [],
    Iterable<Card> cards = const [],
  }) => _transaction(() => _putContent(topics, packs, cards));

  void _putContent(
    Iterable<Topic> topics,
    Iterable<Pack> packs,
    Iterable<Card> cards,
  ) {
    for (final topic in topics) {
      _database.execute(
        '''INSERT INTO topics VALUES (?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET name=excluded.name,
          published=excluded.published, deleted=excluded.deleted,
          revision=excluded.revision''',
        [
          topic.id,
          topic.name,
          topic.published ? 1 : 0,
          topic.deleted ? 1 : 0,
          topic.revision,
        ],
      );
    }
    for (final pack in packs) {
      _database.execute(
        '''INSERT INTO packs VALUES (?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET topic_id=excluded.topic_id,
          name=excluded.name, published=excluded.published,
          deleted=excluded.deleted, revision=excluded.revision''',
        [
          pack.id,
          pack.topicId,
          pack.name,
          pack.published ? 1 : 0,
          pack.deleted ? 1 : 0,
          pack.revision,
        ],
      );
    }
    for (final card in cards) {
      _database.execute(
        '''INSERT INTO cards VALUES (?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET pack_id=excluded.pack_id,
          name=excluded.name, image_reference=excluded.image_reference,
          difficulty=excluded.difficulty''',
        [
          card.id,
          card.packId,
          card.name,
          card.imageReference,
          card.difficulty.value,
        ],
      );
    }
  }

  /// Rebuild only the dedicated installed-content projection from verified
  /// filesystem generations, before exposing it to screens. Never use this on
  /// the catalog/sync database: files remain the installation authority.
  void replaceInstalledContent({
    required Iterable<Topic> topics,
    required Iterable<Pack> packs,
    required Iterable<Card> cards,
    required DateTime projectedAt,
  }) {
    final localPacks = List<Pack>.of(packs);
    _transaction(() {
      _database.execute('DELETE FROM installed_packs');
      _database.execute('DELETE FROM cards');
      _database.execute('DELETE FROM packs');
      _database.execute('DELETE FROM topics');
      _putContent(topics, localPacks, cards);
      for (final pack in localPacks) {
        _setInstalledPack(
          InstalledPackState(
            packId: pack.id,
            revision: pack.revision,
            installedAt: projectedAt,
          ),
        );
      }
    });
  }

  @override
  List<Topic> getTopics() => _topics('SELECT * FROM topics ORDER BY rowid');

  @override
  List<Pack> getPacksForTopic(String topicId) => _packs(
    'SELECT * FROM packs WHERE topic_id = ? ORDER BY rowid',
    [topicId],
  );

  @override
  List<Card> getCardsForPack(String packId) =>
      _cards('SELECT * FROM cards WHERE pack_id = ? ORDER BY rowid', [packId]);

  @override
  List<Card>? getInstalledCardsForPack(String packId) {
    final installed = _database.select(
      '''SELECT i.pack_id FROM installed_packs i
      JOIN packs p ON p.id = i.pack_id JOIN topics t ON t.id = p.topic_id
      WHERE i.pack_id = ? AND p.deleted = 0 AND t.deleted = 0''',
      [packId],
    );
    if (installed.isEmpty) return null;
    return _cards(
      'SELECT * FROM installed_cards WHERE pack_id = ? ORDER BY rowid',
      [packId],
    );
  }

  // Indexed literal prefix search. SQLite NOCASE folds ASCII only; Unicode
  // spelling is preserved and matches exactly outside that range.
  List<Topic> searchTopics(String prefix) => _topics(
    "SELECT * FROM topics WHERE name LIKE ? ESCAPE '\\' ORDER BY rowid",
    [_prefix(prefix)],
  );

  List<Pack> searchPacks(String prefix) => _packs(
    "SELECT * FROM packs WHERE name LIKE ? ESCAPE '\\' ORDER BY rowid",
    [_prefix(prefix)],
  );

  List<Card> searchCards(String prefix, {String? packId}) => _cards(
    "SELECT * FROM cards WHERE name LIKE ? ESCAPE '\\' "
    '${packId == null ? '' : 'AND pack_id = ? '}ORDER BY rowid',
    [_prefix(prefix), if (packId != null) packId],
  );

  /// One-topic, cumulative difficulty pool from installed, non-deleted Packs.
  /// The caller must choose publication policy: installed unpublished-content
  /// playability remains an open product decision. Pending tombstones do not
  /// change availability; their safe application belongs to the sync lifecycle.
  List<Card> getEligibleCards({
    required String topicId,
    required Iterable<String> packIds,
    required Difficulty maximumDifficulty,
    required bool includeUnpublished,
  }) {
    final ids = packIds.toSet();
    if (ids.isEmpty) return const [];
    return _cards(
      '''SELECT c.* FROM installed_cards c
      JOIN packs p ON p.id = c.pack_id
      JOIN topics t ON t.id = p.topic_id
      JOIN installed_packs i ON i.pack_id = p.id
      WHERE p.topic_id = ? AND t.deleted = 0 AND p.deleted = 0
      ${includeUnpublished ? '' : 'AND t.published = 1 AND p.published = 1'}
      AND c.pack_id IN (${List.filled(ids.length, '?').join(',')})
      AND c.difficulty <= ? ORDER BY p.rowid, c.rowid''',
      [topicId, ...ids, maximumDifficulty.value],
    );
  }

  /// Snapshot already verified, installed Card metadata and its revision together.
  /// File validation/activation is owned by the installer. An existing revision
  /// retry leaves its snapshot intact even when the catalog has advanced.
  void setInstalledPack(InstalledPackState state) =>
      _transaction(() => _setInstalledPack(state));

  void _setInstalledPack(InstalledPackState state) {
    final packs = _packs('SELECT * FROM packs WHERE id = ?', [state.packId]);
    final previous = getInstalledPack(state.packId);
    if (previous != null && state.revision < previous.revision) {
      throw StateError('Installed revision cannot go backwards');
    }
    if (previous?.revision == state.revision) return;
    if (packs.isEmpty || state.revision != packs.single.revision) {
      throw StateError('Installed Cards must match the cached Pack revision');
    }
    _database.execute(
      '''INSERT INTO installed_packs VALUES (?, ?, ?)
        ON CONFLICT(pack_id) DO UPDATE SET revision=excluded.revision,
        installed_at=excluded.installed_at''',
      [state.packId, state.revision, state.installedAt.millisecondsSinceEpoch],
    );
    _database.execute('DELETE FROM installed_cards WHERE pack_id = ?', [
      state.packId,
    ]);
    _database.execute(
      '''INSERT INTO installed_cards SELECT * FROM cards
        WHERE pack_id = ? ORDER BY rowid''',
      [state.packId],
    );
  }

  InstalledPackState? getInstalledPack(String packId) {
    final rows = _database.select(
      'SELECT * FROM installed_packs WHERE pack_id = ?',
      [packId],
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return InstalledPackState(
      packId: row['pack_id'] as String,
      revision: row['revision'] as int,
      installedAt: DateTime.fromMillisecondsSinceEpoch(
        row['installed_at'] as int,
        isUtc: true,
      ),
    );
  }

  /// Records evidence only. It never removes metadata or image files.
  /// Duplicate/stale markers cannot undo an acknowledgement of a newer one.
  void recordDeletion(ContentDeletionMarker marker) {
    _database.execute(
      '''INSERT INTO deletion_markers
      (entity_type, entity_id, revision) VALUES (?, ?, ?)
      ON CONFLICT(entity_type, entity_id) DO UPDATE
      SET revision=excluded.revision, applied=0
      WHERE excluded.revision > deletion_markers.revision''',
      [marker.entityType.name, marker.entityId, marker.revision],
    );
  }

  List<ContentDeletionMarker> getDeletionMarkers({bool pendingOnly = false}) =>
      List.unmodifiable(
        _database
            .select(
              'SELECT * FROM deletion_markers '
              '${pendingOnly ? 'WHERE applied = 0 ' : ''}'
              'ORDER BY rowid',
            )
            .map(
              (row) => ContentDeletionMarker(
                entityType: ContentEntityType.values.byName(
                  row['entity_type'] as String,
                ),
                entityId: row['entity_id'] as String,
                revision: row['revision'] as int,
                applied: row['applied'] == 1,
              ),
            ),
      );

  /// Call only after safe removal. Revision matching prevents acknowledging a
  /// newer marker that arrived after the caller's snapshot was taken.
  void acknowledgeDeletion(ContentDeletionMarker marker) {
    _database.execute(
      '''UPDATE deletion_markers SET applied = 1
      WHERE entity_type = ? AND entity_id = ? AND revision = ?''',
      [marker.entityType.name, marker.entityId, marker.revision],
    );
  }

  void _transaction(void Function() action) {
    _database.execute('BEGIN IMMEDIATE');
    try {
      action();
      _database.execute('COMMIT');
    } catch (_) {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }

  List<Topic> _topics(String sql, [List<Object?> args = const []]) =>
      List.unmodifiable(
        _database
            .select(sql, args)
            .map(
              (row) => Topic(
                id: row['id'] as String,
                name: row['name'] as String,
                published: row['published'] == 1,
                deleted: row['deleted'] == 1,
                revision: row['revision'] as int,
              ),
            ),
      );

  List<Pack> _packs(String sql, [List<Object?> args = const []]) =>
      List.unmodifiable(
        _database
            .select(sql, args)
            .map(
              (row) => Pack(
                id: row['id'] as String,
                topicId: row['topic_id'] as String,
                name: row['name'] as String,
                published: row['published'] == 1,
                deleted: row['deleted'] == 1,
                revision: row['revision'] as int,
              ),
            ),
      );

  List<Card> _cards(String sql, [List<Object?> args = const []]) =>
      List.unmodifiable(
        _database
            .select(sql, args)
            .map(
              (row) => Card(
                id: row['id'] as String,
                packId: row['pack_id'] as String,
                name: row['name'] as String,
                imageReference: row['image_reference'] as String,
                difficulty: Difficulty.fromValue(row['difficulty'] as int),
              ),
            ),
      );

  static String _prefix(String value) =>
      '${value.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_')}%';
}

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/topic.dart';
import '../../domain/repositories/content_repository.dart';
import '../repositories/legacy_manifest_content_repository.dart';
import '../repositories/sqlite_content_repository.dart';
import 'local_pack_store.dart';

/// Startup-only bridge from committed private generations to the screen API.
/// The separate SQLite projection is disposable metadata, never installation
/// authority. No catalog/sync database or active game is modified here.
final class LocalContentRuntime {
  static const databaseName = 'biguess_installed_content.sqlite';
  final ContentRepository repository;
  final LocalPackStore? store;
  final Object? failure;

  const LocalContentRuntime._(this.repository, this.store, [this.failure]);

  bool get usesSqlite => repository is SqliteContentRepository;

  static Future<LocalContentRuntime> open({
    Directory? supportDirectory,
    File? importFile,
    bool useLegacy = false,
  }) async {
    final legacy = LegacyManifestContentRepository();
    if (useLegacy) return LocalContentRuntime._(legacy, null);
    SqliteContentRepository? sql;
    try {
      final directory =
          supportDirectory ?? await getApplicationSupportDirectory();
      await directory.create(recursive: true);
      final store = LocalPackStore(Directory(p.join(directory.path, 'packs')));
      // An explicit developer seed is optional on subsequent offline restarts.
      if (importFile != null && await importFile.exists()) {
        await store.install(importFile);
      }
      final installed = await store.readAllInstalled();
      if (installed.isEmpty) return LocalContentRuntime._(legacy, store);
      final topics = <String, Topic>{};
      for (final local in installed) {
        final topic = local.manifest.topic;
        final previous = topics[topic.id];
        // Display names are labels, not identity. Different Topic or Pack IDs
        // may share a name; only conflicting metadata for the same ID is invalid.
        if (previous != null && previous != topic) {
          throw const FormatException('Conflicting installed Topic metadata');
        }
        topics[topic.id] = topic;
      }
      sql = SqliteContentRepository.open(p.join(directory.path, databaseName));
      sql.replaceInstalledContent(
        topics: topics.values,
        packs: installed.map((local) => local.manifest.pack),
        cards: installed.expand((local) => local.cards),
        projectedAt: DateTime.now().toUtc(),
      );
      return LocalContentRuntime._(sql, store);
    } catch (error) {
      sql?.close();
      // Never delete/repair source generations or a failed database to recover.
      return LocalContentRuntime._(legacy, null, error);
    }
  }

  void close() {
    final local = repository;
    if (local is SqliteContentRepository) local.close();
  }
}

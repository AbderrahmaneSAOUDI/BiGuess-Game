import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/topic_pack_data_source.dart';
import '../data/local/local_content_runtime.dart';
import '../data/repositories/legacy_manifest_content_repository.dart';
import '../domain/models/card.dart';
import '../domain/models/game_setup.dart';
import '../domain/models/pack.dart';
import '../domain/repositories/content_repository.dart';

final topicPackDataSourceProvider = Provider<TopicPackDataSource>((ref) {
  return const TopicPackDataSource();
});

/// main supplies the opened runtime and closes it when its root scope ends.
final localContentRuntimeProvider = Provider<LocalContentRuntime?>(
  (ref) => null,
);

/// Local-Pack play and the explicit offline demo never start update requests.
/// Manual update actions remain available outside the gameplay flow.
final automaticUpdateChecksProvider = Provider<bool>((ref) {
  return !const bool.fromEnvironment('biguessOfflineDemo') &&
      !(ref.watch(localContentRuntimeProvider)?.usesSqlite ?? false);
});

/// Override this binding to swap local content sources without screen changes.
final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final local = ref.watch(localContentRuntimeProvider);
  if (local != null) return local.repository;
  return LegacyManifestContentRepository(
    dataSource: ref.watch(topicPackDataSourceProvider),
  );
});

// Preserve the existing name-based screen/round keys during the migration.
// Only this compatibility layer resolves names; repositories use canonical IDs.
final _packsForTopicProvider = Provider.family<List<Pack>, String>((
  ref,
  topicName,
) {
  final repository = ref.watch(contentRepositoryProvider);
  for (final topic in repository.getTopics()) {
    if (topic.name == topicName) {
      return repository.getPacksForTopic(topic.id);
    }
  }
  return const [];
});

final packCardsProvider =
    Provider.family<List<Card>, ({String topic, String pack})>((ref, key) {
      final repository = ref.watch(contentRepositoryProvider);
      final packs = ref.watch(_packsForTopicProvider(key.topic));
      for (final pack in packs) {
        if (pack.name == key.pack) {
          return repository.getCardsForPack(pack.id);
        }
      }
      return const [];
    });

/// Setup must use verified local content rather than cached catalog Cards.
final gameSetupContentProvider =
    Provider.family<GameSetupContent?, ({String topic, String pack})>((
      ref,
      key,
    ) {
      final repository = ref.watch(contentRepositoryProvider);
      for (final topic in repository.getTopics()) {
        if (topic.name != key.topic || topic.deleted) continue;
        for (final pack in repository.getPacksForTopic(topic.id)) {
          if (pack.name == key.pack && !pack.deleted) {
            return GameSetupContent(
              topic: topic,
              pack: pack,
              installedCards: repository.getInstalledCardsForPack(pack.id),
            );
          }
        }
      }
      return null;
    });

/// All available topic names
final topicsProvider = Provider<List<String>>((ref) {
  return ref
      .watch(contentRepositoryProvider)
      .getTopics()
      .map((topic) => topic.name)
      .toList(growable: false);
});

/// Pack names for a given topic
final packsProvider = Provider.family<List<String>, String>((ref, topicName) {
  return ref
      .watch(_packsForTopicProvider(topicName))
      .map((pack) => pack.name)
      .toList(growable: false);
});

/// Asset paths for a given topic+pack combo
final packAssetsProvider =
    Provider.family<List<String>, ({String topic, String pack})>((ref, key) {
      return ref
          .watch(packCardsProvider(key))
          .map((card) => card.imageReference)
          .toList(growable: false);
    });

/// Total asset count across all packs for a topic
final topicAssetCountProvider = Provider.family<int, String>((ref, topicName) {
  final repository = ref.watch(contentRepositoryProvider);
  return ref
      .watch(_packsForTopicProvider(topicName))
      .fold<int>(
        0,
        (total, pack) => total + repository.getCardsForPack(pack.id).length,
      );
});

/// Asset count for a specific pack
final packAssetCountProvider =
    Provider.family<int, ({String topic, String pack})>((ref, key) {
      return ref.watch(packCardsProvider(key)).length;
    });

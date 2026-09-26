import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/topic_pack_data_source.dart';

final topicPackDataSourceProvider = Provider<TopicPackDataSource>((ref) {
  return const TopicPackDataSource();
});

/// All available topic names
final topicsProvider = Provider<List<String>>((ref) {
  return ref.watch(topicPackDataSourceProvider).getTopics();
});

/// Pack names for a given topic
final packsProvider = Provider.family<List<String>, String>((ref, topicName) {
  return ref.watch(topicPackDataSourceProvider).getPacksForTopic(topicName);
});

/// Asset paths for a given topic+pack combo
final packAssetsProvider =
    Provider.family<List<String>, ({String topic, String pack})>((ref, key) {
  return ref
      .watch(topicPackDataSourceProvider)
      .getAssetsForPack(key.topic, key.pack);
});

/// Total asset count across all packs for a topic
final topicAssetCountProvider = Provider.family<int, String>((ref, topicName) {
  return ref
      .watch(topicPackDataSourceProvider)
      .getTotalAssetsForTopic(topicName);
});

/// Asset count for a specific pack
final packAssetCountProvider =
    Provider.family<int, ({String topic, String pack})>((ref, key) {
  return ref
      .watch(topicPackDataSourceProvider)
      .getAssetCountForPack(key.topic, key.pack);
});

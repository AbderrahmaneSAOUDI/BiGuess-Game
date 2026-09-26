import '../../assets_manifest.dart' as manifest;

/// Data source providing topic → pack → asset hierarchy from the generated manifest
class TopicPackDataSource {
  const TopicPackDataSource();

  /// Returns all topic names
  List<String> getTopics() {
    return manifest.topicPackAssets.keys.toList();
  }

  /// Returns pack names for a given topic
  List<String> getPacksForTopic(String topicName) {
    return manifest.topicPackAssets[topicName]?.keys.toList() ?? [];
  }

  /// Returns all asset paths for a given topic + pack
  List<String> getAssetsForPack(String topicName, String packName) {
    return manifest.topicPackAssets[topicName]?[packName] ?? [];
  }

  /// Returns the total number of assets across all packs in a topic
  int getTotalAssetsForTopic(String topicName) {
    final packs = manifest.topicPackAssets[topicName];
    if (packs == null) return 0;
    return packs.values.fold<int>(0, (sum, list) => sum + list.length);
  }

  /// Returns the number of assets in a specific pack
  int getAssetCountForPack(String topicName, String packName) {
    return manifest.topicPackAssets[topicName]?[packName]?.length ?? 0;
  }
}

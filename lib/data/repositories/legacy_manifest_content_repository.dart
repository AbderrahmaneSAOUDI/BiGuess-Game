import '../../core/utils/asset_loader.dart';
import '../../domain/models/card.dart';
import '../../domain/models/difficulty.dart';
import '../../domain/models/pack.dart';
import '../../domain/models/topic.dart';
import '../../domain/repositories/content_repository.dart';
import '../datasources/topic_pack_data_source.dart';

/// Adapts the bundled manifest to canonical content without changing its order,
/// labels, or image paths. The manifest has no difficulty data, so Cards are Easy.
/// Default draft metadata does not assert permission to publish legacy content.
///
/// Legacy IDs encode source keys, not list indexes, and are stable across rebuilds
/// and reordering. Renaming/moving a source requires an explicit migration mapping;
/// these IDs are not a replacement for persistent IDs from a future content store.
final class LegacyManifestContentRepository implements ContentRepository {
  final List<Topic> _topics;
  final Map<String, List<Pack>> _packsByTopicId;
  final Map<String, List<Card>> _cardsByPackId;

  factory LegacyManifestContentRepository({
    TopicPackDataSource dataSource = const TopicPackDataSource(),
  }) {
    final topics = <Topic>[];
    final packsByTopicId = <String, List<Pack>>{};
    final cardsByPackId = <String, List<Card>>{};

    for (final topicName in dataSource.getTopics()) {
      final topicKey = Uri.encodeComponent(topicName);
      final topic = Topic(id: 'legacy:topic:$topicKey', name: topicName);
      topics.add(topic);
      final packs = <Pack>[];
      for (final packName in dataSource.getPacksForTopic(topicName)) {
        final packKey = '$topicKey:${Uri.encodeComponent(packName)}';
        final pack = Pack(
          id: 'legacy:pack:$packKey',
          topicId: topic.id,
          name: packName,
        );
        packs.add(pack);
        cardsByPackId[pack.id] = List<Card>.unmodifiable(
          dataSource
              .getAssetsForPack(topicName, packName)
              .map(
                (asset) => Card(
                  id: 'legacy:card:$packKey:${Uri.encodeComponent(asset)}',
                  packId: pack.id,
                  name: AssetLoader.extractCharacterName(asset) ?? '',
                  imageReference: asset,
                  difficulty: Difficulty.easy,
                ),
              ),
        );
      }
      packsByTopicId[topic.id] = List<Pack>.unmodifiable(packs);
    }

    return LegacyManifestContentRepository._(
      List<Topic>.unmodifiable(topics),
      Map<String, List<Pack>>.unmodifiable(packsByTopicId),
      Map<String, List<Card>>.unmodifiable(cardsByPackId),
    );
  }

  const LegacyManifestContentRepository._(
    this._topics,
    this._packsByTopicId,
    this._cardsByPackId,
  );

  @override
  List<Topic> getTopics() => _topics;

  @override
  List<Pack> getPacksForTopic(String topicId) =>
      _packsByTopicId[topicId] ?? const [];

  @override
  List<Card> getCardsForPack(String packId) =>
      _cardsByPackId[packId] ?? const [];

  @override
  List<Card>? getInstalledCardsForPack(String packId) => _cardsByPackId[packId];
}

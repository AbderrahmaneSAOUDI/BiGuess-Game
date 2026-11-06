import '../models/card.dart';
import '../models/pack.dart';
import '../models/topic.dart';

/// Read-only, synchronous access to locally available content without network
/// calls. Callers materialize an in-memory image pool before drawing Cards.
/// Implementations preserve catalog order and return immutable lists; unknown
/// parent IDs return empty lists. Publication/install policy is separate.
abstract interface class ContentRepository {
  List<Topic> getTopics();

  List<Pack> getPacksForTopic(String topicId);

  List<Card> getCardsForPack(String packId);

  /// Null means unavailable locally; an empty list is an installed empty Pack.
  /// Bundled Packs count as local content. Cached catalog Cards alone do not.
  /// Returns the installed revision, which may differ from cached metadata.
  List<Card>? getInstalledCardsForPack(String packId);
}

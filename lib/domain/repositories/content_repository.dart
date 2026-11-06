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
}

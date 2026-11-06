import 'card.dart';
import 'pack.dart';
import 'topic.dart';

/// Structural validation only. Publication, local installation, difficulty
/// filtering, and eligibility for a new game are separate policies.
class ContentValidator {
  ContentValidator._();

  /// Validates a complete content set, including empty/in-progress draft Packs.
  /// IDs must be unique within each entity type and every parent must exist.
  static void validateRelations({
    required Iterable<Topic> topics,
    required Iterable<Pack> packs,
    required Iterable<Card> cards,
  }) {
    final topicIds = <String>{};
    for (final topic in topics) {
      _addId(topicIds, topic.id, 'Topic');
    }
    final packIds = <String>{};
    for (final pack in packs) {
      _addId(packIds, pack.id, 'Pack');
      if (!topicIds.contains(pack.topicId)) {
        throw ArgumentError(
          'Pack ${pack.id} has unknown Topic ${pack.topicId}',
        );
      }
    }
    final cardIds = <String>{};
    for (final card in cards) {
      _addId(cardIds, card.id, 'Card');
      if (!packIds.contains(card.packId)) {
        throw ArgumentError('Card ${card.id} has unknown Pack ${card.packId}');
      }
    }
  }

  /// A playable Pack needs at least two distinct Cards, all belonging to it.
  /// Pass the Pack's own Cards, not a catalog-wide list.
  static void validatePlayablePack({
    required Pack pack,
    required Iterable<Card> cards,
  }) {
    final cardIds = <String>{};
    for (final card in cards) {
      _addId(cardIds, card.id, 'Card');
      if (card.packId != pack.id) {
        throw ArgumentError(
          'Card ${card.id} does not belong to Pack ${pack.id}',
        );
      }
    }
    if (cardIds.length < 2) {
      throw ArgumentError(
        'Pack ${pack.id} needs at least 2 Cards to be playable',
      );
    }
  }

  static void _addId(Set<String> ids, String id, String entity) {
    if (!ids.add(id)) {
      throw ArgumentError('Duplicate $entity ID: $id');
    }
  }
}

import 'dart:math';

import '../models/card.dart';
import '../models/content_validator.dart';
import '../models/pack.dart';
import '../models/pack_selection.dart';
import '../repositories/content_repository.dart';

enum PackAvailability { playable, downloadRequired, unavailable }

final class PackOption {
  final Pack pack;
  final PackAvailability availability;
  final List<Card> cards;

  PackOption(this.pack, this.availability, [Iterable<Card> cards = const []])
    : cards = List.unmodifiable(cards);
}

/// Frozen content handed to setup/reveal, independent of later catalog edits.
final class PackCardPool {
  final String topicId;
  final List<Pack> packs;
  final List<Card> cards;

  PackCardPool(this.topicId, Iterable<Pack> packs, Iterable<Card> cards)
    : packs = List.unmodifiable(packs),
      cards = List.unmodifiable(cards);
}

final class PackSelectionException implements Exception {
  final String message;
  const PackSelectionException(this.message);
}

/// Resolves IDs, validates one Topic and materializes installed Cards before play.
/// Publication/unlisting policy for existing copies belongs to the content source.
final class SelectPacksUseCase {
  final ContentRepository repository;
  final Random _random;

  SelectPacksUseCase(this.repository, {Random? random})
    : _random = random ?? Random();

  List<PackOption> options(String topicId) {
    final topics = repository.getTopics().where((t) => t.id == topicId);
    if (topics.isEmpty) return const [];
    final topic = topics.single;
    return List.unmodifiable(
      repository.getPacksForTopic(topicId).map((pack) {
        if (topic.deleted || pack.deleted || pack.topicId != topicId) {
          return PackOption(pack, PackAvailability.unavailable);
        }
        final cards = repository.getInstalledCardsForPack(pack.id);
        if (cards == null) {
          return PackOption(
            pack,
            topic.published && pack.published
                ? PackAvailability.downloadRequired
                : PackAvailability.unavailable,
          );
        }
        try {
          ContentValidator.validatePlayablePack(pack: pack, cards: cards);
        } on ArgumentError {
          return PackOption(pack, PackAvailability.unavailable);
        }
        return PackOption(pack, PackAvailability.playable, cards);
      }),
    );
  }

  PackCardPool call(PackSelection selection) {
    final eligible = {
      for (final option in options(selection.topicId))
        if (option.availability == PackAvailability.playable)
          option.pack.id: option,
    };
    final List<PackOption> selected;
    if (selection.mode == PackSelectionMode.random) {
      if (eligible.isEmpty) {
        throw const PackSelectionException(
          'No locally playable packs available.',
        );
      }
      final shuffled = eligible.values.toList()..shuffle(_random);
      selected = shuffled.take(selection.randomCount).toList();
    } else {
      if (selection.packIds.isEmpty) {
        throw const PackSelectionException(
          'Select at least one playable pack.',
        );
      }
      selected = selection.packIds.map((id) {
        final option = eligible[id];
        if (option == null) {
          throw const PackSelectionException(
            'Selected packs must be locally playable and belong to this Topic.',
          );
        }
        return option;
      }).toList();
    }
    final cards = <Card>[];
    final ids = <String>{};
    for (final option in selected) {
      for (final card in option.cards) {
        if (!ids.add(card.id)) {
          throw const PackSelectionException(
            'Selected packs contain duplicate Card IDs.',
          );
        }
        cards.add(card);
      }
    }
    return PackCardPool(
      selection.topicId,
      selected.map((option) => option.pack),
      cards,
    );
  }
}

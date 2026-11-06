import 'dart:math';

import '../models/card.dart';
import '../models/difficulty.dart';

/// A local, non-repeating deck for one device's game.
///
/// Callers supply Cards from the selected local Packs. Construction captures
/// unique IDs at or below the configured difficulty. Later content changes
/// cannot alter the deck. Names and image references never affect selection.
///
/// Each instance owns its draw history. Devices may draw the same ID, and an ID
/// may repeat across cycle boundaries after the previous deck is exhausted.
final class CardSelectionEngine {
  /// Immutable eligible IDs, available for validating an empty configuration.
  final List<String> eligibleCardIds;

  final Random _random;
  final List<String> _remainingCardIds = [];

  CardSelectionEngine({
    required Iterable<Card> cards,
    Difficulty difficulty = Difficulty.easy,
    Random? random,
  }) : eligibleCardIds = List<String>.unmodifiable({
         for (final card in cards)
           if (card.difficulty.value <= difficulty.value) card.id,
       }),
       _random = random ?? Random();

  /// Draws without replacement, shuffling a fresh deck after exhaustion.
  /// Returns null when no Cards match the configured difficulty.
  String? draw() {
    if (eligibleCardIds.isEmpty) return null;

    if (_remainingCardIds.isEmpty) {
      _remainingCardIds.addAll(eligibleCardIds);
      _remainingCardIds.shuffle(_random);
    }

    return _remainingCardIds.removeLast();
  }
}

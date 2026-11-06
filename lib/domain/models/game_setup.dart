import 'card.dart';
import 'difficulty.dart';
import 'entitlement.dart';
import 'game_session_configuration.dart';
import 'game_session.dart';
import 'pack.dart';
import 'topic.dart';

enum GameSetupError {
  invalidRounds,
  freeRoundLimit,
  packNotInstalled,
  emptyEligiblePool,
}

/// A draft may be invalid while the player edits the round field.
final class GameSetup {
  final Difficulty maximumDifficulty;
  final int rounds;

  const GameSetup({
    this.maximumDifficulty = Difficulty.easy,
    this.rounds = Entitlement.freeRoundLimit,
  });

  List<Card> eligibleCards(Iterable<Card> cards) => List.unmodifiable(
    cards.where((card) => card.difficulty.value <= maximumDifficulty.value),
  );

  GameSetupError? validate({
    required Entitlement entitlement,
    required GameSetupContent? content,
  }) {
    if (rounds <= 0) return GameSetupError.invalidRounds;
    if (!entitlement.allowsRounds(rounds)) return GameSetupError.freeRoundLimit;
    if (content == null || content.installedCards == null) {
      return GameSetupError.packNotInstalled;
    }
    if (eligibleCards(content.installedCards!).isEmpty) {
      return GameSetupError.emptyEligiblePool;
    }
    return null;
  }

  GameContentSnapshot freeze({
    required Entitlement entitlement,
    required GameSetupContent? content,
  }) {
    final error = validate(entitlement: entitlement, content: content);
    if (error != null) throw StateError('Invalid game setup: $error');
    return GameContentSnapshot.capture(
      configuration: GameSessionConfiguration(
        topicId: content!.topic.id,
        packIds: [content.pack.id],
        maximumDifficulty: maximumDifficulty,
        rounds: rounds,
        isPro: entitlement.isProTestEnabled,
      ),
      topic: content.topic,
      installedPacks: [content.pack],
      installedCards: content.installedCards!,
    );
  }
}

/// Catalog identity plus the verified installed revision, if one exists.
final class GameSetupContent {
  final Topic topic;
  final Pack pack;
  final List<Card>? installedCards;

  GameSetupContent({
    required this.topic,
    required this.pack,
    required List<Card>? installedCards,
  }) : installedCards = installedCards == null
           ? null
           : List.unmodifiable(installedCards);
}

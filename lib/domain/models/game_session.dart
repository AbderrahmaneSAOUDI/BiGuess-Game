import 'card.dart';
import 'game_session_configuration.dart';
import 'pack.dart';
import 'topic.dart';

enum GameSessionPhase { home, configuring, active, completed, exited }

enum GameReplayRoute { home, game }

/// A detached copy of selected installed content, captured once on Start.
///
/// The caller supplies verified, playable installed revisions, never newer
/// cached catalog Cards. Installation and unpublished-content availability
/// policy belong to the content layer. Published flags are not checked during
/// play. Image generations must remain available until gameplay is exited;
/// retaining their immutable references does not itself prevent file deletion.
final class GameContentSnapshot {
  final GameSessionConfiguration configuration;
  final Topic topic;
  final List<Pack> packs;
  final List<Card> cards;

  GameContentSnapshot._({
    required this.configuration,
    required this.topic,
    required Iterable<Pack> packs,
    required Iterable<Card> cards,
  }) : packs = List.unmodifiable(packs),
       cards = List.unmodifiable(cards);

  factory GameContentSnapshot.capture({
    required GameSessionConfiguration configuration,
    required Topic topic,
    required Iterable<Pack> installedPacks,
    required Iterable<Card> installedCards,
  }) {
    if (topic.id != configuration.topicId || topic.deleted) {
      throw ArgumentError('The selected Topic is unavailable');
    }
    final selectedIds = configuration.packIds.toSet();
    final selectedPacks = <String, Pack>{};
    for (final pack in installedPacks) {
      if (!selectedIds.contains(pack.id)) continue;
      if (pack.topicId != topic.id || pack.deleted) {
        throw ArgumentError(
          'Selected Packs must belong to the available Topic',
        );
      }
      if (selectedPacks.containsKey(pack.id)) {
        throw ArgumentError('Duplicate installed Pack ID: ${pack.id}');
      }
      selectedPacks[pack.id] = pack;
    }
    if (selectedPacks.length != selectedIds.length) {
      throw ArgumentError('Every selected Pack must be installed');
    }
    final cards = <Card>[];
    final cardIds = <String>{};
    for (final card in installedCards) {
      if (!selectedIds.contains(card.packId)) continue;
      if (!cardIds.add(card.id)) {
        throw ArgumentError('Duplicate installed Card ID: ${card.id}');
      }
      if (card.difficulty.value <= configuration.maximumDifficulty.value) {
        cards.add(card);
      }
    }
    if (cards.isEmpty) {
      throw ArgumentError('No installed Cards match the configuration');
    }
    return GameContentSnapshot._(
      configuration: configuration,
      topic: topic,
      packs: configuration.packIds.map((id) => selectedPacks[id]!),
      cards: cards,
    );
  }
}

/// Immutable, temporary session state. Round indexes are zero-based; the
/// presentation-facing roundNumber is one-based during play and completion.
final class GameSession {
  final GameSessionPhase phase;
  final GameSessionConfiguration? configuration;
  final GameContentSnapshot? snapshot;
  final int? roundIndex;
  final Card? assignedCard;

  const GameSession.home()
    : phase = GameSessionPhase.home,
      configuration = null,
      snapshot = null,
      roundIndex = null,
      assignedCard = null;

  const GameSession.configuring(GameSessionConfiguration this.configuration)
    : phase = GameSessionPhase.configuring,
      snapshot = null,
      roundIndex = null,
      assignedCard = null;

  GameSession.active({
    required GameContentSnapshot snapshot,
    required int roundIndex,
    required Card assignedCard,
  }) : phase = GameSessionPhase.active,
       configuration = snapshot.configuration,
       snapshot = snapshot,
       roundIndex = roundIndex,
       assignedCard = assignedCard {
    if (roundIndex < 0 || roundIndex >= configuration!.rounds) {
      throw RangeError.range(roundIndex, 0, configuration!.rounds - 1);
    }
    if (!snapshot.cards.contains(assignedCard)) {
      throw ArgumentError('Assigned Card must come from the session snapshot');
    }
  }

  GameSession.completed(GameContentSnapshot this.snapshot)
    : phase = GameSessionPhase.completed,
      configuration = snapshot.configuration,
      roundIndex = snapshot.configuration.rounds - 1,
      assignedCard = null;

  const GameSession.exited()
    : phase = GameSessionPhase.exited,
      configuration = null,
      snapshot = null,
      roundIndex = null,
      assignedCard = null;

  int get roundNumber => roundIndex == null ? 0 : roundIndex! + 1;

  int get completedRounds => switch (phase) {
    GameSessionPhase.active => roundIndex!,
    GameSessionPhase.completed => configuration!.rounds,
    _ => 0,
  };

  /// Completion stays in the gameplay flow, including Pro replay. Storage may
  /// release the referenced image generations only after exit/returnHome.
  bool get retainsContent => snapshot != null;
}

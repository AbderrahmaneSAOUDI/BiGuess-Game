import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/card.dart';
import '../domain/models/game_session_configuration.dart';
import '../domain/models/game_session.dart';
import '../domain/models/pack.dart';
import '../domain/models/topic.dart';
import '../domain/use_cases/card_selection_engine.dart';

/// Owns only in-memory session transitions. There are deliberately no watched
/// content/settings/entitlement dependencies: background changes cannot rebuild
/// an active session. Content is supplied once, before the first local draw.
class GameSessionNotifier extends Notifier<GameSession> {
  final Random _random;
  CardSelectionEngine? _selection;

  GameSessionNotifier({Random? random}) : _random = random ?? Random();

  @override
  GameSession build() => const GameSession.home();

  void configure(GameSessionConfiguration configuration) {
    if (state.phase != GameSessionPhase.home &&
        state.phase != GameSessionPhase.configuring) {
      throw StateError('Return to Home before configuring another game');
    }
    state = GameSession.configuring(configuration);
  }

  void start({
    required Topic topic,
    required Iterable<Pack> installedPacks,
    required Iterable<Card> installedCards,
  }) {
    _requirePhase(GameSessionPhase.configuring);
    // Validate everything before changing state or assigning a Card.
    final snapshot = GameContentSnapshot.capture(
      configuration: state.configuration!,
      topic: topic,
      installedPacks: installedPacks,
      installedCards: installedCards,
    );
    _start(snapshot);
  }

  /// Finishes the displayed round. Finishing the configured last round
  /// completes the session without assigning an extra Card.
  void nextRound() {
    _requirePhase(GameSessionPhase.active);
    final snapshot = state.snapshot!;
    final nextIndex = state.roundIndex! + 1;
    if (nextIndex == snapshot.configuration.rounds) {
      _selection = null;
      state = GameSession.completed(snapshot);
      return;
    }
    state = GameSession.active(
      snapshot: snapshot,
      roundIndex: nextIndex,
      assignedCard: _draw(snapshot),
    );
  }

  /// Free replay requests navigation only: the session remains completed until
  /// the router reports arrival at Home via returnHome(). Pro restarts locally
  /// with the exact frozen configuration/content, without consulting storage.
  GameReplayRoute requestReplay() {
    _requirePhase(GameSessionPhase.completed);
    if (!state.configuration!.isPro) return GameReplayRoute.home;
    _start(state.snapshot!);
    return GameReplayRoute.game;
  }

  /// Safe at any point, including setup and repeated back/exit actions. No
  /// retained content or draw state can be resumed after leaving gameplay.
  void exit() {
    if (state.phase == GameSessionPhase.home ||
        state.phase == GameSessionPhase.exited) {
      return;
    }
    _selection = null;
    state = const GameSession.exited();
  }

  /// Called when navigation reaches Home. This is the explicit boundary that
  /// clears the per-game counter and permits a fresh Free configuration.
  void returnHome() {
    _selection = null;
    state = const GameSession.home();
  }

  void _start(GameContentSnapshot snapshot) {
    _selection = CardSelectionEngine(
      cards: snapshot.cards,
      difficulty: snapshot.configuration.maximumDifficulty,
      random: _random,
    );
    state = GameSession.active(
      snapshot: snapshot,
      roundIndex: 0,
      assignedCard: _draw(snapshot),
    );
  }

  Card _draw(GameContentSnapshot snapshot) {
    final id = _selection!.draw();
    return snapshot.cards.firstWhere((card) => card.id == id);
  }

  void _requirePhase(GameSessionPhase phase) {
    if (state.phase != phase) {
      throw StateError('Expected $phase, got ${state.phase}');
    }
  }
}

/// Kept alive across configuration/game/completion routes in one ProviderScope.
/// A new scope/process starts at Home; no active session is persisted.
final gameSessionProvider = NotifierProvider<GameSessionNotifier, GameSession>(
  GameSessionNotifier.new,
);

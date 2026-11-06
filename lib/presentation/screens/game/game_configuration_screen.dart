import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/difficulty.dart';
import '../../../domain/models/entitlement.dart';
import '../../../domain/models/game_setup.dart';
import '../../../providers/entitlement_provider.dart';
import '../../../providers/game_session_controller.dart';
import '../../../providers/game_settings_controller.dart';
import '../../../providers/topic_pack_providers.dart';
import 'game_screen.dart';

/// Short setup step for the selected locally available Pack.
class GameConfigurationScreen extends ConsumerStatefulWidget {
  final String topicName;
  final String packName;

  const GameConfigurationScreen({
    super.key,
    required this.topicName,
    required this.packName,
  });

  @override
  ConsumerState<GameConfigurationScreen> createState() =>
      _GameConfigurationScreenState();
}

class _GameConfigurationScreenState
    extends ConsumerState<GameConfigurationScreen> {
  final _roundsController = TextEditingController(
    text: '${Entitlement.freeRoundLimit}',
  );
  Difficulty _difficulty = Difficulty.easy;
  bool _starting = false;

  ({String topic, String pack}) get _key =>
      (topic: widget.topicName, pack: widget.packName);

  GameSetup get _setup => GameSetup(
    maximumDifficulty: _difficulty,
    rounds: int.tryParse(_roundsController.text.trim()) ?? 0,
  );

  @override
  void dispose() {
    _roundsController.dispose();
    super.dispose();
  }

  void _start() {
    // Re-read at the tap boundary, including entitlement/local availability.
    final setup = _setup;
    final entitlement = ref.read(entitlementProvider);
    ref.invalidate(gameSetupContentProvider(_key));
    final content = ref.read(gameSetupContentProvider(_key));
    if (_starting ||
        setup.validate(entitlement: entitlement, content: content) != null) {
      return;
    }
    final snapshot = setup.freeze(entitlement: entitlement, content: content);
    final session = ref.read(gameSessionProvider.notifier);
    session.configure(snapshot.configuration);
    session.start(
      topic: snapshot.topic,
      installedPacks: snapshot.packs,
      installedCards: snapshot.cards,
    );
    ref.read(showCharacterNameHintProvider.notifier).set(false);
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _starting = true);
    // Replace setup so Back exits to Packs rather than editing a running game.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => GameScreen(
          topicName: widget.topicName,
          packName: widget.packName,
          useSession: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entitlement = ref.watch(entitlementProvider);
    final content = ref.watch(gameSetupContentProvider(_key));
    final setup = _setup;
    final error = setup.validate(entitlement: entitlement, content: content);
    final errorText = switch (error) {
      GameSetupError.invalidRounds => 'Enter a positive whole number.',
      GameSetupError.freeRoundLimit => 'Free games allow up to 10 rounds.',
      GameSetupError.packNotInstalled =>
        'Download at least one Pack before starting.',
      GameSetupError.emptyEligiblePool =>
        'No cards match this difficulty. Choose a higher difficulty or another Pack.',
      null => null,
    };
    final roundsError =
        error == GameSetupError.invalidRounds ||
        error == GameSetupError.freeRoundLimit;
    final eligibleCount = setup
        .eligibleCards(content?.installedCards ?? [])
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Game Setup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.topicName,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.packName.replaceAll('_', ' '),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 28),
                  DropdownButtonFormField<Difficulty>(
                    initialValue: _difficulty,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    items: const [
                      DropdownMenuItem(
                        value: Difficulty.easy,
                        child: Text('Easy'),
                      ),
                      DropdownMenuItem(
                        value: Difficulty.medium,
                        child: Text('Medium'),
                      ),
                      DropdownMenuItem(
                        value: Difficulty.hard,
                        child: Text('Hard'),
                      ),
                    ],
                    onChanged: _starting
                        ? null
                        : (value) => setState(() => _difficulty = value!),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Easy: Easy cards\nMedium: Easy + Medium\nHard: Easy + Medium + Hard',
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _roundsController,
                    enabled: !_starting,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Number of rounds',
                      helperText: entitlement.maxRounds == null
                          ? 'Choose any positive number of rounds.'
                          : '1–10 rounds per game',
                      errorText: roundsError ? errorText : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  Text('$eligibleCount eligible cards'),
                  if (errorText != null && !roundsError) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorText,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: error == null && !_starting ? _start : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Game'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

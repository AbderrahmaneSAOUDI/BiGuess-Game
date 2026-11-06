import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/game_setup.dart';
import '../../../domain/models/pack_selection.dart';
import '../../../domain/use_cases/select_packs_use_case.dart';
import '../../../providers/pack_selection_controller.dart';
import '../../../providers/topic_pack_providers.dart';
import '../game/game_configuration_screen.dart';

/// Resolve random choices once, then keep their IDs fixed throughout setup.
/// Availability is rechecked by setup before freezing the active game's pool.
class SelectedPacksSetup extends StatelessWidget {
  final PackCardPool pool;
  final String topicName;

  const SelectedPacksSetup({
    super.key,
    required this.pool,
    required this.topicName,
  });

  @override
  Widget build(BuildContext context) {
    final label = pool.packs.length == 1
        ? pool.packs.single.name
        : '${pool.packs.length} selected packs';
    final selection = PackSelection(
      topicId: pool.topicId,
      mode: pool.packs.length == 1
          ? PackSelectionMode.single
          : PackSelectionMode.multiple,
      packIds: pool.packs.map((pack) => pack.id),
    );
    return ProviderScope(
      overrides: [
        gameSetupContentProvider((topic: topicName, pack: label)).overrideWith((
          ref,
        ) {
          final repository = ref.watch(contentRepositoryProvider);
          final topics = repository.getTopics().where(
            (t) => t.id == pool.topicId,
          );
          if (topics.isEmpty) return null;
          try {
            final selected = ref.watch(selectPacksUseCaseProvider)(selection);
            return GameSetupContent.selectedPacks(
              topic: topics.single,
              packs: selected.packs,
              installedCards: selected.cards,
            );
          } on PackSelectionException {
            return null;
          }
        }),
      ],
      child: GameConfigurationScreen(topicName: topicName, packName: label),
    );
  }
}

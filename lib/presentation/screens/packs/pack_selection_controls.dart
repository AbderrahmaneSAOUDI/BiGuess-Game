import 'package:flutter/material.dart';

import '../../../domain/models/pack_selection.dart';

class PackSelectionControls extends StatelessWidget {
  final PackSelection selection;
  final int playableCount;
  final int selectedCount;
  final ValueChanged<PackSelectionMode> onModeChanged;
  final ValueChanged<int> onRandomCountChanged;
  final VoidCallback onContinue;

  const PackSelectionControls({
    super.key,
    required this.selection,
    required this.playableCount,
    required this.selectedCount,
    required this.onModeChanged,
    required this.onRandomCountChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final random = selection.mode == PackSelectionMode.random;
    final randomCount = playableCount == 0
        ? 0
        : selection.randomCount.clamp(1, playableCount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final mode in PackSelectionMode.values)
              ChoiceChip(
                label: Text(switch (mode) {
                  PackSelectionMode.single => 'Single',
                  PackSelectionMode.multiple => 'Multiple',
                  PackSelectionMode.random => 'Random',
                }),
                selected: selection.mode == mode,
                onSelected: (_) => onModeChanged(mode),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (playableCount == 0)
          const Text('No locally playable packs available in this Topic.')
        else
          Text(switch (selection.mode) {
            PackSelectionMode.single => 'Tap one pack to continue.',
            PackSelectionMode.multiple =>
              '$selectedCount packs selected in this Topic.',
            PackSelectionMode.random =>
              'Choose from $playableCount locally playable packs in this Topic.',
          }),
        if (random) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Random packs'),
              const Spacer(),
              IconButton(
                tooltip: 'Fewer random packs',
                onPressed: randomCount > 1
                    ? () => onRandomCountChanged(randomCount - 1)
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Text('$randomCount', key: const ValueKey('random-pack-count')),
              IconButton(
                tooltip: 'More random packs',
                onPressed: randomCount < playableCount
                    ? () => onRandomCountChanged(randomCount + 1)
                    : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
        if (selection.mode != PackSelectionMode.single) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('packs-continue'),
            onPressed:
                (random
                    ? playableCount > 0
                    : selectedCount > 0 &&
                          selectedCount == selection.packIds.length)
                ? onContinue
                : null,
            icon: Icon(
              random ? Icons.shuffle_rounded : Icons.play_arrow_rounded,
            ),
            label: Text(
              random
                  ? 'Continue with $randomCount random ${randomCount == 1 ? 'pack' : 'packs'}'
                  : 'Continue with $selectedCount selected ${selectedCount == 1 ? 'pack' : 'packs'}',
            ),
          ),
        ],
      ],
    );
  }
}

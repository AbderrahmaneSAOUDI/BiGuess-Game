import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../controllers/game_settings_controller.dart';
import '../../../widgets/animations/animated_character_card.dart';

/// Responsive layout container for displaying the revealed anime character card
class GameCharacterDisplay extends ConsumerWidget {
  final String imageAsset;
  final String? characterName;

  const GameCharacterDisplay({
    super.key,
    required this.imageAsset,
    this.characterName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showNameHint = ref.watch(showCharacterNameHintProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool hasName = characterName != null && showNameHint;
        final double nameReservedHeight = hasName ? 54.0 : 0.0;

        // Utilize flexible height while constraining width to 80% of available width
        final double availableHeight = max(
          0.0,
          constraints.maxHeight - nameReservedHeight - 6.0,
        );
        final double effectiveContainerWidth =
            constraints.maxWidth > 0 ? constraints.maxWidth : 360.0;
        final double availableWidth = effectiveContainerWidth * 0.80;

        return AnimatedCharacterCard(
          key: ValueKey(imageAsset),
          imageAsset: imageAsset,
          characterName: characterName,
          showNameHint: showNameHint,
          maxWidth: availableWidth,
          maxHeight: availableHeight,
        );
      },
    );
  }
}

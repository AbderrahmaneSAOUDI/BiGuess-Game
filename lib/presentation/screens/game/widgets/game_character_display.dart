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
        final double screenWidth = MediaQuery.of(context).size.width;
        final bool hasName = characterName != null && showNameHint;
        final double nameReservedHeight = hasName ? 72.0 : 0.0;
        final double availableHeight = max(
          0.0,
          constraints.maxHeight - nameReservedHeight - 12.0,
        );

        final double targetWidth = screenWidth * 0.75;
        final double maxImageHeight = availableHeight;

        return AnimatedCharacterCard(
          key: ValueKey(imageAsset),
          imageAsset: imageAsset,
          characterName: characterName,
          showNameHint: showNameHint,
          maxWidth: targetWidth,
          maxHeight: maxImageHeight,
        );
      },
    );
  }
}

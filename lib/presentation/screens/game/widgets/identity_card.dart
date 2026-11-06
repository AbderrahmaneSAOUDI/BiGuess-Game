import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/card.dart' as domain;
import '../../../../providers/content_image_provider.dart';
import '../../../widgets/animations/animated_character_card.dart';

/// Outward-facing identity from the session snapshot, never from a filename.
/// Scrolling preserves the complete name at large accessibility text sizes.
class IdentityCard extends ConsumerWidget {
  final domain.Card card;

  const IdentityCard({super.key, required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedCharacterCard(
              fastReveal: true,
              imageAsset: card.imageReference,
              imageLoader: ref.watch(contentImageLoaderProvider),
              maxWidth: (constraints.maxWidth - 56).clamp(0, 640),
              maxHeight: (constraints.maxHeight * 0.65).clamp(48, 640),
            ),
            const SizedBox(height: 16),
            Semantics(
              container: true,
              label: 'Identity: ${card.name}',
              excludeSemantics: true,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: theme.colorScheme.primary),
                ),
                child: Text(
                  card.name,
                  key: const ValueKey('identity_name'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// 3D flip card with holographic diagonal light sweep and spring name hint tag
class AnimatedCharacterCard extends StatefulWidget {
  final String imageAsset;
  final String? characterName;
  final bool showNameHint;
  final double maxHeight;
  final double maxWidth;
  final double? cardSize;

  const AnimatedCharacterCard({
    super.key,
    required this.imageAsset,
    this.characterName,
    this.showNameHint = true,
    this.maxHeight = 400.0,
    this.maxWidth = 320.0,
    this.cardSize,
  });

  @override
  State<AnimatedCharacterCard> createState() => _AnimatedCharacterCardState();
}

class _AnimatedCharacterCardState extends State<AnimatedCharacterCard>
    with TickerProviderStateMixin {
  late final AnimationController _flipController;
  late final AnimationController _shimmerController;
  late final Animation<double> _flipAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _shimmerAnimation;
  Timer? _sequenceTimer;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _flipAnimation = Tween<double>(begin: pi / 2, end: 0.0).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: Curves.easeOutBack,
      ),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_flipController);

    _shimmerAnimation = Tween<double>(begin: -1.2, end: 1.8).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.easeInOutSine,
      ),
    );

    _playRevealAnimation();
  }

  void _playRevealAnimation() {
    _sequenceTimer?.cancel();
    _flipController.forward(from: 0.0);
    _sequenceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _shimmerController.forward(from: 0.0);
      }
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedCharacterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageAsset != widget.imageAsset) {
      _playRevealAnimation();
    }
  }

  @override
  void dispose() {
    _sequenceTimer?.cancel();
    _flipController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveMaxWidth = widget.cardSize ?? widget.maxWidth;
    final effectiveMaxHeight = widget.cardSize ?? widget.maxHeight;

    return AnimatedBuilder(
      animation: _flipController,
      builder: (context, child) {
        final flipVal = _flipAnimation.value;
        final scaleVal = _scaleAnimation.value;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(flipVal)
            ..scaleByDouble(scaleVal, scaleVal, 1.0, 1.0),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: effectiveMaxWidth,
                      maxHeight: effectiveMaxHeight,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.85),
                            theme.colorScheme.tertiary.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.28),
                            blurRadius: 22,
                            spreadRadius: 2,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3.5),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(21),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              widget.imageAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.broken_image_rounded,
                                          color: Colors.red,
                                          size: 50,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Error loading image',
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Holographic diagonal light sweep
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _shimmerController,
                                builder: (context, child) {
                                  if (_shimmerController.value <= 0.0 ||
                                      _shimmerController.value >= 1.0) {
                                    return const SizedBox.shrink();
                                  }
                                  return LayoutBuilder(
                                    builder: (context, cardConstraints) {
                                      final sweepDistance =
                                          (cardConstraints.maxWidth > 0
                                              ? cardConstraints.maxWidth
                                              : 300.0) *
                                          1.5;
                                      return IgnorePointer(
                                        child: Transform.translate(
                                          offset: Offset(
                                            _shimmerAnimation.value *
                                                sweepDistance,
                                            0,
                                          ),
                                          child: Transform.rotate(
                                            angle: 0.4,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white
                                                        .withValues(alpha: 0.0),
                                                    Colors.white
                                                        .withValues(alpha: 0.45),
                                                    Colors.white
                                                        .withValues(alpha: 0.0),
                                                  ],
                                                  stops: const [0.0, 0.5, 1.0],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Character Name Hint with spring entrance
              if (widget.characterName != null && widget.showNameHint)
                TweenAnimationBuilder<double>(
                  key: ValueKey(widget.characterName),
                  duration: const Duration(milliseconds: 600),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Transform.scale(
                        scale: (0.7 + 0.3 * value).clamp(0.0, 1.0),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.4,
                                ),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.shadow.withValues(
                                    alpha: 0.12,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 22,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    widget.characterName!,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.onSurface,
                                      letterSpacing: 0.4,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

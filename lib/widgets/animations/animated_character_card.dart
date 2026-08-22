import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'animated_particle_burst.dart';

class AnimatedCharacterCard extends StatefulWidget {
  final String imageAsset;
  final String? characterName;
  final bool showNameHint;
  final double maxHeight;

  const AnimatedCharacterCard({
    super.key,
    required this.imageAsset,
    this.characterName,
    this.showNameHint = true,
    this.maxHeight = 350.0,
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
  final GlobalKey<AnimatedParticleBurstState> _burstKey = GlobalKey();
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
        _burstKey.currentState?.trigger();
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

    return AnimatedParticleBurst(
      key: _burstKey,
      autoPlay: false,
      particleCount: 45,
      child: AnimatedBuilder(
        animation: _flipController,
        builder: (context, child) {
          final flipVal = _flipAnimation.value;
          final scaleVal = _scaleAnimation.value;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // 3D perspective
              ..rotateY(flipVal)
              ..scaleByDouble(scaleVal, scaleVal, 1.0, 1.0),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Character Image Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.8),
                          theme.colorScheme.tertiary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.25),
                          blurRadius: 24,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3), // Gradient border width
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(21),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            color: theme.colorScheme.surface,
                            child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(maxHeight: widget.maxHeight),
                              child: Image.asset(
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
                            ),
                          ),

                          // Holographic diagonal light sweep across the card
                          AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, child) {
                              if (_shimmerController.value <= 0.0 ||
                                  _shimmerController.value >= 1.0) {
                                return const SizedBox.shrink();
                              }
                              return Positioned.fill(
                                child: IgnorePointer(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(21),
                                    child: Transform.translate(
                                      offset: Offset(
                                        _shimmerAnimation.value * 350.0,
                                        0,
                                      ),
                                      child: Transform.rotate(
                                        angle: 0.4,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.white.withValues(alpha: 0.0),
                                                Colors.white.withValues(alpha: 0.45),
                                                Colors.white.withValues(alpha: 0.0),
                                              ],
                                              stops: const [0.0, 0.5, 1.0],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
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
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.shadow.withValues(
                                      alpha: 0.1,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      widget.characterName!,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                        letterSpacing: 0.3,
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
      ),
    );
  }
}

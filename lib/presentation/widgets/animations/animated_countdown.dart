import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Animated countdown display featuring expanding sonic shockwave rings and pulsing number
class AnimatedCountdown extends StatefulWidget {
  final int countdown;

  const AnimatedCountdown({
    super.key,
    required this.countdown,
  });

  @override
  State<AnimatedCountdown> createState() => _AnimatedCountdownState();
}

class _AnimatedCountdownState extends State<AnimatedCountdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rippleController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.6, end: 0.9)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_rippleController);

    _glowAnimation = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _rippleController.forward(from: 0.0);
  }

  @override
  void didUpdateWidget(covariant AnimatedCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countdown != widget.countdown) {
      _rippleController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  Color _getCountdownColor(int count) {
    if (count <= 1) return AppColors.countdownCritical;
    if (count <= 2) return AppColors.countdownWarning;
    if (count <= 3) return AppColors.countdownAlert;
    return AppColors.countdownDefault;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countColor = _getCountdownColor(widget.countdown);

    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Expanding sonic shockwave rings
            AnimatedBuilder(
              animation: _rippleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ShockwaveRingsPainter(
                    progress: _rippleController.value,
                    color: countColor,
                  ),
                  size: const Size(260, 260),
                );
              },
            ),

            // Ambient Radial Glow
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: countColor.withValues(
                          alpha: 0.35 * _glowAnimation.value,
                        ),
                        blurRadius: 50,
                        spreadRadius: 20 * _glowAnimation.value,
                      ),
                    ],
                  ),
                );
              },
            ),

            // Pulsing Count Number
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Text(
                    '${widget.countdown}',
                    style: TextStyle(
                      fontSize: 108,
                      fontWeight: FontWeight.w900,
                      color: countColor,
                      letterSpacing: -2.0,
                      shadows: [
                        Shadow(
                          color: countColor.withValues(alpha: 0.8),
                          blurRadius: 24,
                        ),
                        const Shadow(
                          color: Colors.black38,
                          offset: Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ShockwaveRingsPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ShockwaveRingsPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Ring 1 (fast primary wave)
    _drawWaveRing(
      canvas: canvas,
      center: center,
      progress: progress,
      maxRadius: maxRadius,
      strokeWidth: 4.0,
      opacityFactor: 1.0,
    );

    // Ring 2 (delayed secondary wave)
    if (progress > 0.15) {
      final delayedProgress = (progress - 0.15) / 0.85;
      _drawWaveRing(
        canvas: canvas,
        center: center,
        progress: delayedProgress,
        maxRadius: maxRadius * 0.85,
        strokeWidth: 2.5,
        opacityFactor: 0.7,
      );
    }
  }

  void _drawWaveRing({
    required Canvas canvas,
    required Offset center,
    required double progress,
    required double maxRadius,
    required double strokeWidth,
    required double opacityFactor,
  }) {
    final currentRadius = 40.0 + progress * (maxRadius - 40.0);
    final opacity = (1.0 - progress).clamp(0.0, 1.0) * opacityFactor * 0.8;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * (1.0 - progress * 0.5);

    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _ShockwaveRingsPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

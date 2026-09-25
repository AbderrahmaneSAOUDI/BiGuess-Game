import 'dart:math';
import 'package:flutter/material.dart';

/// Floating mystery box with pulsing borders, radial glow, and orbiting sparkles
class AnimatedMysteryBox extends StatefulWidget {
  final VoidCallback? onTap;

  const AnimatedMysteryBox({
    super.key,
    this.onTap,
  });

  @override
  State<AnimatedMysteryBox> createState() => _AnimatedMysteryBoxState();
}

class _AnimatedMysteryBoxState extends State<AnimatedMysteryBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          final floatOffset = sin(progress * 2 * pi) * 8.0;
          final pulse = (sin(progress * 2 * pi) + 1.0) / 2.0;

          return Transform.translate(
            offset: Offset(0, floatOffset),
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: isDark
                      ? Color.lerp(
                          const Color(0xFF1E1E2C),
                          const Color(0xFF26263A),
                          pulse,
                        )
                      : Color.lerp(
                          Colors.white,
                          const Color(0xFFF0F4FF),
                          pulse,
                        ),
                  border: Border.all(
                    color: Color.lerp(
                      theme.colorScheme.primary.withValues(alpha: 0.3),
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                      pulse,
                    )!,
                    width: 2.0 + pulse * 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(
                        alpha: 0.15 + pulse * 0.2,
                      ),
                      blurRadius: 20 + pulse * 15,
                      spreadRadius: 2 + pulse * 4,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Orbiting Sparkles
                    CustomPaint(
                      painter: _OrbitingSparklesPainter(
                        progress: progress,
                        color: theme.colorScheme.primary,
                      ),
                      size: const Size(280, 280),
                    ),

                    // Central Content
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                theme.colorScheme.primary.withValues(alpha: 0.25),
                                theme.colorScheme.primary.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.help_outline_rounded,
                            size: 80,
                            color: Color.lerp(
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                              pulse,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Tap to Reveal',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrbitingSparklesPainter extends CustomPainter {
  final double progress;
  final Color color;

  _OrbitingSparklesPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 95.0;
    const numSparkles = 4;

    for (int i = 0; i < numSparkles; i++) {
      final angle = (progress * 2 * pi) + (i * 2 * pi / numSparkles);
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * (radius * 0.75);

      final sparklePaint = Paint()
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle * 2);

      final path = Path();
      const s = 4.5;
      path.moveTo(0, -s);
      path.lineTo(s, 0);
      path.lineTo(0, s);
      path.lineTo(-s, 0);
      path.close();

      canvas.drawPath(path, sparklePaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitingSparklesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

import 'dart:math';
import 'package:flutter/material.dart';

enum ParticleShape {
  circle,
  rect,
  star,
}

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double rotationSpeed;
  double scale;
  double maxScale;
  Color color;
  ParticleShape shape;
  double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.scale,
    required this.maxScale,
    required this.color,
    required this.shape,
    required this.opacity,
  });
}

class AnimatedParticleBurst extends StatefulWidget {
  final Widget? child;
  final int particleCount;
  final List<Color>? colors;
  final Duration duration;
  final bool autoPlay;

  const AnimatedParticleBurst({
    super.key,
    this.child,
    this.particleCount = 50,
    this.colors,
    this.duration = const Duration(milliseconds: 1400),
    this.autoPlay = true,
  });

  @override
  State<AnimatedParticleBurst> createState() => AnimatedParticleBurstState();
}

class AnimatedParticleBurstState extends State<AnimatedParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  static const List<Color> defaultColors = [
    Color(0xFFFF5252), // Red
    Color(0xFFFFD700), // Gold
    Color(0xFF448AFF), // Blue
    Color(0xFF69F0AE), // Mint Green
    Color(0xFFFF4081), // Pink
    Color(0xFFE040FB), // Purple
    Color(0xFFFFAB40), // Orange
    Color(0xFF40C4FF), // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addListener(() {
        _updateParticles();
      });

    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        trigger();
      });
    }
  }

  void trigger() {
    if (!mounted) return;
    _initParticles();
    _controller.forward(from: 0.0);
  }

  void _initParticles() {
    _particles.clear();
    final colors = widget.colors ?? defaultColors;

    for (int i = 0; i < widget.particleCount; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 120.0 + _random.nextDouble() * 280.0;
      final shapeType = _random.nextInt(3);
      final shape = shapeType == 0
          ? ParticleShape.star
          : (shapeType == 1 ? ParticleShape.rect : ParticleShape.circle);

      _particles.add(
        _Particle(
          x: 0,
          y: 0,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 60.0, // slight upward boost
          rotation: _random.nextDouble() * 2 * pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 8.0,
          scale: 0.2,
          maxScale: 6.0 + _random.nextDouble() * 6.0,
          color: colors[_random.nextInt(colors.length)],
          shape: shape,
          opacity: 1.0,
        ),
      );
    }
  }

  void _updateParticles() {
    final progress = _controller.value;
    const dt = 1.0 / 60.0; // standard frame step

    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 180.0 * dt; // gravity
      p.vx *= 0.98; // air drag
      p.rotation += p.rotationSpeed * dt;

      // Scale up fast then maintain
      if (progress < 0.2) {
        p.scale = (progress / 0.2) * p.maxScale;
      } else {
        p.scale = p.maxScale;
      }

      // Fade out towards the end
      if (progress > 0.6) {
        p.opacity = ((1.0 - progress) / 0.4).clamp(0.0, 1.0);
      } else {
        p.opacity = 1.0;
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (widget.child != null) widget.child!,
        if (_controller.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _controller.value,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final p in particles) {
      if (p.opacity <= 0.01) continue;

      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(center.dx + p.x, center.dy + p.y);
      canvas.rotate(p.rotation);

      switch (p.shape) {
        case ParticleShape.circle:
          canvas.drawCircle(Offset.zero, p.scale, paint);
          break;
        case ParticleShape.rect:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: p.scale * 1.8,
                height: p.scale * 0.9,
              ),
              const Radius.circular(2),
            ),
            paint,
          );
          break;
        case ParticleShape.star:
          _drawStar(canvas, p.scale * 1.3, paint);
          break;
      }

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, double radius, Paint paint) {
    final path = Path();
    const numPoints = 5;
    final halfRadius = radius / 2;

    for (int i = 0; i < numPoints * 2; i++) {
      final r = i.isEven ? radius : halfRadius;
      final angle = i * pi / numPoints - pi / 2;
      final x = cos(angle) * r;
      final y = sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 3D Glassmorphic Action Button featuring frosted blur, specular highlights,
/// multi-layered 3D depth shadows, and interactive physical press down response
class AnimatedActionButton extends StatefulWidget {
  final bool hasStarted;
  final bool isEnabled;
  final VoidCallback onPressed;

  const AnimatedActionButton({
    super.key,
    this.hasStarted = true,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  State<AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<AnimatedActionButton>
    with TickerProviderStateMixin {
  late final AnimationController _buttonAnimationController;
  late final AnimationController _tapClickController;
  late final Animation<double> _buttonScaleAnimation;
  late final Animation<double> _shimmerAnimation;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _tapScalePunchAnimation;
  late final Animation<double> _tapSpinAnimation;
  late final Animation<double> _tapFlashAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat(reverse: true);

    _tapClickController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );

    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.2,
      end: 2.2,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.35,
      end: 0.85,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));

    _tapScalePunchAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.90)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.90, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_tapClickController);

    _tapSpinAnimation = Tween<double>(begin: 0.0, end: 4 * pi).animate(
      CurvedAnimation(
        parent: _tapClickController,
        curve: Curves.easeOutCubic,
      ),
    );

    _tapFlashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _tapClickController,
        curve: Curves.easeOutQuad,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEnabled != oldWidget.isEnabled) {
      if (widget.isEnabled) {
        if (!_buttonAnimationController.isAnimating) {
          _buttonAnimationController.repeat(reverse: true);
        }
      } else {
        _buttonAnimationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    _tapClickController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isEnabled) return;
    _tapClickController.forward(from: 0.0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryGlow = isDark
        ? AppColors.refreshGradientStart
        : theme.colorScheme.primary;
    final primaryDeep = isDark
        ? AppColors.refreshGradientEnd
        : theme.colorScheme.primaryContainer;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _buttonAnimationController,
        _tapClickController,
      ]),
      builder: (context, child) {
        final scale = _isPressed
            ? 0.95
            : (_buttonScaleAnimation.value *
                (_tapClickController.isAnimating
                    ? _tapScalePunchAnimation.value
                    : 1.0));

        final verticalOffset = _isPressed ? 4.0 : 0.0;

        return Transform.translate(
          offset: Offset(0, verticalOffset),
          child: Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  // Deep 3D Ambient Base Shadow
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark
                          ? (_isPressed ? 0.30 : 0.55)
                          : (_isPressed ? 0.10 : 0.22),
                    ),
                    blurRadius: _isPressed ? 6 : 16,
                    offset: Offset(0, _isPressed ? 2 : 8),
                  ),
                  // Glowing Electric Aura
                  BoxShadow(
                    color: primaryGlow.withValues(
                      alpha: _isPressed
                          ? 0.25
                          : _glowAnimation.value * (isDark ? 0.50 : 0.35),
                    ),
                    spreadRadius: _isPressed ? 0 : 2,
                    blurRadius: _isPressed ? 8 : 24,
                    offset: Offset(0, _isPressed ? 2 : 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Colors.white.withValues(alpha: 0.22),
                                primaryGlow.withValues(alpha: 0.40),
                                primaryDeep.withValues(alpha: 0.65),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.70),
                                primaryGlow.withValues(alpha: 0.45),
                                primaryGlow.withValues(alpha: 0.75),
                              ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.30)
                            : Colors.white.withValues(alpha: 0.70),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Top Specular 3D Glass Light Ridge
                        Positioned(
                          top: 0,
                          left: 16,
                          right: 16,
                          height: 1.5,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(
                                    alpha: isDark ? 0.75 : 0.95,
                                  ),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // Shimmer sweep reflection
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Transform.translate(
                              offset: Offset(
                                _shimmerAnimation.value *
                                    (MediaQuery.of(context).size.width * 0.6),
                                0,
                              ),
                              child: Transform.rotate(
                                angle: 0.35,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.0),
                                        Colors.white.withValues(
                                          alpha: isDark ? 0.25 : 0.45,
                                        ),
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

                        // Tap Energy Flash Wave
                        if (_tapClickController.isAnimating)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: CustomPaint(
                                painter: _ButtonFlashPainter(
                                  progress: _tapFlashAnimation.value,
                                ),
                              ),
                            ),
                          ),

                        // Interactive Button Area
                        GestureDetector(
                          onTapDown: (_) => setState(() => _isPressed = true),
                          onTapUp: (_) => setState(() => _isPressed = false),
                          onTapCancel: () => setState(() => _isPressed = false),
                          child: ElevatedButton.icon(
                            onPressed: widget.isEnabled ? _handleTap : null,
                            icon: Transform.rotate(
                              angle: _tapSpinAnimation.value,
                              child: const Icon(
                                Icons.refresh_rounded,
                                key: ValueKey('refresh_icon'),
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            label: const Text(
                              'Refresh',
                              key: ValueKey('refresh_text'),
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.8,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 1.5),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 44,
                                vertical: 17,
                              ),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ButtonFlashPainter extends CustomPainter {
  final double progress;

  _ButtonFlashPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final currentRadius = progress * maxRadius;
    final opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.5;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: opacity),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: currentRadius));

    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _ButtonFlashPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

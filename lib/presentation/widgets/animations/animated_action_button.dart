import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Animated energetic action button featuring glowing borders, shimmer sweep, and tap flash wave
class AnimatedActionButton extends StatefulWidget {
  final bool hasStarted;
  final bool isEnabled;
  final VoidCallback onPressed;

  const AnimatedActionButton({
    super.key,
    required this.hasStarted,
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
  late final Animation<double> _buttonRotationAnimation;
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
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);

    _tapClickController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );

    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));

    _buttonRotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
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
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));

    _tapScalePunchAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.88)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.88, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
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
    final activeColor1 = widget.hasStarted
        ? AppColors.refreshGradientStart
        : AppColors.startGradientStart;
    final activeColor2 = widget.hasStarted
        ? AppColors.refreshGradientEnd
        : AppColors.startGradientEnd;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _buttonAnimationController,
        _tapClickController,
      ]),
      builder: (context, child) {
        final scale = _isPressed
            ? 0.93
            : (_buttonScaleAnimation.value *
                (_tapClickController.isAnimating
                    ? _tapScalePunchAnimation.value
                    : 1.0));

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [activeColor1, activeColor2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: activeColor1.withValues(
                    alpha: _isPressed
                        ? 0.3
                        : _glowAnimation.value * 0.45,
                  ),
                  spreadRadius: _isPressed ? 0 : 2,
                  blurRadius: _isPressed ? 6 : 18,
                  offset: Offset(0, _isPressed ? 2 : 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Shimmer sweep
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Transform.translate(
                      offset: Offset(
                        _shimmerAnimation.value *
                            (MediaQuery.of(context).size.width * 0.6),
                        0,
                      ),
                      child: Transform.rotate(
                        angle: 0.3,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.35),
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
                      borderRadius: BorderRadius.circular(30),
                      child: CustomPaint(
                        painter: _ButtonFlashPainter(
                          progress: _tapFlashAnimation.value,
                        ),
                      ),
                    ),
                  ),

                GestureDetector(
                  onTapDown: (_) => setState(() => _isPressed = true),
                  onTapUp: (_) => setState(() => _isPressed = false),
                  onTapCancel: () => setState(() => _isPressed = false),
                  child: ElevatedButton.icon(
                    onPressed: widget.isEnabled ? _handleTap : null,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: widget.hasStarted
                          ? Transform.rotate(
                              angle: _buttonRotationAnimation.value +
                                  _tapSpinAnimation.value,
                              child: const Icon(
                                Icons.refresh_rounded,
                                key: ValueKey('refresh'),
                                color: Colors.white,
                                size: 28,
                              ),
                            )
                          : const Icon(
                              Icons.play_arrow_rounded,
                              key: ValueKey('play'),
                              color: Colors.white,
                              size: 28,
                            ),
                    ),
                    label: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        widget.hasStarted ? 'Refresh' : 'Start',
                        key: ValueKey(widget.hasStarted),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 42,
                        vertical: 18,
                      ),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
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

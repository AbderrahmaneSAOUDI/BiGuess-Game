import 'dart:ui';
import 'package:flutter/material.dart';

/// An animated frosted glass background designed for AppBar flexibleSpace
class AnimatedGlassAppBarBackground extends StatefulWidget {
  final double blurSigmaX;
  final double blurSigmaY;
  final bool showShimmerBorder;
  final Color? accentColor;

  const AnimatedGlassAppBarBackground({
    super.key,
    this.blurSigmaX = 16.0,
    this.blurSigmaY = 16.0,
    this.showShimmerBorder = true,
    this.accentColor,
  });

  @override
  State<AnimatedGlassAppBarBackground> createState() =>
      _AnimatedGlassAppBarBackgroundState();
}

class _AnimatedGlassAppBarBackgroundState
    extends State<AnimatedGlassAppBarBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _shimmerAnimation = Tween<double>(begin: -0.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.easeInOutCubic,
      ),
    );

    if (widget.showShimmerBorder) {
      _shimmerController.forward();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = widget.accentColor ?? theme.colorScheme.primary;

    final baseGlassColor = isDark
        ? theme.colorScheme.surface.withValues(alpha: 0.68)
        : theme.colorScheme.surface.withValues(alpha: 0.78);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.blurSigmaX,
          sigmaY: widget.blurSigmaY,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Glass surface tint with subtle gradient
            DecoratedBox(
              decoration: BoxDecoration(
                color: baseGlassColor,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.45),
                    Colors.transparent,
                    isDark
                        ? primary.withValues(alpha: 0.04)
                        : primary.withValues(alpha: 0.02),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: borderColor,
                    width: 1.0,
                  ),
                ),
              ),
            ),

            // Animated entrance light sweep / shimmer border at the bottom
            if (widget.showShimmerBorder)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 1.5,
                child: AnimatedBuilder(
                  animation: _shimmerAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(_shimmerAnimation.value - 0.4, 0),
                          end: Alignment(_shimmerAnimation.value + 0.4, 0),
                          colors: [
                            Colors.transparent,
                            primary.withValues(alpha: isDark ? 0.7 : 0.5),
                            theme.colorScheme.tertiary
                                .withValues(alpha: isDark ? 0.6 : 0.4),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 0.55, 1.0],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

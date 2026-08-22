import 'package:flutter/material.dart';

class InteractiveScaleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleOnHover;
  final double scaleOnPress;
  final BorderRadius? borderRadius;
  final Color? glowColor;

  const InteractiveScaleCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleOnHover = 1.04,
    this.scaleOnPress = 0.96,
    this.borderRadius,
    this.glowColor,
  });

  @override
  State<InteractiveScaleCard> createState() => _InteractiveScaleCardState();
}

class _InteractiveScaleCardState extends State<InteractiveScaleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  bool _isHovered = false;
  bool _isPressed = false;
  double _targetTiltX = 0.0;
  double _targetTiltY = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleOnHover).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHoverEnter(PointerEvent details) {
    setState(() => _isHovered = true);
    _controller.forward();
  }

  void _handleHoverExit(PointerEvent details) {
    setState(() {
      _isHovered = false;
      _targetTiltX = 0.0;
      _targetTiltY = 0.0;
    });
    if (!_isPressed) {
      _controller.reverse();
    }
  }

  void _handleHover(PointerEvent details) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final size = box.size;
      final localPos = box.globalToLocal(details.position);
      final nx = (localPos.dx / size.width - 0.5) * 2.0; // -1.0 to 1.0
      final ny = (localPos.dy / size.height - 0.5) * 2.0; // -1.0 to 1.0

      setState(() {
        _targetTiltY = nx * 0.12; // Rotate around Y axis
        _targetTiltX = -ny * 0.12; // Rotate around X axis
      });
    }
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = widget.borderRadius ?? BorderRadius.circular(16);
    final glow = widget.glowColor ?? theme.colorScheme.primary;

    return MouseRegion(
      onEnter: _handleHoverEnter,
      onExit: _handleHoverExit,
      onHover: _handleHover,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale = _isPressed
                ? widget.scaleOnPress
                : (_isHovered ? _scaleAnimation.value : 1.0);

            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // 3D perspective
                ..rotateX(_isHovered ? _targetTiltX : 0.0)
                ..rotateY(_isHovered ? _targetTiltY : 0.0)
                ..scaleByDouble(scale, scale, 1.0, 1.0),
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [
                    if (_isHovered || _isPressed)
                      BoxShadow(
                        color: glow.withValues(
                          alpha: _isPressed ? 0.4 : 0.25 * _glowAnimation.value,
                        ),
                        blurRadius: _isPressed ? 8 : 16,
                        spreadRadius: _isPressed ? 0 : 2,
                        offset: Offset(0, _isPressed ? 2 : 6),
                      ),
                  ],
                ),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

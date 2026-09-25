import 'package:flutter/material.dart';

/// A modern frosted glass icon button with hover glow and press feedback
class GlassIconButton extends StatefulWidget {
  final Widget icon;
  final String? tooltip;
  final VoidCallback? onPressed;
  final Color? glowColor;
  final double size;
  final EdgeInsetsGeometry padding;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.tooltip,
    this.onPressed,
    this.glowColor,
    this.size = 40.0,
    this.padding = const EdgeInsets.all(8.0),
  });

  factory GlassIconButton.icon({
    Key? key,
    required IconData iconData,
    String? tooltip,
    VoidCallback? onPressed,
    Color? glowColor,
    double size = 40.0,
    double iconSize = 22.0,
    Color? iconColor,
  }) {
    return GlassIconButton(
      key: key,
      tooltip: tooltip,
      onPressed: onPressed,
      glowColor: glowColor,
      size: size,
      icon: Icon(
        iconData,
        size: iconSize,
        color: iconColor,
      ),
    );
  }

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = widget.glowColor ?? theme.colorScheme.primary;

    final scale = _isPressed ? 0.92 : (_isHovered ? 1.08 : 1.0);

    final glassBg = isDark
        ? (_isHovered
            ? primary.withValues(alpha: 0.20)
            : Colors.white.withValues(alpha: 0.08))
        : (_isHovered
            ? primary.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.05));

    final glassBorder = isDark
        ? (_isHovered
            ? primary.withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.12))
        : (_isHovered
            ? primary.withValues(alpha: 0.35)
            : Colors.black.withValues(alpha: 0.08));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: widget.onPressed != null
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.onPressed != null
            ? (_) => setState(() => _isPressed = false)
            : null,
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: glassBg,
              border: Border.all(
                color: glassBorder,
                width: 1.0,
              ),
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color: primary.withValues(alpha: isDark ? 0.35 : 0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
              ],
            ),
            alignment: Alignment.center,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(
                width: widget.size,
                height: widget.size,
              ),
              icon: widget.icon,
              tooltip: widget.tooltip,
              onPressed: widget.onPressed,
              splashRadius: widget.size / 2,
            ),
          ),
        ),
      ),
    );
  }
}

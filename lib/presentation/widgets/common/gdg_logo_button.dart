import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Animated GDG logo button that spins on tap
class GdgLogoButton extends StatefulWidget {
  final double size;

  const GdgLogoButton({
    super.key,
    this.size = 36.0,
  });

  @override
  State<GdgLogoButton> createState() => _GdgLogoButtonState();
}

class _GdgLogoButtonState extends State<GdgLogoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _triggerSpin() {
    if (!_spinController.isAnimating) {
      _spinController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _triggerSpin,
      child: RotationTransition(
        turns: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _spinController,
            curve: Curves.easeOutBack,
          ),
        ),
        child: Image.asset(
          AppConstants.gdgLogoPath,
          width: widget.size,
          height: widget.size,
        ),
      ),
    );
  }
}

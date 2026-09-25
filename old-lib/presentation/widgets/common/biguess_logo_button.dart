import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Animated BiGuess logo button that spins on tap
class BiGuessLogoButton extends StatefulWidget {
  final double size;

  const BiGuessLogoButton({
    super.key,
    this.size = 36.0,
  });

  @override
  State<BiGuessLogoButton> createState() => _BiGuessLogoButtonState();
}

class _BiGuessLogoButtonState extends State<BiGuessLogoButton>
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
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.size * 0.25),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.size * 0.25),
            child: Image.asset(
              AppConstants.appIconPath,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

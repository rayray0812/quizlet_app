import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Lightweight press feedback wrapper for buttons.
/// Uses implicit animations only to avoid manual controller lifecycle issues.
class BouncyPressable extends StatefulWidget {
  const BouncyPressable({
    super.key,
    required this.child,
    this.scaleWhenPressed = 0.96,
    this.duration = const Duration(milliseconds: 120),
  });

  final Widget child;
  final double scaleWhenPressed;
  final Duration duration;

  @override
  State<BouncyPressable> createState() => _BouncyPressableState();
}

class _BouncyPressableState extends State<BouncyPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        HapticFeedback.selectionClick();
        setState(() => _pressed = true);
      },
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.scaleWhenPressed : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

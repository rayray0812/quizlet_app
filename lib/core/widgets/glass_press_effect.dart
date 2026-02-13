import 'package:flutter/material.dart';

class GlassPressEffect extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double pressedOpacity;
  final Duration duration;

  const GlassPressEffect({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.pressedOpacity = 0.16,
    this.duration = const Duration(milliseconds: 140),
  });

  @override
  State<GlassPressEffect> createState() => _GlassPressEffectState();
}

class _GlassPressEffectState extends State<GlassPressEffect> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          fit: StackFit.passthrough,
          children: [widget.child,
            IgnorePointer(
              child: AnimatedOpacity(
                duration: widget.duration,
                curve: Curves.easeOutCubic,
                opacity: _pressed ? 1 : 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: widget.pressedOpacity),
                        Colors.white.withValues(alpha: widget.pressedOpacity * 0.45),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

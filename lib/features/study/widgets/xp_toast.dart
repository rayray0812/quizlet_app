import 'package:flutter/material.dart';
import 'package:recall_app/core/theme/app_theme.dart';

/// Animated "+XP" toast that floats upward and fades out.
class XpToast extends StatefulWidget {
  final int xp;
  final double? multiplier;
  final VoidCallback? onComplete;

  const XpToast({
    super.key,
    required this.xp,
    this.multiplier,
    this.onComplete,
  });

  @override
  State<XpToast> createState() => _XpToastState();
}

class _XpToastState extends State<XpToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward().then((_) => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final opacity = (1.0 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
        final offset = -40.0 * Curves.easeOut.transform(t);
        final scale = 0.8 + Curves.easeOutBack.transform(
          const Interval(0, 0.4).transform(t),
        ) * 0.3;

        return Transform.translate(
          offset: Offset(0, offset),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Text(
                '+${widget.xp} XP',
                style: const TextStyle(
                  color: AppTheme.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  shadows: [
                    Shadow(
                      color: Colors.white,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Manages a queue of XP toasts displayed as an overlay.
class XpToastOverlay extends StatefulWidget {
  const XpToastOverlay({super.key});

  @override
  State<XpToastOverlay> createState() => XpToastOverlayState();
}

class XpToastOverlayState extends State<XpToastOverlay> {
  final List<_ToastEntry> _toasts = [];
  int _nextId = 0;

  void showXp(int xp, {double? multiplier}) {
    setState(() {
      _toasts.add(_ToastEntry(id: _nextId++, xp: xp, multiplier: multiplier));
    });
  }

  void _removeToast(int id) {
    setState(() {
      _toasts.removeWhere((t) => t.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _toasts.map((entry) {
          return XpToast(
            key: ValueKey(entry.id),
            xp: entry.xp,
            multiplier: entry.multiplier,
            onComplete: () => _removeToast(entry.id),
          );
        }).toList(),
      ),
    );
  }
}

class _ToastEntry {
  final int id;
  final int xp;
  final double? multiplier;

  const _ToastEntry({
    required this.id,
    required this.xp,
    this.multiplier,
  });
}

import 'dart:math' show cos, pi, sin;

import 'package:flutter/material.dart';

/// Shared celebration overlay widget used across quiz and matching game screens.
/// Animates a celebration icon with a burst of dots when a study mode is
/// completed.
class CompletionCelebrateOverlay extends StatelessWidget {
  final Animation<double> animation;
  final Color color;

  const CompletionCelebrateOverlay({
    super.key,
    required this.animation,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final overlayT = const Interval(
          0.0,
          0.7,
          curve: Curves.easeOut,
        ).transform(t);
        final revealT = const Interval(
          0.16,
          0.74,
          curve: Curves.easeOutBack,
        ).transform(t);
        final revealOpacity = revealT.clamp(0.0, 1.0);
        final burstT = const Interval(
          0.28,
          1.0,
          curve: Curves.easeOutCubic,
        ).transform(t);
        final overlayOpacity = (0.18 * (1 - (overlayT - 0.72).clamp(0.0, 1.0)))
            .clamp(0.0, 0.18);
        final pop = 0.46 + (revealT * 0.54) + sin(revealT * pi * 1.6) * 0.035;

        return Container(
          color: Colors.white.withValues(alpha: overlayOpacity),
          child: Center(
            child: Transform.scale(
              scale: pop,
              child: Opacity(
                opacity: revealOpacity,
                child: Container(
                  width: 124,
                  height: 124,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.94),
                    border: Border.all(
                      color: color.withValues(alpha: 0.25),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.22),
                        blurRadius: 26,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (var i = 0; i < 10; i++)
                        _CelebrationDot(
                          index: i,
                          progress: burstT,
                          color: color,
                        ),
                      Icon(Icons.celebration_rounded, size: 54, color: color),
                    ],
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

class _CelebrationDot extends StatelessWidget {
  final int index;
  final double progress;
  final Color color;

  const _CelebrationDot({
    required this.index,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final angle = ((index / 10) * pi * 2) - pi / 2;
    final distance = 16 + progress * 42;
    final dx = cos(angle) * distance;
    final dy = sin(angle) * distance;
    final alpha = (0.8 - progress * 0.75).clamp(0.0, 1.0);

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Opacity(
        opacity: alpha,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Color.lerp(
              color,
              const Color(0xFFFFD96B),
              (index % 3) * 0.35,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

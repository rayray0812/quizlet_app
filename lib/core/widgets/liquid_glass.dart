import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool get isLiquidGlassSupported =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? tintColor;
  final double blurSigma;
  final Border? border;
  final List<BoxShadow>? shadows;

  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.tintColor,
    this.blurSigma = 16,
    this.border,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    if (!isLiquidGlassSupported) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: tintColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border,
          boxShadow: shadows,
        ),
        child: child,
      );
    }

    final effectiveTint =
        tintColor ??
        Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: isDark ? 0.18 : 0.24);
    final effectiveBorder =
        border ??
        Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.24 : 0.52),
          width: 1.1,
        );
    final effectiveShadows =
        shadows ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: effectiveTint,
            borderRadius: BorderRadius.circular(borderRadius),
            border: effectiveBorder,
            boxShadow: effectiveShadows,
          ),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: isDark ? 0.16 : 0.26),
                        Colors.white.withValues(alpha: isDark ? 0.07 : 0.12),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.35, 1.0],
                    ),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

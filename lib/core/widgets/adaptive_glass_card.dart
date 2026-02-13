import 'package:flutter/material.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/liquid_glass.dart';

class AdaptiveGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color? fillColor;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double elevation;
  final Color? borderColor;

  const AdaptiveGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.fillColor,
    this.margin,
    this.padding,
    this.elevation = 1,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = padding != null
        ? Padding(padding: padding!, child: child)
        : child;

    final card = isLiquidGlassSupported
        ? LiquidGlass(
            borderRadius: borderRadius,
            blurSigma: isDark ? 20 : 24,
            tintColor: (fillColor ?? Theme.of(context).colorScheme.surface)
                .withValues(alpha: isDark ? 0.16 : 0.22),
            border: Border.all(
              color:
                  borderColor ??
                  Colors.white.withValues(alpha: isDark ? 0.24 : 0.46),
              width: 1,
            ),
            child: content,
          )
        : Container(
            decoration: AppTheme.softCardDecoration(
              fillColor: fillColor ?? Theme.of(context).cardColor,
              borderRadius: borderRadius,
              borderColor: borderColor,
              elevation: elevation,
            ),
            child: content,
          );

    if (margin == null) return card;
    return Padding(padding: margin!, child: card);
  }
}

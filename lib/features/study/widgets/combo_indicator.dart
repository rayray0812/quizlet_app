import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/providers/session_xp_provider.dart';

/// Shows a fire icon + combo count when combo >= 3.
/// Pulses at combo 5 and 10 milestones.
class ComboIndicator extends ConsumerWidget {
  const ComboIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xp = ref.watch(sessionXpProvider);
    if (xp.comboCount < 3) return const SizedBox.shrink();

    final isMilestone = xp.comboCount == 5 || xp.comboCount == 10;
    final color = xp.comboCount >= 10
        ? AppTheme.orange
        : xp.comboCount >= 5
            ? AppTheme.gold
            : AppTheme.green;

    return TweenAnimationBuilder<double>(
      key: ValueKey(xp.comboCount),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: isMilestone ? 0.8 + value * 0.3 : 0.9 + value * 0.1,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department_rounded, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              '${xp.comboCount}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            if (xp.multiplier > 1.0) ...[
              const SizedBox(width: 6),
              Text(
                '\u00D7${xp.multiplier.toStringAsFixed(1)}',
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

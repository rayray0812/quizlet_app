import 'package:flutter/material.dart';
import 'package:recall_app/core/theme/app_theme.dart';

class StudyResultHeader extends StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final String title;
  final String primaryText;
  final String? badgeText;

  const StudyResultHeader({
    super.key,
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.primaryText,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 40, color: accentColor),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          primaryText,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (badgeText != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeText!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class StudyResultChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;
  final double minWidth;

  const StudyResultChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.minWidth = 110,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: minWidth),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class StudyResultDialogActions extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const StudyResultDialogActions({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(onPressed: onLeft, child: Text(leftLabel)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(onPressed: onRight, child: Text(rightLabel)),
        ),
      ],
    );
  }
}

class StudyResultCard extends StatelessWidget {
  final Widget child;

  const StudyResultCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: AppTheme.softCardDecoration(
            fillColor: Theme.of(context).cardColor,
            borderRadius: 12,
            borderColor: Theme.of(context).colorScheme.outlineVariant,
            elevation: 1.2,
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: child,
        ),
      ),
    );
  }
}


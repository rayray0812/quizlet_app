import 'package:flutter/material.dart';
import 'package:recall_app/core/constants/study_constants.dart';
import 'package:recall_app/core/theme/app_theme.dart';

class RoundedProgressBar extends StatelessWidget {
  final double value;
  final String? counterText;
  final Color? accentColor;

  const RoundedProgressBar({
    super.key,
    required this.value,
    this.counterText,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.green;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 6,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: StudyConstants.progressBarDuration,
                curve: StudyConstants.progressBarCurve,
                builder: (context, animatedValue, _) {
                  return LinearProgressIndicator(
                    value: animatedValue,
                    backgroundColor: color.withValues(alpha: 0.14),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  );
                },
              ),
            ),
          ),
          if (counterText != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                counterText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

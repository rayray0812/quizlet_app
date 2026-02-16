import 'package:flutter/material.dart';
import 'package:recall_app/core/theme/app_theme.dart';

class RoundedProgressBar extends StatelessWidget {
  final double value;

  const RoundedProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 6,
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppTheme.indigo.withValues(alpha: 0.14),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.green),
          ),
        ),
      ),
    );
  }
}

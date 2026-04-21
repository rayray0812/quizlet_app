import 'dart:math';

import 'package:flutter/material.dart';

class VoiceWaveIndicator extends StatelessWidget {
  final double soundLevel;

  const VoiceWaveIndicator({super.key, required this.soundLevel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = (soundLevel.clamp(0.0, 10.0)) / 10.0;
    final rng = Random(42);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(5, (i) {
        final jitter = 0.3 + rng.nextDouble() * 0.7;
        final barHeight = 6.0 + normalized * 18.0 * jitter;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          width: 3,
          height: barHeight,
          margin: EdgeInsets.only(left: i == 0 ? 0 : 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

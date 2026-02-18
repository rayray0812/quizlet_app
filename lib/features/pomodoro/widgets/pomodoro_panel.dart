import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/adaptive_glass_card.dart';
import 'package:recall_app/models/pomodoro_state.dart';
import 'package:recall_app/providers/pomodoro_provider.dart';
import 'package:recall_app/features/pomodoro/widgets/timer_dial.dart';

class PomodoroPanel extends ConsumerWidget {
  final VoidCallback onClose;

  const PomodoroPanel({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pom = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final l10n = AppLocalizations.of(context);

    final phaseColor = switch (pom.phase) {
      PomodoroPhase.study => AppTheme.indigo,
      PomodoroPhase.shortBreak => AppTheme.green,
      PomodoroPhase.longBreak => AppTheme.cyan,
    };

    final phaseLabel = switch (pom.phase) {
      PomodoroPhase.study => l10n.pomodoroStudy,
      PomodoroPhase.shortBreak => l10n.pomodoroShortBreak,
      PomodoroPhase.longBreak => l10n.pomodoroLongBreak,
    };

    final totalSeconds = switch (pom.phase) {
      PomodoroPhase.study => 25 * 60,
      PomodoroPhase.shortBreak => 5 * 60,
      PomodoroPhase.longBreak => 15 * 60,
    };

    return AdaptiveGlassCard(
      fillColor: Theme.of(context).colorScheme.surface,
      borderRadius: 24,
      elevation: 4,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.pomodoro,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: onClose,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: phaseColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              phaseLabel,
              style: TextStyle(
                  color: phaseColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
          TimerDial(
            remainingSeconds: pom.remainingSeconds,
            totalSeconds: totalSeconds,
            color: phaseColor,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.pomodoroSessions(pom.sessionsCompleted),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (pom.isActive)
                IconButton.filledTonal(
                  onPressed: () => notifier.reset(),
                  icon: const Icon(Icons.stop_rounded),
                ),
              const SizedBox(width: 16),
              FloatingActionButton(
                onPressed: () {
                  if (!pom.isActive || pom.isPaused) {
                    notifier.start();
                  } else {
                    notifier.pause();
                  }
                },
                backgroundColor: phaseColor,
                foregroundColor: Colors.white,
                child: Icon(
                  (!pom.isActive || pom.isPaused)
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

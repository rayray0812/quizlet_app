import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/models/pomodoro_state.dart';
import 'package:recall_app/providers/pomodoro_provider.dart';
import 'package:recall_app/features/pomodoro/widgets/pomodoro_panel.dart';

class PomodoroFab extends ConsumerStatefulWidget {
  const PomodoroFab({super.key});

  @override
  ConsumerState<PomodoroFab> createState() => _PomodoroFabState();
}

class _PomodoroFabState extends ConsumerState<PomodoroFab> {
  bool _expanded = false;

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final pom = ref.watch(pomodoroProvider);

    // Only show when timer is active
    if (!pom.isActive) return const SizedBox.shrink();

    final phaseColor = switch (pom.phase) {
      PomodoroPhase.study => AppTheme.indigo,
      PomodoroPhase.shortBreak => AppTheme.green,
      PomodoroPhase.longBreak => AppTheme.cyan,
    };

    if (_expanded) {
      return Positioned(
        bottom: 80,
        left: 0,
        right: 0,
        child: PomodoroPanel(
          onClose: () => setState(() => _expanded = false),
        ),
      );
    }

    return Positioned(
      bottom: 90,
      right: 16,
      child: GestureDetector(
        onTap: () => setState(() => _expanded = true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: phaseColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: phaseColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                pom.isPaused ? Icons.pause_rounded : Icons.timer_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                _formatTime(pom.remainingSeconds),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

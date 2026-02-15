import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/models/pomodoro_state.dart';

const _defaultStudyMinutes = 25;
const _defaultShortBreakMinutes = 5;
const _defaultLongBreakMinutes = 15;
const _sessionsBeforeLongBreak = 4;

final pomodoroProvider =
    StateNotifierProvider<PomodoroNotifier, PomodoroState>((ref) {
  return PomodoroNotifier();
});

class PomodoroNotifier extends StateNotifier<PomodoroState> {
  Timer? _timer;

  PomodoroNotifier() : super(const PomodoroState());

  int get _phaseDuration {
    return switch (state.phase) {
      PomodoroPhase.study => _defaultStudyMinutes * 60,
      PomodoroPhase.shortBreak => _defaultShortBreakMinutes * 60,
      PomodoroPhase.longBreak => _defaultLongBreakMinutes * 60,
    };
  }

  void start() {
    if (state.isActive && !state.isPaused) return;
    if (!state.isActive) {
      state = state.copyWith(
        isActive: true,
        isPaused: false,
        remainingSeconds: _phaseDuration,
      );
    } else {
      state = state.copyWith(isPaused: false);
    }
    _startTimer();
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  void reset() {
    _timer?.cancel();
    state = const PomodoroState();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remainingSeconds <= 1) {
        _timer?.cancel();
        _onPhaseComplete();
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  void _onPhaseComplete() {
    // Vibrate
    HapticFeedback.heavyImpact();

    if (state.phase == PomodoroPhase.study) {
      final newSessions = state.sessionsCompleted + 1;
      final isLongBreak = newSessions % _sessionsBeforeLongBreak == 0;
      final nextPhase =
          isLongBreak ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;
      state = state.copyWith(
        phase: nextPhase,
        sessionsCompleted: newSessions,
        remainingSeconds: isLongBreak
            ? _defaultLongBreakMinutes * 60
            : _defaultShortBreakMinutes * 60,
        isPaused: true,
      );
    } else {
      state = state.copyWith(
        phase: PomodoroPhase.study,
        remainingSeconds: _defaultStudyMinutes * 60,
        isPaused: true,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'pomodoro_state.freezed.dart';
part 'pomodoro_state.g.dart';

enum PomodoroPhase { study, shortBreak, longBreak }

@freezed
class PomodoroState with _$PomodoroState {
  const factory PomodoroState({
    @Default(PomodoroPhase.study) PomodoroPhase phase,
    @Default(1500) int remainingSeconds,
    @Default(0) int sessionsCompleted,
    @Default(true) bool isPaused,
    @Default(false) bool isActive,
  }) = _PomodoroState;

  factory PomodoroState.fromJson(Map<String, dynamic> json) =>
      _$PomodoroStateFromJson(json);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pomodoro_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PomodoroStateImpl _$$PomodoroStateImplFromJson(Map<String, dynamic> json) =>
    _$PomodoroStateImpl(
      phase:
          $enumDecodeNullable(_$PomodoroPhaseEnumMap, json['phase']) ??
          PomodoroPhase.study,
      remainingSeconds: (json['remainingSeconds'] as num?)?.toInt() ?? 1500,
      sessionsCompleted: (json['sessionsCompleted'] as num?)?.toInt() ?? 0,
      isPaused: json['isPaused'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? false,
    );

Map<String, dynamic> _$$PomodoroStateImplToJson(_$PomodoroStateImpl instance) =>
    <String, dynamic>{
      'phase': _$PomodoroPhaseEnumMap[instance.phase]!,
      'remainingSeconds': instance.remainingSeconds,
      'sessionsCompleted': instance.sessionsCompleted,
      'isPaused': instance.isPaused,
      'isActive': instance.isActive,
    };

const _$PomodoroPhaseEnumMap = {
  PomodoroPhase.study: 'study',
  PomodoroPhase.shortBreak: 'shortBreak',
  PomodoroPhase.longBreak: 'longBreak',
};

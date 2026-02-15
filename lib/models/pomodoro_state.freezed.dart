// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pomodoro_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PomodoroState _$PomodoroStateFromJson(Map<String, dynamic> json) {
  return _PomodoroState.fromJson(json);
}

/// @nodoc
mixin _$PomodoroState {
  PomodoroPhase get phase => throw _privateConstructorUsedError;
  int get remainingSeconds => throw _privateConstructorUsedError;
  int get sessionsCompleted => throw _privateConstructorUsedError;
  bool get isPaused => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;

  /// Serializes this PomodoroState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PomodoroState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PomodoroStateCopyWith<PomodoroState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PomodoroStateCopyWith<$Res> {
  factory $PomodoroStateCopyWith(
    PomodoroState value,
    $Res Function(PomodoroState) then,
  ) = _$PomodoroStateCopyWithImpl<$Res, PomodoroState>;
  @useResult
  $Res call({
    PomodoroPhase phase,
    int remainingSeconds,
    int sessionsCompleted,
    bool isPaused,
    bool isActive,
  });
}

/// @nodoc
class _$PomodoroStateCopyWithImpl<$Res, $Val extends PomodoroState>
    implements $PomodoroStateCopyWith<$Res> {
  _$PomodoroStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PomodoroState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? phase = null,
    Object? remainingSeconds = null,
    Object? sessionsCompleted = null,
    Object? isPaused = null,
    Object? isActive = null,
  }) {
    return _then(
      _value.copyWith(
            phase: null == phase
                ? _value.phase
                : phase // ignore: cast_nullable_to_non_nullable
                      as PomodoroPhase,
            remainingSeconds: null == remainingSeconds
                ? _value.remainingSeconds
                : remainingSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            sessionsCompleted: null == sessionsCompleted
                ? _value.sessionsCompleted
                : sessionsCompleted // ignore: cast_nullable_to_non_nullable
                      as int,
            isPaused: null == isPaused
                ? _value.isPaused
                : isPaused // ignore: cast_nullable_to_non_nullable
                      as bool,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PomodoroStateImplCopyWith<$Res>
    implements $PomodoroStateCopyWith<$Res> {
  factory _$$PomodoroStateImplCopyWith(
    _$PomodoroStateImpl value,
    $Res Function(_$PomodoroStateImpl) then,
  ) = __$$PomodoroStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    PomodoroPhase phase,
    int remainingSeconds,
    int sessionsCompleted,
    bool isPaused,
    bool isActive,
  });
}

/// @nodoc
class __$$PomodoroStateImplCopyWithImpl<$Res>
    extends _$PomodoroStateCopyWithImpl<$Res, _$PomodoroStateImpl>
    implements _$$PomodoroStateImplCopyWith<$Res> {
  __$$PomodoroStateImplCopyWithImpl(
    _$PomodoroStateImpl _value,
    $Res Function(_$PomodoroStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PomodoroState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? phase = null,
    Object? remainingSeconds = null,
    Object? sessionsCompleted = null,
    Object? isPaused = null,
    Object? isActive = null,
  }) {
    return _then(
      _$PomodoroStateImpl(
        phase: null == phase
            ? _value.phase
            : phase // ignore: cast_nullable_to_non_nullable
                  as PomodoroPhase,
        remainingSeconds: null == remainingSeconds
            ? _value.remainingSeconds
            : remainingSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        sessionsCompleted: null == sessionsCompleted
            ? _value.sessionsCompleted
            : sessionsCompleted // ignore: cast_nullable_to_non_nullable
                  as int,
        isPaused: null == isPaused
            ? _value.isPaused
            : isPaused // ignore: cast_nullable_to_non_nullable
                  as bool,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PomodoroStateImpl implements _PomodoroState {
  const _$PomodoroStateImpl({
    this.phase = PomodoroPhase.study,
    this.remainingSeconds = 1500,
    this.sessionsCompleted = 0,
    this.isPaused = true,
    this.isActive = false,
  });

  factory _$PomodoroStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$PomodoroStateImplFromJson(json);

  @override
  @JsonKey()
  final PomodoroPhase phase;
  @override
  @JsonKey()
  final int remainingSeconds;
  @override
  @JsonKey()
  final int sessionsCompleted;
  @override
  @JsonKey()
  final bool isPaused;
  @override
  @JsonKey()
  final bool isActive;

  @override
  String toString() {
    return 'PomodoroState(phase: $phase, remainingSeconds: $remainingSeconds, sessionsCompleted: $sessionsCompleted, isPaused: $isPaused, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PomodoroStateImpl &&
            (identical(other.phase, phase) || other.phase == phase) &&
            (identical(other.remainingSeconds, remainingSeconds) ||
                other.remainingSeconds == remainingSeconds) &&
            (identical(other.sessionsCompleted, sessionsCompleted) ||
                other.sessionsCompleted == sessionsCompleted) &&
            (identical(other.isPaused, isPaused) ||
                other.isPaused == isPaused) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    phase,
    remainingSeconds,
    sessionsCompleted,
    isPaused,
    isActive,
  );

  /// Create a copy of PomodoroState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PomodoroStateImplCopyWith<_$PomodoroStateImpl> get copyWith =>
      __$$PomodoroStateImplCopyWithImpl<_$PomodoroStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PomodoroStateImplToJson(this);
  }
}

abstract class _PomodoroState implements PomodoroState {
  const factory _PomodoroState({
    final PomodoroPhase phase,
    final int remainingSeconds,
    final int sessionsCompleted,
    final bool isPaused,
    final bool isActive,
  }) = _$PomodoroStateImpl;

  factory _PomodoroState.fromJson(Map<String, dynamic> json) =
      _$PomodoroStateImpl.fromJson;

  @override
  PomodoroPhase get phase;
  @override
  int get remainingSeconds;
  @override
  int get sessionsCompleted;
  @override
  bool get isPaused;
  @override
  bool get isActive;

  /// Create a copy of PomodoroState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PomodoroStateImplCopyWith<_$PomodoroStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CardProgress _$CardProgressFromJson(Map<String, dynamic> json) {
  return _CardProgress.fromJson(json);
}

/// @nodoc
mixin _$CardProgress {
  String get cardId => throw _privateConstructorUsedError;
  String get setId => throw _privateConstructorUsedError;
  double get stability => throw _privateConstructorUsedError;
  double get difficulty => throw _privateConstructorUsedError;
  int get reps => throw _privateConstructorUsedError;
  int get lapses => throw _privateConstructorUsedError;
  int get state =>
      throw _privateConstructorUsedError; // 0=New, 1=Learning, 2=Review, 3=Relearning
  DateTime? get lastReview => throw _privateConstructorUsedError;
  DateTime? get due => throw _privateConstructorUsedError;
  int get scheduledDays => throw _privateConstructorUsedError;
  int get elapsedDays => throw _privateConstructorUsedError;
  bool get isSynced => throw _privateConstructorUsedError;

  /// Serializes this CardProgress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CardProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CardProgressCopyWith<CardProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CardProgressCopyWith<$Res> {
  factory $CardProgressCopyWith(
    CardProgress value,
    $Res Function(CardProgress) then,
  ) = _$CardProgressCopyWithImpl<$Res, CardProgress>;
  @useResult
  $Res call({
    String cardId,
    String setId,
    double stability,
    double difficulty,
    int reps,
    int lapses,
    int state,
    DateTime? lastReview,
    DateTime? due,
    int scheduledDays,
    int elapsedDays,
    bool isSynced,
  });
}

/// @nodoc
class _$CardProgressCopyWithImpl<$Res, $Val extends CardProgress>
    implements $CardProgressCopyWith<$Res> {
  _$CardProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CardProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cardId = null,
    Object? setId = null,
    Object? stability = null,
    Object? difficulty = null,
    Object? reps = null,
    Object? lapses = null,
    Object? state = null,
    Object? lastReview = freezed,
    Object? due = freezed,
    Object? scheduledDays = null,
    Object? elapsedDays = null,
    Object? isSynced = null,
  }) {
    return _then(
      _value.copyWith(
            cardId: null == cardId
                ? _value.cardId
                : cardId // ignore: cast_nullable_to_non_nullable
                      as String,
            setId: null == setId
                ? _value.setId
                : setId // ignore: cast_nullable_to_non_nullable
                      as String,
            stability: null == stability
                ? _value.stability
                : stability // ignore: cast_nullable_to_non_nullable
                      as double,
            difficulty: null == difficulty
                ? _value.difficulty
                : difficulty // ignore: cast_nullable_to_non_nullable
                      as double,
            reps: null == reps
                ? _value.reps
                : reps // ignore: cast_nullable_to_non_nullable
                      as int,
            lapses: null == lapses
                ? _value.lapses
                : lapses // ignore: cast_nullable_to_non_nullable
                      as int,
            state: null == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                      as int,
            lastReview: freezed == lastReview
                ? _value.lastReview
                : lastReview // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            due: freezed == due
                ? _value.due
                : due // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            scheduledDays: null == scheduledDays
                ? _value.scheduledDays
                : scheduledDays // ignore: cast_nullable_to_non_nullable
                      as int,
            elapsedDays: null == elapsedDays
                ? _value.elapsedDays
                : elapsedDays // ignore: cast_nullable_to_non_nullable
                      as int,
            isSynced: null == isSynced
                ? _value.isSynced
                : isSynced // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CardProgressImplCopyWith<$Res>
    implements $CardProgressCopyWith<$Res> {
  factory _$$CardProgressImplCopyWith(
    _$CardProgressImpl value,
    $Res Function(_$CardProgressImpl) then,
  ) = __$$CardProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String cardId,
    String setId,
    double stability,
    double difficulty,
    int reps,
    int lapses,
    int state,
    DateTime? lastReview,
    DateTime? due,
    int scheduledDays,
    int elapsedDays,
    bool isSynced,
  });
}

/// @nodoc
class __$$CardProgressImplCopyWithImpl<$Res>
    extends _$CardProgressCopyWithImpl<$Res, _$CardProgressImpl>
    implements _$$CardProgressImplCopyWith<$Res> {
  __$$CardProgressImplCopyWithImpl(
    _$CardProgressImpl _value,
    $Res Function(_$CardProgressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CardProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cardId = null,
    Object? setId = null,
    Object? stability = null,
    Object? difficulty = null,
    Object? reps = null,
    Object? lapses = null,
    Object? state = null,
    Object? lastReview = freezed,
    Object? due = freezed,
    Object? scheduledDays = null,
    Object? elapsedDays = null,
    Object? isSynced = null,
  }) {
    return _then(
      _$CardProgressImpl(
        cardId: null == cardId
            ? _value.cardId
            : cardId // ignore: cast_nullable_to_non_nullable
                  as String,
        setId: null == setId
            ? _value.setId
            : setId // ignore: cast_nullable_to_non_nullable
                  as String,
        stability: null == stability
            ? _value.stability
            : stability // ignore: cast_nullable_to_non_nullable
                  as double,
        difficulty: null == difficulty
            ? _value.difficulty
            : difficulty // ignore: cast_nullable_to_non_nullable
                  as double,
        reps: null == reps
            ? _value.reps
            : reps // ignore: cast_nullable_to_non_nullable
                  as int,
        lapses: null == lapses
            ? _value.lapses
            : lapses // ignore: cast_nullable_to_non_nullable
                  as int,
        state: null == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
                  as int,
        lastReview: freezed == lastReview
            ? _value.lastReview
            : lastReview // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        due: freezed == due
            ? _value.due
            : due // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        scheduledDays: null == scheduledDays
            ? _value.scheduledDays
            : scheduledDays // ignore: cast_nullable_to_non_nullable
                  as int,
        elapsedDays: null == elapsedDays
            ? _value.elapsedDays
            : elapsedDays // ignore: cast_nullable_to_non_nullable
                  as int,
        isSynced: null == isSynced
            ? _value.isSynced
            : isSynced // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CardProgressImpl implements _CardProgress {
  const _$CardProgressImpl({
    required this.cardId,
    required this.setId,
    this.stability = 0.0,
    this.difficulty = 0.0,
    this.reps = 0,
    this.lapses = 0,
    this.state = 0,
    this.lastReview,
    this.due,
    this.scheduledDays = 0,
    this.elapsedDays = 0,
    this.isSynced = false,
  });

  factory _$CardProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$CardProgressImplFromJson(json);

  @override
  final String cardId;
  @override
  final String setId;
  @override
  @JsonKey()
  final double stability;
  @override
  @JsonKey()
  final double difficulty;
  @override
  @JsonKey()
  final int reps;
  @override
  @JsonKey()
  final int lapses;
  @override
  @JsonKey()
  final int state;
  // 0=New, 1=Learning, 2=Review, 3=Relearning
  @override
  final DateTime? lastReview;
  @override
  final DateTime? due;
  @override
  @JsonKey()
  final int scheduledDays;
  @override
  @JsonKey()
  final int elapsedDays;
  @override
  @JsonKey()
  final bool isSynced;

  @override
  String toString() {
    return 'CardProgress(cardId: $cardId, setId: $setId, stability: $stability, difficulty: $difficulty, reps: $reps, lapses: $lapses, state: $state, lastReview: $lastReview, due: $due, scheduledDays: $scheduledDays, elapsedDays: $elapsedDays, isSynced: $isSynced)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CardProgressImpl &&
            (identical(other.cardId, cardId) || other.cardId == cardId) &&
            (identical(other.setId, setId) || other.setId == setId) &&
            (identical(other.stability, stability) ||
                other.stability == stability) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.reps, reps) || other.reps == reps) &&
            (identical(other.lapses, lapses) || other.lapses == lapses) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.lastReview, lastReview) ||
                other.lastReview == lastReview) &&
            (identical(other.due, due) || other.due == due) &&
            (identical(other.scheduledDays, scheduledDays) ||
                other.scheduledDays == scheduledDays) &&
            (identical(other.elapsedDays, elapsedDays) ||
                other.elapsedDays == elapsedDays) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    cardId,
    setId,
    stability,
    difficulty,
    reps,
    lapses,
    state,
    lastReview,
    due,
    scheduledDays,
    elapsedDays,
    isSynced,
  );

  /// Create a copy of CardProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CardProgressImplCopyWith<_$CardProgressImpl> get copyWith =>
      __$$CardProgressImplCopyWithImpl<_$CardProgressImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CardProgressImplToJson(this);
  }
}

abstract class _CardProgress implements CardProgress {
  const factory _CardProgress({
    required final String cardId,
    required final String setId,
    final double stability,
    final double difficulty,
    final int reps,
    final int lapses,
    final int state,
    final DateTime? lastReview,
    final DateTime? due,
    final int scheduledDays,
    final int elapsedDays,
    final bool isSynced,
  }) = _$CardProgressImpl;

  factory _CardProgress.fromJson(Map<String, dynamic> json) =
      _$CardProgressImpl.fromJson;

  @override
  String get cardId;
  @override
  String get setId;
  @override
  double get stability;
  @override
  double get difficulty;
  @override
  int get reps;
  @override
  int get lapses;
  @override
  int get state; // 0=New, 1=Learning, 2=Review, 3=Relearning
  @override
  DateTime? get lastReview;
  @override
  DateTime? get due;
  @override
  int get scheduledDays;
  @override
  int get elapsedDays;
  @override
  bool get isSynced;

  /// Create a copy of CardProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CardProgressImplCopyWith<_$CardProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

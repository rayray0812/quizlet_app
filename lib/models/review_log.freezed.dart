// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ReviewLog _$ReviewLogFromJson(Map<String, dynamic> json) {
  return _ReviewLog.fromJson(json);
}

/// @nodoc
mixin _$ReviewLog {
  String get id => throw _privateConstructorUsedError;
  String get cardId => throw _privateConstructorUsedError;
  String get setId => throw _privateConstructorUsedError;
  int get rating =>
      throw _privateConstructorUsedError; // 1=Again, 2=Hard, 3=Good, 4=Easy
  int get state =>
      throw _privateConstructorUsedError; // card state at time of review
  DateTime get reviewedAt => throw _privateConstructorUsedError;
  String get reviewType => throw _privateConstructorUsedError;
  int? get speakingScore => throw _privateConstructorUsedError;
  int get elapsedDays => throw _privateConstructorUsedError;
  int get scheduledDays => throw _privateConstructorUsedError;
  double get lastStability => throw _privateConstructorUsedError;
  double get lastDifficulty => throw _privateConstructorUsedError;
  bool get isSynced => throw _privateConstructorUsedError;

  /// Serializes this ReviewLog to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReviewLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReviewLogCopyWith<ReviewLog> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReviewLogCopyWith<$Res> {
  factory $ReviewLogCopyWith(ReviewLog value, $Res Function(ReviewLog) then) =
      _$ReviewLogCopyWithImpl<$Res, ReviewLog>;
  @useResult
  $Res call({
    String id,
    String cardId,
    String setId,
    int rating,
    int state,
    DateTime reviewedAt,
    String reviewType,
    int? speakingScore,
    int elapsedDays,
    int scheduledDays,
    double lastStability,
    double lastDifficulty,
    bool isSynced,
  });
}

/// @nodoc
class _$ReviewLogCopyWithImpl<$Res, $Val extends ReviewLog>
    implements $ReviewLogCopyWith<$Res> {
  _$ReviewLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReviewLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? cardId = null,
    Object? setId = null,
    Object? rating = null,
    Object? state = null,
    Object? reviewedAt = null,
    Object? reviewType = null,
    Object? speakingScore = freezed,
    Object? elapsedDays = null,
    Object? scheduledDays = null,
    Object? lastStability = null,
    Object? lastDifficulty = null,
    Object? isSynced = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            cardId: null == cardId
                ? _value.cardId
                : cardId // ignore: cast_nullable_to_non_nullable
                      as String,
            setId: null == setId
                ? _value.setId
                : setId // ignore: cast_nullable_to_non_nullable
                      as String,
            rating: null == rating
                ? _value.rating
                : rating // ignore: cast_nullable_to_non_nullable
                      as int,
            state: null == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                      as int,
            reviewedAt: null == reviewedAt
                ? _value.reviewedAt
                : reviewedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            reviewType: null == reviewType
                ? _value.reviewType
                : reviewType // ignore: cast_nullable_to_non_nullable
                      as String,
            speakingScore: freezed == speakingScore
                ? _value.speakingScore
                : speakingScore // ignore: cast_nullable_to_non_nullable
                      as int?,
            elapsedDays: null == elapsedDays
                ? _value.elapsedDays
                : elapsedDays // ignore: cast_nullable_to_non_nullable
                      as int,
            scheduledDays: null == scheduledDays
                ? _value.scheduledDays
                : scheduledDays // ignore: cast_nullable_to_non_nullable
                      as int,
            lastStability: null == lastStability
                ? _value.lastStability
                : lastStability // ignore: cast_nullable_to_non_nullable
                      as double,
            lastDifficulty: null == lastDifficulty
                ? _value.lastDifficulty
                : lastDifficulty // ignore: cast_nullable_to_non_nullable
                      as double,
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
abstract class _$$ReviewLogImplCopyWith<$Res>
    implements $ReviewLogCopyWith<$Res> {
  factory _$$ReviewLogImplCopyWith(
    _$ReviewLogImpl value,
    $Res Function(_$ReviewLogImpl) then,
  ) = __$$ReviewLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String cardId,
    String setId,
    int rating,
    int state,
    DateTime reviewedAt,
    String reviewType,
    int? speakingScore,
    int elapsedDays,
    int scheduledDays,
    double lastStability,
    double lastDifficulty,
    bool isSynced,
  });
}

/// @nodoc
class __$$ReviewLogImplCopyWithImpl<$Res>
    extends _$ReviewLogCopyWithImpl<$Res, _$ReviewLogImpl>
    implements _$$ReviewLogImplCopyWith<$Res> {
  __$$ReviewLogImplCopyWithImpl(
    _$ReviewLogImpl _value,
    $Res Function(_$ReviewLogImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReviewLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? cardId = null,
    Object? setId = null,
    Object? rating = null,
    Object? state = null,
    Object? reviewedAt = null,
    Object? reviewType = null,
    Object? speakingScore = freezed,
    Object? elapsedDays = null,
    Object? scheduledDays = null,
    Object? lastStability = null,
    Object? lastDifficulty = null,
    Object? isSynced = null,
  }) {
    return _then(
      _$ReviewLogImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        cardId: null == cardId
            ? _value.cardId
            : cardId // ignore: cast_nullable_to_non_nullable
                  as String,
        setId: null == setId
            ? _value.setId
            : setId // ignore: cast_nullable_to_non_nullable
                  as String,
        rating: null == rating
            ? _value.rating
            : rating // ignore: cast_nullable_to_non_nullable
                  as int,
        state: null == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
                  as int,
        reviewedAt: null == reviewedAt
            ? _value.reviewedAt
            : reviewedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        reviewType: null == reviewType
            ? _value.reviewType
            : reviewType // ignore: cast_nullable_to_non_nullable
                  as String,
        speakingScore: freezed == speakingScore
            ? _value.speakingScore
            : speakingScore // ignore: cast_nullable_to_non_nullable
                  as int?,
        elapsedDays: null == elapsedDays
            ? _value.elapsedDays
            : elapsedDays // ignore: cast_nullable_to_non_nullable
                  as int,
        scheduledDays: null == scheduledDays
            ? _value.scheduledDays
            : scheduledDays // ignore: cast_nullable_to_non_nullable
                  as int,
        lastStability: null == lastStability
            ? _value.lastStability
            : lastStability // ignore: cast_nullable_to_non_nullable
                  as double,
        lastDifficulty: null == lastDifficulty
            ? _value.lastDifficulty
            : lastDifficulty // ignore: cast_nullable_to_non_nullable
                  as double,
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
class _$ReviewLogImpl implements _ReviewLog {
  const _$ReviewLogImpl({
    required this.id,
    required this.cardId,
    required this.setId,
    required this.rating,
    required this.state,
    required this.reviewedAt,
    this.reviewType = 'srs',
    this.speakingScore,
    this.elapsedDays = 0,
    this.scheduledDays = 0,
    this.lastStability = 0.0,
    this.lastDifficulty = 0.0,
    this.isSynced = false,
  });

  factory _$ReviewLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReviewLogImplFromJson(json);

  @override
  final String id;
  @override
  final String cardId;
  @override
  final String setId;
  @override
  final int rating;
  // 1=Again, 2=Hard, 3=Good, 4=Easy
  @override
  final int state;
  // card state at time of review
  @override
  final DateTime reviewedAt;
  @override
  @JsonKey()
  final String reviewType;
  @override
  final int? speakingScore;
  @override
  @JsonKey()
  final int elapsedDays;
  @override
  @JsonKey()
  final int scheduledDays;
  @override
  @JsonKey()
  final double lastStability;
  @override
  @JsonKey()
  final double lastDifficulty;
  @override
  @JsonKey()
  final bool isSynced;

  @override
  String toString() {
    return 'ReviewLog(id: $id, cardId: $cardId, setId: $setId, rating: $rating, state: $state, reviewedAt: $reviewedAt, reviewType: $reviewType, speakingScore: $speakingScore, elapsedDays: $elapsedDays, scheduledDays: $scheduledDays, lastStability: $lastStability, lastDifficulty: $lastDifficulty, isSynced: $isSynced)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReviewLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.cardId, cardId) || other.cardId == cardId) &&
            (identical(other.setId, setId) || other.setId == setId) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.reviewedAt, reviewedAt) ||
                other.reviewedAt == reviewedAt) &&
            (identical(other.reviewType, reviewType) ||
                other.reviewType == reviewType) &&
            (identical(other.speakingScore, speakingScore) ||
                other.speakingScore == speakingScore) &&
            (identical(other.elapsedDays, elapsedDays) ||
                other.elapsedDays == elapsedDays) &&
            (identical(other.scheduledDays, scheduledDays) ||
                other.scheduledDays == scheduledDays) &&
            (identical(other.lastStability, lastStability) ||
                other.lastStability == lastStability) &&
            (identical(other.lastDifficulty, lastDifficulty) ||
                other.lastDifficulty == lastDifficulty) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    cardId,
    setId,
    rating,
    state,
    reviewedAt,
    reviewType,
    speakingScore,
    elapsedDays,
    scheduledDays,
    lastStability,
    lastDifficulty,
    isSynced,
  );

  /// Create a copy of ReviewLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReviewLogImplCopyWith<_$ReviewLogImpl> get copyWith =>
      __$$ReviewLogImplCopyWithImpl<_$ReviewLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReviewLogImplToJson(this);
  }
}

abstract class _ReviewLog implements ReviewLog {
  const factory _ReviewLog({
    required final String id,
    required final String cardId,
    required final String setId,
    required final int rating,
    required final int state,
    required final DateTime reviewedAt,
    final String reviewType,
    final int? speakingScore,
    final int elapsedDays,
    final int scheduledDays,
    final double lastStability,
    final double lastDifficulty,
    final bool isSynced,
  }) = _$ReviewLogImpl;

  factory _ReviewLog.fromJson(Map<String, dynamic> json) =
      _$ReviewLogImpl.fromJson;

  @override
  String get id;
  @override
  String get cardId;
  @override
  String get setId;
  @override
  int get rating; // 1=Again, 2=Hard, 3=Good, 4=Easy
  @override
  int get state; // card state at time of review
  @override
  DateTime get reviewedAt;
  @override
  String get reviewType;
  @override
  int? get speakingScore;
  @override
  int get elapsedDays;
  @override
  int get scheduledDays;
  @override
  double get lastStability;
  @override
  double get lastDifficulty;
  @override
  bool get isSynced;

  /// Create a copy of ReviewLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReviewLogImplCopyWith<_$ReviewLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

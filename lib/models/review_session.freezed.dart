// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ReviewSession _$ReviewSessionFromJson(Map<String, dynamic> json) {
  return _ReviewSession.fromJson(json);
}

/// @nodoc
mixin _$ReviewSession {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get modality =>
      throw _privateConstructorUsedError; // srs | quiz | match | speaking | conversation
  DateTime get startedAt => throw _privateConstructorUsedError;
  DateTime? get endedAt => throw _privateConstructorUsedError;
  int get itemCount => throw _privateConstructorUsedError;
  int get completedCount => throw _privateConstructorUsedError;
  double? get scoreAvg => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;
  bool get isSynced => throw _privateConstructorUsedError;

  /// Serializes this ReviewSession to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReviewSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReviewSessionCopyWith<ReviewSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReviewSessionCopyWith<$Res> {
  factory $ReviewSessionCopyWith(
    ReviewSession value,
    $Res Function(ReviewSession) then,
  ) = _$ReviewSessionCopyWithImpl<$Res, ReviewSession>;
  @useResult
  $Res call({
    String id,
    String userId,
    String modality,
    DateTime startedAt,
    DateTime? endedAt,
    int itemCount,
    int completedCount,
    double? scoreAvg,
    Map<String, dynamic>? metadata,
    bool isSynced,
  });
}

/// @nodoc
class _$ReviewSessionCopyWithImpl<$Res, $Val extends ReviewSession>
    implements $ReviewSessionCopyWith<$Res> {
  _$ReviewSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReviewSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? modality = null,
    Object? startedAt = null,
    Object? endedAt = freezed,
    Object? itemCount = null,
    Object? completedCount = null,
    Object? scoreAvg = freezed,
    Object? metadata = freezed,
    Object? isSynced = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            modality: null == modality
                ? _value.modality
                : modality // ignore: cast_nullable_to_non_nullable
                      as String,
            startedAt: null == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endedAt: freezed == endedAt
                ? _value.endedAt
                : endedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            itemCount: null == itemCount
                ? _value.itemCount
                : itemCount // ignore: cast_nullable_to_non_nullable
                      as int,
            completedCount: null == completedCount
                ? _value.completedCount
                : completedCount // ignore: cast_nullable_to_non_nullable
                      as int,
            scoreAvg: freezed == scoreAvg
                ? _value.scoreAvg
                : scoreAvg // ignore: cast_nullable_to_non_nullable
                      as double?,
            metadata: freezed == metadata
                ? _value.metadata
                : metadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
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
abstract class _$$ReviewSessionImplCopyWith<$Res>
    implements $ReviewSessionCopyWith<$Res> {
  factory _$$ReviewSessionImplCopyWith(
    _$ReviewSessionImpl value,
    $Res Function(_$ReviewSessionImpl) then,
  ) = __$$ReviewSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String modality,
    DateTime startedAt,
    DateTime? endedAt,
    int itemCount,
    int completedCount,
    double? scoreAvg,
    Map<String, dynamic>? metadata,
    bool isSynced,
  });
}

/// @nodoc
class __$$ReviewSessionImplCopyWithImpl<$Res>
    extends _$ReviewSessionCopyWithImpl<$Res, _$ReviewSessionImpl>
    implements _$$ReviewSessionImplCopyWith<$Res> {
  __$$ReviewSessionImplCopyWithImpl(
    _$ReviewSessionImpl _value,
    $Res Function(_$ReviewSessionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReviewSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? modality = null,
    Object? startedAt = null,
    Object? endedAt = freezed,
    Object? itemCount = null,
    Object? completedCount = null,
    Object? scoreAvg = freezed,
    Object? metadata = freezed,
    Object? isSynced = null,
  }) {
    return _then(
      _$ReviewSessionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        modality: null == modality
            ? _value.modality
            : modality // ignore: cast_nullable_to_non_nullable
                  as String,
        startedAt: null == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endedAt: freezed == endedAt
            ? _value.endedAt
            : endedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        itemCount: null == itemCount
            ? _value.itemCount
            : itemCount // ignore: cast_nullable_to_non_nullable
                  as int,
        completedCount: null == completedCount
            ? _value.completedCount
            : completedCount // ignore: cast_nullable_to_non_nullable
                  as int,
        scoreAvg: freezed == scoreAvg
            ? _value.scoreAvg
            : scoreAvg // ignore: cast_nullable_to_non_nullable
                  as double?,
        metadata: freezed == metadata
            ? _value._metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
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
class _$ReviewSessionImpl implements _ReviewSession {
  const _$ReviewSessionImpl({
    required this.id,
    required this.userId,
    required this.modality,
    required this.startedAt,
    this.endedAt,
    this.itemCount = 0,
    this.completedCount = 0,
    this.scoreAvg,
    final Map<String, dynamic>? metadata,
    this.isSynced = false,
  }) : _metadata = metadata;

  factory _$ReviewSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReviewSessionImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String modality;
  // srs | quiz | match | speaking | conversation
  @override
  final DateTime startedAt;
  @override
  final DateTime? endedAt;
  @override
  @JsonKey()
  final int itemCount;
  @override
  @JsonKey()
  final int completedCount;
  @override
  final double? scoreAvg;
  final Map<String, dynamic>? _metadata;
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey()
  final bool isSynced;

  @override
  String toString() {
    return 'ReviewSession(id: $id, userId: $userId, modality: $modality, startedAt: $startedAt, endedAt: $endedAt, itemCount: $itemCount, completedCount: $completedCount, scoreAvg: $scoreAvg, metadata: $metadata, isSynced: $isSynced)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReviewSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.modality, modality) ||
                other.modality == modality) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.itemCount, itemCount) ||
                other.itemCount == itemCount) &&
            (identical(other.completedCount, completedCount) ||
                other.completedCount == completedCount) &&
            (identical(other.scoreAvg, scoreAvg) ||
                other.scoreAvg == scoreAvg) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    modality,
    startedAt,
    endedAt,
    itemCount,
    completedCount,
    scoreAvg,
    const DeepCollectionEquality().hash(_metadata),
    isSynced,
  );

  /// Create a copy of ReviewSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReviewSessionImplCopyWith<_$ReviewSessionImpl> get copyWith =>
      __$$ReviewSessionImplCopyWithImpl<_$ReviewSessionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReviewSessionImplToJson(this);
  }
}

abstract class _ReviewSession implements ReviewSession {
  const factory _ReviewSession({
    required final String id,
    required final String userId,
    required final String modality,
    required final DateTime startedAt,
    final DateTime? endedAt,
    final int itemCount,
    final int completedCount,
    final double? scoreAvg,
    final Map<String, dynamic>? metadata,
    final bool isSynced,
  }) = _$ReviewSessionImpl;

  factory _ReviewSession.fromJson(Map<String, dynamic> json) =
      _$ReviewSessionImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get modality; // srs | quiz | match | speaking | conversation
  @override
  DateTime get startedAt;
  @override
  DateTime? get endedAt;
  @override
  int get itemCount;
  @override
  int get completedCount;
  @override
  double? get scoreAvg;
  @override
  Map<String, dynamic>? get metadata;
  @override
  bool get isSynced;

  /// Create a copy of ReviewSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReviewSessionImplCopyWith<_$ReviewSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

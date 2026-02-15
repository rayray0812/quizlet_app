// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'badge.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AppBadge _$AppBadgeFromJson(Map<String, dynamic> json) {
  return _AppBadge.fromJson(json);
}

/// @nodoc
mixin _$AppBadge {
  String get id => throw _privateConstructorUsedError;
  String get titleKey => throw _privateConstructorUsedError;
  String get descKey => throw _privateConstructorUsedError;
  int get iconCodePoint => throw _privateConstructorUsedError;
  DateTime? get unlockedAt => throw _privateConstructorUsedError;
  bool get isUnlocked => throw _privateConstructorUsedError;

  /// Serializes this AppBadge to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppBadge
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppBadgeCopyWith<AppBadge> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppBadgeCopyWith<$Res> {
  factory $AppBadgeCopyWith(AppBadge value, $Res Function(AppBadge) then) =
      _$AppBadgeCopyWithImpl<$Res, AppBadge>;
  @useResult
  $Res call({
    String id,
    String titleKey,
    String descKey,
    int iconCodePoint,
    DateTime? unlockedAt,
    bool isUnlocked,
  });
}

/// @nodoc
class _$AppBadgeCopyWithImpl<$Res, $Val extends AppBadge>
    implements $AppBadgeCopyWith<$Res> {
  _$AppBadgeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppBadge
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? titleKey = null,
    Object? descKey = null,
    Object? iconCodePoint = null,
    Object? unlockedAt = freezed,
    Object? isUnlocked = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            titleKey: null == titleKey
                ? _value.titleKey
                : titleKey // ignore: cast_nullable_to_non_nullable
                      as String,
            descKey: null == descKey
                ? _value.descKey
                : descKey // ignore: cast_nullable_to_non_nullable
                      as String,
            iconCodePoint: null == iconCodePoint
                ? _value.iconCodePoint
                : iconCodePoint // ignore: cast_nullable_to_non_nullable
                      as int,
            unlockedAt: freezed == unlockedAt
                ? _value.unlockedAt
                : unlockedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            isUnlocked: null == isUnlocked
                ? _value.isUnlocked
                : isUnlocked // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppBadgeImplCopyWith<$Res>
    implements $AppBadgeCopyWith<$Res> {
  factory _$$AppBadgeImplCopyWith(
    _$AppBadgeImpl value,
    $Res Function(_$AppBadgeImpl) then,
  ) = __$$AppBadgeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String titleKey,
    String descKey,
    int iconCodePoint,
    DateTime? unlockedAt,
    bool isUnlocked,
  });
}

/// @nodoc
class __$$AppBadgeImplCopyWithImpl<$Res>
    extends _$AppBadgeCopyWithImpl<$Res, _$AppBadgeImpl>
    implements _$$AppBadgeImplCopyWith<$Res> {
  __$$AppBadgeImplCopyWithImpl(
    _$AppBadgeImpl _value,
    $Res Function(_$AppBadgeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppBadge
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? titleKey = null,
    Object? descKey = null,
    Object? iconCodePoint = null,
    Object? unlockedAt = freezed,
    Object? isUnlocked = null,
  }) {
    return _then(
      _$AppBadgeImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        titleKey: null == titleKey
            ? _value.titleKey
            : titleKey // ignore: cast_nullable_to_non_nullable
                  as String,
        descKey: null == descKey
            ? _value.descKey
            : descKey // ignore: cast_nullable_to_non_nullable
                  as String,
        iconCodePoint: null == iconCodePoint
            ? _value.iconCodePoint
            : iconCodePoint // ignore: cast_nullable_to_non_nullable
                  as int,
        unlockedAt: freezed == unlockedAt
            ? _value.unlockedAt
            : unlockedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isUnlocked: null == isUnlocked
            ? _value.isUnlocked
            : isUnlocked // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AppBadgeImpl implements _AppBadge {
  const _$AppBadgeImpl({
    required this.id,
    required this.titleKey,
    required this.descKey,
    required this.iconCodePoint,
    this.unlockedAt,
    this.isUnlocked = false,
  });

  factory _$AppBadgeImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppBadgeImplFromJson(json);

  @override
  final String id;
  @override
  final String titleKey;
  @override
  final String descKey;
  @override
  final int iconCodePoint;
  @override
  final DateTime? unlockedAt;
  @override
  @JsonKey()
  final bool isUnlocked;

  @override
  String toString() {
    return 'AppBadge(id: $id, titleKey: $titleKey, descKey: $descKey, iconCodePoint: $iconCodePoint, unlockedAt: $unlockedAt, isUnlocked: $isUnlocked)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppBadgeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.titleKey, titleKey) ||
                other.titleKey == titleKey) &&
            (identical(other.descKey, descKey) || other.descKey == descKey) &&
            (identical(other.iconCodePoint, iconCodePoint) ||
                other.iconCodePoint == iconCodePoint) &&
            (identical(other.unlockedAt, unlockedAt) ||
                other.unlockedAt == unlockedAt) &&
            (identical(other.isUnlocked, isUnlocked) ||
                other.isUnlocked == isUnlocked));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    titleKey,
    descKey,
    iconCodePoint,
    unlockedAt,
    isUnlocked,
  );

  /// Create a copy of AppBadge
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppBadgeImplCopyWith<_$AppBadgeImpl> get copyWith =>
      __$$AppBadgeImplCopyWithImpl<_$AppBadgeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppBadgeImplToJson(this);
  }
}

abstract class _AppBadge implements AppBadge {
  const factory _AppBadge({
    required final String id,
    required final String titleKey,
    required final String descKey,
    required final int iconCodePoint,
    final DateTime? unlockedAt,
    final bool isUnlocked,
  }) = _$AppBadgeImpl;

  factory _AppBadge.fromJson(Map<String, dynamic> json) =
      _$AppBadgeImpl.fromJson;

  @override
  String get id;
  @override
  String get titleKey;
  @override
  String get descKey;
  @override
  int get iconCodePoint;
  @override
  DateTime? get unlockedAt;
  @override
  bool get isUnlocked;

  /// Create a copy of AppBadge
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppBadgeImplCopyWith<_$AppBadgeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'study_set.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

StudySet _$StudySetFromJson(Map<String, dynamic> json) {
  return _StudySet.fromJson(json);
}

/// @nodoc
mixin _$StudySet {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  List<Flashcard> get cards => throw _privateConstructorUsedError;
  bool get isSynced => throw _privateConstructorUsedError;

  /// Serializes this StudySet to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StudySet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StudySetCopyWith<StudySet> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StudySetCopyWith<$Res> {
  factory $StudySetCopyWith(StudySet value, $Res Function(StudySet) then) =
      _$StudySetCopyWithImpl<$Res, StudySet>;
  @useResult
  $Res call({
    String id,
    String title,
    String description,
    DateTime createdAt,
    DateTime? updatedAt,
    List<Flashcard> cards,
    bool isSynced,
  });
}

/// @nodoc
class _$StudySetCopyWithImpl<$Res, $Val extends StudySet>
    implements $StudySetCopyWith<$Res> {
  _$StudySetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StudySet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? cards = null,
    Object? isSynced = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            cards: null == cards
                ? _value.cards
                : cards // ignore: cast_nullable_to_non_nullable
                      as List<Flashcard>,
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
abstract class _$$StudySetImplCopyWith<$Res>
    implements $StudySetCopyWith<$Res> {
  factory _$$StudySetImplCopyWith(
    _$StudySetImpl value,
    $Res Function(_$StudySetImpl) then,
  ) = __$$StudySetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String description,
    DateTime createdAt,
    DateTime? updatedAt,
    List<Flashcard> cards,
    bool isSynced,
  });
}

/// @nodoc
class __$$StudySetImplCopyWithImpl<$Res>
    extends _$StudySetCopyWithImpl<$Res, _$StudySetImpl>
    implements _$$StudySetImplCopyWith<$Res> {
  __$$StudySetImplCopyWithImpl(
    _$StudySetImpl _value,
    $Res Function(_$StudySetImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StudySet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? cards = null,
    Object? isSynced = null,
  }) {
    return _then(
      _$StudySetImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        cards: null == cards
            ? _value._cards
            : cards // ignore: cast_nullable_to_non_nullable
                  as List<Flashcard>,
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
class _$StudySetImpl implements _StudySet {
  const _$StudySetImpl({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdAt,
    this.updatedAt,
    final List<Flashcard> cards = const [],
    this.isSynced = false,
  }) : _cards = cards;

  factory _$StudySetImpl.fromJson(Map<String, dynamic> json) =>
      _$$StudySetImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey()
  final String description;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  final List<Flashcard> _cards;
  @override
  @JsonKey()
  List<Flashcard> get cards {
    if (_cards is EqualUnmodifiableListView) return _cards;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cards);
  }

  @override
  @JsonKey()
  final bool isSynced;

  @override
  String toString() {
    return 'StudySet(id: $id, title: $title, description: $description, createdAt: $createdAt, updatedAt: $updatedAt, cards: $cards, isSynced: $isSynced)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StudySetImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other._cards, _cards) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    description,
    createdAt,
    updatedAt,
    const DeepCollectionEquality().hash(_cards),
    isSynced,
  );

  /// Create a copy of StudySet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StudySetImplCopyWith<_$StudySetImpl> get copyWith =>
      __$$StudySetImplCopyWithImpl<_$StudySetImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StudySetImplToJson(this);
  }
}

abstract class _StudySet implements StudySet {
  const factory _StudySet({
    required final String id,
    required final String title,
    final String description,
    required final DateTime createdAt,
    final DateTime? updatedAt,
    final List<Flashcard> cards,
    final bool isSynced,
  }) = _$StudySetImpl;

  factory _StudySet.fromJson(Map<String, dynamic> json) =
      _$StudySetImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  DateTime get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  List<Flashcard> get cards;
  @override
  bool get isSynced;

  /// Create a copy of StudySet
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StudySetImplCopyWith<_$StudySetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

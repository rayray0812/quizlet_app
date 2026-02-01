// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'flashcard.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Flashcard _$FlashcardFromJson(Map<String, dynamic> json) {
  return _Flashcard.fromJson(json);
}

/// @nodoc
mixin _$Flashcard {
  String get id => throw _privateConstructorUsedError;
  String get term => throw _privateConstructorUsedError;
  String get definition => throw _privateConstructorUsedError;
  int get difficultyLevel => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;

  /// Serializes this Flashcard to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Flashcard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FlashcardCopyWith<Flashcard> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FlashcardCopyWith<$Res> {
  factory $FlashcardCopyWith(Flashcard value, $Res Function(Flashcard) then) =
      _$FlashcardCopyWithImpl<$Res, Flashcard>;
  @useResult
  $Res call({
    String id,
    String term,
    String definition,
    int difficultyLevel,
    String imageUrl,
    List<String> tags,
  });
}

/// @nodoc
class _$FlashcardCopyWithImpl<$Res, $Val extends Flashcard>
    implements $FlashcardCopyWith<$Res> {
  _$FlashcardCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Flashcard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? term = null,
    Object? definition = null,
    Object? difficultyLevel = null,
    Object? imageUrl = null,
    Object? tags = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            term: null == term
                ? _value.term
                : term // ignore: cast_nullable_to_non_nullable
                      as String,
            definition: null == definition
                ? _value.definition
                : definition // ignore: cast_nullable_to_non_nullable
                      as String,
            difficultyLevel: null == difficultyLevel
                ? _value.difficultyLevel
                : difficultyLevel // ignore: cast_nullable_to_non_nullable
                      as int,
            imageUrl: null == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FlashcardImplCopyWith<$Res>
    implements $FlashcardCopyWith<$Res> {
  factory _$$FlashcardImplCopyWith(
    _$FlashcardImpl value,
    $Res Function(_$FlashcardImpl) then,
  ) = __$$FlashcardImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String term,
    String definition,
    int difficultyLevel,
    String imageUrl,
    List<String> tags,
  });
}

/// @nodoc
class __$$FlashcardImplCopyWithImpl<$Res>
    extends _$FlashcardCopyWithImpl<$Res, _$FlashcardImpl>
    implements _$$FlashcardImplCopyWith<$Res> {
  __$$FlashcardImplCopyWithImpl(
    _$FlashcardImpl _value,
    $Res Function(_$FlashcardImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Flashcard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? term = null,
    Object? definition = null,
    Object? difficultyLevel = null,
    Object? imageUrl = null,
    Object? tags = null,
  }) {
    return _then(
      _$FlashcardImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        term: null == term
            ? _value.term
            : term // ignore: cast_nullable_to_non_nullable
                  as String,
        definition: null == definition
            ? _value.definition
            : definition // ignore: cast_nullable_to_non_nullable
                  as String,
        difficultyLevel: null == difficultyLevel
            ? _value.difficultyLevel
            : difficultyLevel // ignore: cast_nullable_to_non_nullable
                  as int,
        imageUrl: null == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FlashcardImpl implements _Flashcard {
  const _$FlashcardImpl({
    required this.id,
    required this.term,
    required this.definition,
    this.difficultyLevel = 0,
    this.imageUrl = '',
    final List<String> tags = const [],
  }) : _tags = tags;

  factory _$FlashcardImpl.fromJson(Map<String, dynamic> json) =>
      _$$FlashcardImplFromJson(json);

  @override
  final String id;
  @override
  final String term;
  @override
  final String definition;
  @override
  @JsonKey()
  final int difficultyLevel;
  @override
  @JsonKey()
  final String imageUrl;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'Flashcard(id: $id, term: $term, definition: $definition, difficultyLevel: $difficultyLevel, imageUrl: $imageUrl, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FlashcardImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.term, term) || other.term == term) &&
            (identical(other.definition, definition) ||
                other.definition == definition) &&
            (identical(other.difficultyLevel, difficultyLevel) ||
                other.difficultyLevel == difficultyLevel) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    term,
    definition,
    difficultyLevel,
    imageUrl,
    const DeepCollectionEquality().hash(_tags),
  );

  /// Create a copy of Flashcard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FlashcardImplCopyWith<_$FlashcardImpl> get copyWith =>
      __$$FlashcardImplCopyWithImpl<_$FlashcardImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FlashcardImplToJson(this);
  }
}

abstract class _Flashcard implements Flashcard {
  const factory _Flashcard({
    required final String id,
    required final String term,
    required final String definition,
    final int difficultyLevel,
    final String imageUrl,
    final List<String> tags,
  }) = _$FlashcardImpl;

  factory _Flashcard.fromJson(Map<String, dynamic> json) =
      _$FlashcardImpl.fromJson;

  @override
  String get id;
  @override
  String get term;
  @override
  String get definition;
  @override
  int get difficultyLevel;
  @override
  String get imageUrl;
  @override
  List<String> get tags;

  /// Create a copy of Flashcard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FlashcardImplCopyWith<_$FlashcardImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

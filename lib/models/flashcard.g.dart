// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FlashcardImpl _$$FlashcardImplFromJson(Map<String, dynamic> json) =>
    _$FlashcardImpl(
      id: json['id'] as String,
      term: json['term'] as String,
      definition: json['definition'] as String,
      difficultyLevel: (json['difficultyLevel'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$FlashcardImplToJson(_$FlashcardImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'term': instance.term,
      'definition': instance.definition,
      'difficultyLevel': instance.difficultyLevel,
    };

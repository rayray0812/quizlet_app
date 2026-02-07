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
      exampleSentence: json['exampleSentence'] as String? ?? '',
      difficultyLevel: (json['difficultyLevel'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
    );

Map<String, dynamic> _$$FlashcardImplToJson(_$FlashcardImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'term': instance.term,
      'definition': instance.definition,
      'exampleSentence': instance.exampleSentence,
      'difficultyLevel': instance.difficultyLevel,
      'imageUrl': instance.imageUrl,
      'tags': instance.tags,
    };

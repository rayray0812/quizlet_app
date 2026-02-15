// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StudySetImpl _$$StudySetImplFromJson(Map<String, dynamic> json) =>
    _$StudySetImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      cards:
          (json['cards'] as List<dynamic>?)
              ?.map((e) => Flashcard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isSynced: json['isSynced'] as bool? ?? false,
      folderId: json['folderId'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
      lastStudiedAt: json['lastStudiedAt'] == null
          ? null
          : DateTime.parse(json['lastStudiedAt'] as String),
    );

Map<String, dynamic> _$$StudySetImplToJson(_$StudySetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'cards': instance.cards,
      'isSynced': instance.isSynced,
      'folderId': instance.folderId,
      'isPinned': instance.isPinned,
      'lastStudiedAt': instance.lastStudiedAt?.toIso8601String(),
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReviewSessionImpl _$$ReviewSessionImplFromJson(Map<String, dynamic> json) =>
    _$ReviewSessionImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      modality: json['modality'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      scoreAvg: (json['scoreAvg'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      isSynced: json['isSynced'] as bool? ?? false,
    );

Map<String, dynamic> _$$ReviewSessionImplToJson(_$ReviewSessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'modality': instance.modality,
      'startedAt': instance.startedAt.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'itemCount': instance.itemCount,
      'completedCount': instance.completedCount,
      'scoreAvg': instance.scoreAvg,
      'metadata': instance.metadata,
      'isSynced': instance.isSynced,
    };

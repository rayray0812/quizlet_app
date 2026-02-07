// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReviewLogImpl _$$ReviewLogImplFromJson(Map<String, dynamic> json) =>
    _$ReviewLogImpl(
      id: json['id'] as String,
      cardId: json['cardId'] as String,
      setId: json['setId'] as String,
      rating: (json['rating'] as num).toInt(),
      state: (json['state'] as num).toInt(),
      reviewedAt: DateTime.parse(json['reviewedAt'] as String),
      reviewType: json['reviewType'] as String? ?? 'srs',
      speakingScore: (json['speakingScore'] as num?)?.toInt(),
      elapsedDays: (json['elapsedDays'] as num?)?.toInt() ?? 0,
      scheduledDays: (json['scheduledDays'] as num?)?.toInt() ?? 0,
      lastStability: (json['lastStability'] as num?)?.toDouble() ?? 0.0,
      lastDifficulty: (json['lastDifficulty'] as num?)?.toDouble() ?? 0.0,
      isSynced: json['isSynced'] as bool? ?? false,
    );

Map<String, dynamic> _$$ReviewLogImplToJson(_$ReviewLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cardId': instance.cardId,
      'setId': instance.setId,
      'rating': instance.rating,
      'state': instance.state,
      'reviewedAt': instance.reviewedAt.toIso8601String(),
      'reviewType': instance.reviewType,
      'speakingScore': instance.speakingScore,
      'elapsedDays': instance.elapsedDays,
      'scheduledDays': instance.scheduledDays,
      'lastStability': instance.lastStability,
      'lastDifficulty': instance.lastDifficulty,
      'isSynced': instance.isSynced,
    };

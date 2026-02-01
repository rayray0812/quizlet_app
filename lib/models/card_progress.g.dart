// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CardProgressImpl _$$CardProgressImplFromJson(Map<String, dynamic> json) =>
    _$CardProgressImpl(
      cardId: json['cardId'] as String,
      setId: json['setId'] as String,
      stability: (json['stability'] as num?)?.toDouble() ?? 0.0,
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0.0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      lapses: (json['lapses'] as num?)?.toInt() ?? 0,
      state: (json['state'] as num?)?.toInt() ?? 0,
      lastReview: json['lastReview'] == null
          ? null
          : DateTime.parse(json['lastReview'] as String),
      due: json['due'] == null ? null : DateTime.parse(json['due'] as String),
      scheduledDays: (json['scheduledDays'] as num?)?.toInt() ?? 0,
      elapsedDays: (json['elapsedDays'] as num?)?.toInt() ?? 0,
      isSynced: json['isSynced'] as bool? ?? false,
    );

Map<String, dynamic> _$$CardProgressImplToJson(_$CardProgressImpl instance) =>
    <String, dynamic>{
      'cardId': instance.cardId,
      'setId': instance.setId,
      'stability': instance.stability,
      'difficulty': instance.difficulty,
      'reps': instance.reps,
      'lapses': instance.lapses,
      'state': instance.state,
      'lastReview': instance.lastReview?.toIso8601String(),
      'due': instance.due?.toIso8601String(),
      'scheduledDays': instance.scheduledDays,
      'elapsedDays': instance.elapsedDays,
      'isSynced': instance.isSynced,
    };

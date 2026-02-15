// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppBadgeImpl _$$AppBadgeImplFromJson(Map<String, dynamic> json) =>
    _$AppBadgeImpl(
      id: json['id'] as String,
      titleKey: json['titleKey'] as String,
      descKey: json['descKey'] as String,
      iconCodePoint: (json['iconCodePoint'] as num).toInt(),
      unlockedAt: json['unlockedAt'] == null
          ? null
          : DateTime.parse(json['unlockedAt'] as String),
      isUnlocked: json['isUnlocked'] as bool? ?? false,
    );

Map<String, dynamic> _$$AppBadgeImplToJson(_$AppBadgeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titleKey': instance.titleKey,
      'descKey': instance.descKey,
      'iconCodePoint': instance.iconCodePoint,
      'unlockedAt': instance.unlockedAt?.toIso8601String(),
      'isUnlocked': instance.isUnlocked,
    };

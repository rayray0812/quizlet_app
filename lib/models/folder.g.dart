// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FolderImpl _$$FolderImplFromJson(Map<String, dynamic> json) => _$FolderImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  colorHex: json['colorHex'] as String? ?? 'FF6366F1',
  iconCodePoint: (json['iconCodePoint'] as num?)?.toInt() ?? 0xe6c4,
  isSynced: json['isSynced'] as bool? ?? false,
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$FolderImplToJson(_$FolderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'colorHex': instance.colorHex,
      'iconCodePoint': instance.iconCodePoint,
      'isSynced': instance.isSynced,
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

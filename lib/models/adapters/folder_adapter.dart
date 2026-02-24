import 'package:hive/hive.dart';
import 'package:recall_app/models/folder.dart';

class FolderAdapter extends TypeAdapter<Folder> {
  @override
  final int typeId = 4;

  @override
  Folder read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return Folder(
      id: map['id'] as String,
      name: map['name'] as String,
      colorHex: map['colorHex'] as String? ?? 'FF6366F1',
      iconCodePoint: map['iconCodePoint'] as int? ?? 0xe6c4,
      isSynced: map['isSynced'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now().toUtc(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, Folder obj) {
    writer.writeMap({
      'id': obj.id,
      'name': obj.name,
      'colorHex': obj.colorHex,
      'iconCodePoint': obj.iconCodePoint,
      'isSynced': obj.isSynced,
      'createdAt': obj.createdAt.toIso8601String(),
      'updatedAt': obj.updatedAt?.toIso8601String(),
    });
  }
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder.freezed.dart';
part 'folder.g.dart';

@freezed
class Folder with _$Folder {
  const factory Folder({
    required String id,
    required String name,
    @Default('FF6366F1') String colorHex,
    @Default(0xe6c4) int iconCodePoint,
    @Default(false) bool isSynced,
    DateTime? updatedAt,
    required DateTime createdAt,
  }) = _Folder;

  factory Folder.fromJson(Map<String, dynamic> json) => _$FolderFromJson(json);
}

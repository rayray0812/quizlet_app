import 'package:freezed_annotation/freezed_annotation.dart';

part 'badge.freezed.dart';
part 'badge.g.dart';

@freezed
class AppBadge with _$AppBadge {
  const factory AppBadge({
    required String id,
    required String titleKey,
    required String descKey,
    required int iconCodePoint,
    DateTime? unlockedAt,
    @Default(false) bool isUnlocked,
  }) = _AppBadge;

  factory AppBadge.fromJson(Map<String, dynamic> json) => _$AppBadgeFromJson(json);
}

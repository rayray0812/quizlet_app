import 'package:freezed_annotation/freezed_annotation.dart';

part 'review_log.freezed.dart';
part 'review_log.g.dart';

/// A single review event, append-only log for statistics.
@freezed
class ReviewLog with _$ReviewLog {
  const factory ReviewLog({
    required String id,
    required String cardId,
    required String setId,
    required int rating, // 1=Again, 2=Hard, 3=Good, 4=Easy
    required int state, // card state at time of review
    required DateTime reviewedAt,
    @Default(0) int elapsedDays,
    @Default(0) int scheduledDays,
    @Default(0.0) double lastStability,
    @Default(0.0) double lastDifficulty,
    @Default(false) bool isSynced,
  }) = _ReviewLog;

  factory ReviewLog.fromJson(Map<String, dynamic> json) =>
      _$ReviewLogFromJson(json);
}

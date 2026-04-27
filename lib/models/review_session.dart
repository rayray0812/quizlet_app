import 'package:freezed_annotation/freezed_annotation.dart';

part 'review_session.freezed.dart';
part 'review_session.g.dart';

/// A learning session grouping multiple review events.
///
/// Each modality (srs, quiz, match, speaking, conversation) creates one session.
/// ReviewLog.sessionId references this record's id for analytics linkage.
@freezed
class ReviewSession with _$ReviewSession {
  const factory ReviewSession({
    required String id,
    required String userId,
    required String modality, // srs | quiz | match | speaking | conversation
    required DateTime startedAt,
    DateTime? endedAt,
    @Default(0) int itemCount,
    @Default(0) int completedCount,
    double? scoreAvg,
    Map<String, dynamic>? metadata,
    @Default(false) bool isSynced,
  }) = _ReviewSession;

  factory ReviewSession.fromJson(Map<String, dynamic> json) =>
      _$ReviewSessionFromJson(json);
}

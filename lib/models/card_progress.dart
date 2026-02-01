import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_progress.freezed.dart';
part 'card_progress.g.dart';

/// SRS state for a single flashcard, stored independently from card content.
@freezed
class CardProgress with _$CardProgress {
  const factory CardProgress({
    required String cardId,
    required String setId,
    @Default(0.0) double stability,
    @Default(0.0) double difficulty,
    @Default(0) int reps,
    @Default(0) int lapses,
    @Default(0) int state, // 0=New, 1=Learning, 2=Review, 3=Relearning
    DateTime? lastReview,
    DateTime? due,
    @Default(0) int scheduledDays,
    @Default(0) int elapsedDays,
    @Default(false) bool isSynced,
  }) = _CardProgress;

  factory CardProgress.fromJson(Map<String, dynamic> json) =>
      _$CardProgressFromJson(json);
}

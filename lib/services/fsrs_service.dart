import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:uuid/uuid.dart';
import 'package:recall_app/models/card_progress.dart';
import 'package:recall_app/models/review_log.dart' as app;

/// Wraps the fsrs package, converting between app models and fsrs models.
class FsrsService {
  final fsrs.Scheduler _scheduler;

  FsrsService({fsrs.Scheduler? scheduler})
    : _scheduler =
          scheduler ??
          fsrs.Scheduler(enableFuzzing: true, desiredRetention: 0.9);

  /// Review a card with a given rating (1=Again, 2=Hard, 3=Good, 4=Easy).
  /// Returns updated CardProgress and a ReviewLog entry.
  ({CardProgress progress, app.ReviewLog log}) reviewCard(
    CardProgress progress,
    int rating,
  ) {
    if (rating < 1 || rating > 4) {
      throw ArgumentError.value(rating, 'rating', 'rating must be 1..4');
    }
    final now = DateTime.now().toUtc();
    final fsrsCard = _toFsrsCard(progress, now);
    final fsrsRating = fsrs.Rating.fromValue(rating);

    final result = _scheduler.reviewCard(
      fsrsCard,
      fsrsRating,
      reviewDateTime: now,
    );

    final updatedCard = result.card;

    // Map fsrs State back to our int representation
    // 0=New (won't happen after review), 1=Learning, 2=Review, 3=Relearning
    final newState = updatedCard.state.value;

    final elapsedDays = progress.lastReview != null
        ? now.difference(progress.lastReview!).inDays
        : 0;

    final scheduledDays = updatedCard.due.difference(now).inDays;

    final updatedProgress = progress.copyWith(
      stability: updatedCard.stability ?? 0.0,
      difficulty: updatedCard.difficulty ?? 0.0,
      reps: progress.reps + 1,
      lapses: rating == 1 ? progress.lapses + 1 : progress.lapses,
      state: newState,
      lastReview: now,
      due: updatedCard.due,
      scheduledDays: scheduledDays,
      elapsedDays: elapsedDays,
      isSynced: false,
    );

    final log = app.ReviewLog(
      id: const Uuid().v4(),
      cardId: progress.cardId,
      setId: progress.setId,
      rating: rating,
      state: progress.state, // state *before* review
      reviewedAt: now,
      elapsedDays: elapsedDays,
      scheduledDays: scheduledDays,
      lastStability: progress.stability,
      lastDifficulty: progress.difficulty,
    );

    return (progress: updatedProgress, log: log);
  }

  /// Get the predicted next interval for each of the four ratings.
  /// Returns a map of rating (1-4) ??human-readable interval string.
  Map<int, String> getSchedulingPreview(CardProgress progress) {
    final now = DateTime.now().toUtc();
    final previews = <int, String>{};

    for (final rating in fsrs.Rating.values) {
      final fsrsCard = _toFsrsCard(progress, now);
      final result = _scheduler.reviewCard(
        fsrsCard,
        rating,
        reviewDateTime: now,
      );
      final interval = result.card.due.difference(now);
      previews[rating.value] = _formatInterval(interval);
    }

    return previews;
  }

  /// Get the current retrievability (probability of recall) for a card.
  double getRetrievability(CardProgress progress) {
    if (progress.lastReview == null || progress.state == 0) return 0.0;
    final fsrsCard = _toFsrsCard(progress, DateTime.now().toUtc());
    return _scheduler.getCardRetrievability(fsrsCard);
  }

  /// Convert our CardProgress to an fsrs Card.
  fsrs.Card _toFsrsCard(CardProgress progress, DateTime now) {
    final fsrsCardId = toFsrsCardId(progress.cardId);

    // State 0 = New ??treat as learning with step 0
    if (progress.state == 0 || progress.lastReview == null) {
      return fsrs.Card(
        cardId: fsrsCardId,
        state: fsrs.State.learning,
        step: 0,
        stability: null,
        difficulty: null,
        due: now,
        lastReview: null,
      );
    }

    final estimatedStep = _estimateLearningStep(progress, now);
    return fsrs.Card(
      cardId: fsrsCardId,
      state: fsrs.State.fromValue(progress.state),
      step: progress.state == 2 ? null : estimatedStep, // review state has no step
      stability: progress.stability,
      difficulty: progress.difficulty,
      due: progress.due ?? now,
      lastReview: progress.lastReview,
    );
  }

  /// Estimate learning/relearning step using existing progress fields.
  /// This avoids resetting every non-review card to step 0 on app restarts.
  int _estimateLearningStep(CardProgress progress, DateTime now) {
    if (progress.state == 2) return 0;
    if (progress.reps <= 0) return 0;
    if (progress.due == null) return 0;
    if (progress.scheduledDays > 0) return 1;

    final minutesToDue = progress.due!.difference(now).inMinutes;
    if (minutesToDue <= 3) return 0;
    return 1;
  }

  /// Format a Duration into a human-readable string like "1m", "10m", "1d", "4d".
  String _formatInterval(Duration interval) {
    if (interval.inDays > 0) {
      return '${interval.inDays}d';
    } else if (interval.inHours > 0) {
      return '${interval.inHours}h';
    } else {
      final minutes = interval.inMinutes;
      return '${minutes < 1 ? 1 : minutes}m';
    }
  }

  /// Stable 31-bit hash used for fsrs.Card.cardId.
  /// Avoids Dart String.hashCode instability across runs/platforms.
  static int toFsrsCardId(String cardId) {
    const int offsetBasis = 0x811C9DC5;
    const int fnvPrime = 0x01000193;
    var hash = offsetBasis;
    for (final codeUnit in cardId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }
}

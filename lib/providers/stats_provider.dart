import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizlet_app/providers/study_set_provider.dart';

/// Today's review count.
final todayReviewCountProvider = Provider<int>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  final today = DateTime.now().toUtc();
  final logs = localStorage.getReviewLogsForDate(today);
  return logs.length;
});

/// Consecutive days with at least one review (streak).
final streakProvider = Provider<int>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  final allLogs = localStorage.getAllReviewLogs();
  if (allLogs.isEmpty) return 0;

  // Collect unique review dates
  final reviewDates = <DateTime>{};
  for (final log in allLogs) {
    final d = log.reviewedAt.toUtc();
    reviewDates.add(DateTime.utc(d.year, d.month, d.day));
  }

  final sorted = reviewDates.toList()..sort((a, b) => b.compareTo(a));
  final today = DateTime.utc(
    DateTime.now().toUtc().year,
    DateTime.now().toUtc().month,
    DateTime.now().toUtc().day,
  );

  // Streak must include today or yesterday
  if (sorted.first != today &&
      sorted.first != today.subtract(const Duration(days: 1))) {
    return 0;
  }

  int streak = 1;
  for (int i = 0; i < sorted.length - 1; i++) {
    if (sorted[i].difference(sorted[i + 1]).inDays == 1) {
      streak++;
    } else {
      break;
    }
  }

  return streak;
});

/// Total review count.
final totalReviewCountProvider = Provider<int>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  return localStorage.getAllReviewLogs().length;
});

/// Daily review counts for the last 30 days.
/// Returns a list of (date, count) pairs.
final dailyCountsProvider = Provider<List<({DateTime date, int count})>>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  final now = DateTime.now().toUtc();
  final result = <({DateTime date, int count})>[];

  for (int i = 29; i >= 0; i--) {
    final date = DateTime.utc(now.year, now.month, now.day)
        .subtract(Duration(days: i));
    final logs = localStorage.getReviewLogsForDate(date);
    result.add((date: date, count: logs.length));
  }

  return result;
});

/// Rating counts: again, hard, good, easy.
final ratingCountsProvider =
    Provider<({int again, int hard, int good, int easy})>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  final allLogs = localStorage.getAllReviewLogs();

  int again = 0, hard = 0, good = 0, easy = 0;
  for (final log in allLogs) {
    switch (log.rating) {
      case 1:
        again++;
        break;
      case 2:
        hard++;
        break;
      case 3:
        good++;
        break;
      case 4:
        easy++;
        break;
    }
  }

  return (again: again, hard: hard, good: good, easy: easy);
});

/// Heatmap data: date → count for the last 365 days.
final heatmapDataProvider = Provider<Map<DateTime, int>>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  final now = DateTime.now().toUtc();
  final from = DateTime.utc(now.year, now.month, now.day)
      .subtract(const Duration(days: 364));
  final to = DateTime.utc(now.year, now.month, now.day)
      .add(const Duration(days: 1));
  final logs = localStorage.getReviewLogsInRange(from, to);

  final map = <DateTime, int>{};
  for (final log in logs) {
    final d = log.reviewedAt.toUtc();
    final key = DateTime.utc(d.year, d.month, d.day);
    map[key] = (map[key] ?? 0) + 1;
  }

  return map;
});

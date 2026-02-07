import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/models/review_log.dart';
import 'package:recall_app/providers/study_set_provider.dart';

/// Single source of truth for all review logs ??avoids repeated Hive scans.
final allReviewLogsProvider = Provider<List<ReviewLog>>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  return localStorage.getAllReviewLogs();
});

bool _isSpeakingLog(ReviewLog log) {
  return log.reviewType == 'speaking' && log.speakingScore != null;
}

/// Today's review count.
final todayReviewCountProvider = Provider<int>((ref) {
  final allLogs = ref.watch(allReviewLogsProvider);
  final now = DateTime.now().toUtc();
  final todayStart = DateTime.utc(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));
  return allLogs.where((log) {
    return !log.reviewedAt.isBefore(todayStart) &&
        log.reviewedAt.isBefore(todayEnd);
  }).length;
});

/// Consecutive days with at least one review (streak).
final streakProvider = Provider<int>((ref) {
  final allLogs = ref.watch(allReviewLogsProvider);
  if (allLogs.isEmpty) return 0;

  // Collect unique review dates
  final reviewDates = <DateTime>{};
  for (final log in allLogs) {
    final d = log.reviewedAt.toUtc();
    reviewDates.add(DateTime.utc(d.year, d.month, d.day));
  }

  final sorted = reviewDates.toList()..sort((a, b) => b.compareTo(a));
  final now = DateTime.now().toUtc();
  final today = DateTime.utc(now.year, now.month, now.day);

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
  return ref.watch(allReviewLogsProvider).length;
});

/// Daily review counts for the last 30 days.
/// Returns a list of (date, count) pairs.
final dailyCountsProvider = Provider<List<({DateTime date, int count})>>((ref) {
  final allLogs = ref.watch(allReviewLogsProvider);
  final now = DateTime.now().toUtc();
  final todayDate = DateTime.utc(now.year, now.month, now.day);

  // Build a date?ount map from all logs
  final dateCountMap = <DateTime, int>{};
  for (final log in allLogs) {
    final d = log.reviewedAt.toUtc();
    final key = DateTime.utc(d.year, d.month, d.day);
    dateCountMap[key] = (dateCountMap[key] ?? 0) + 1;
  }

  final result = <({DateTime date, int count})>[];
  for (int i = 29; i >= 0; i--) {
    final date = todayDate.subtract(Duration(days: i));
    result.add((date: date, count: dateCountMap[date] ?? 0));
  }

  return result;
});

/// Rating counts: again, hard, good, easy.
final ratingCountsProvider =
    Provider<({int again, int hard, int good, int easy})>((ref) {
  final allLogs = ref.watch(allReviewLogsProvider);

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

/// Heatmap data: date ??count for the last 365 days.
final heatmapDataProvider = Provider<Map<DateTime, int>>((ref) {
  final allLogs = ref.watch(allReviewLogsProvider);
  final now = DateTime.now().toUtc();
  final from = DateTime.utc(now.year, now.month, now.day)
      .subtract(const Duration(days: 364));
  final to = DateTime.utc(now.year, now.month, now.day)
      .add(const Duration(days: 1));

  final map = <DateTime, int>{};
  for (final log in allLogs) {
    final d = log.reviewedAt.toUtc();
    if (d.isBefore(from) || !d.isBefore(to)) continue;
    final key = DateTime.utc(d.year, d.month, d.day);
    map[key] = (map[key] ?? 0) + 1;
  }

  return map;
});

/// Total speaking practice attempts.
final totalSpeakingCountProvider = Provider<int>((ref) {
  final allLogs = ref.watch(allReviewLogsProvider);
  return allLogs.where(_isSpeakingLog).length;
});

/// Today's average speaking score (1-5). Null when no speaking logs today.
final todaySpeakingAverageProvider = Provider<double?>((ref) {
  final allLogs = ref.watch(allReviewLogsProvider);
  final now = DateTime.now().toUtc();
  final todayStart = DateTime.utc(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));
  final scores = allLogs
      .where(_isSpeakingLog)
      .where((log) {
        return !log.reviewedAt.isBefore(todayStart) &&
            log.reviewedAt.isBefore(todayEnd);
      })
      .map((log) => log.speakingScore!)
      .toList();
  if (scores.isEmpty) return null;
  return scores.reduce((a, b) => a + b) / scores.length;
});

/// Last 30 days average speaking score (1-5). Null when no data.
final last30DaysSpeakingAverageProvider = Provider<double?>((ref) {
  final allLogs = ref.watch(allReviewLogsProvider);
  final now = DateTime.now().toUtc();
  final from = DateTime.utc(now.year, now.month, now.day)
      .subtract(const Duration(days: 29));
  final to = DateTime.utc(now.year, now.month, now.day)
      .add(const Duration(days: 1));
  final scores = allLogs
      .where(_isSpeakingLog)
      .where((log) => !log.reviewedAt.isBefore(from) && log.reviewedAt.isBefore(to))
      .map((log) => log.speakingScore!)
      .toList();
  if (scores.isEmpty) return null;
  return scores.reduce((a, b) => a + b) / scores.length;
});


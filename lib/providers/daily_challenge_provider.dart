import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/providers/conversation_stats_provider.dart';
import 'package:recall_app/providers/fsrs_provider.dart';
import 'package:recall_app/providers/stats_provider.dart';

const int dailyChallengeTarget = 10;

class DailyChallengeStatus {
  final int target;
  final int reviewedToday;
  final int remaining;
  final int dueNow;
  final int currentStreak;
  final bool isCompleted;

  const DailyChallengeStatus({
    required this.target,
    required this.reviewedToday,
    required this.remaining,
    required this.dueNow,
    required this.currentStreak,
    required this.isCompleted,
  });
}

final dailyChallengeStatusProvider = Provider<DailyChallengeStatus>((ref) {
  final dueNow = ref.watch(dueCountProvider);
  final allLogs = ref.watch(allReviewLogsProvider);
  // Every 2 conversation turns = 1 daily challenge progress.
  // Exclude conversation logs from srsCount so they aren't counted twice
  // (conversation logs are also stored in allReviewLogs via saveReviewLog).
  final convTurnsToday = ref.watch(todayConversationTurnsProvider);
  final convBonus = convTurnsToday ~/ 2;

  final now = DateTime.now().toUtc();
  final todayStart = DateTime.utc(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));
  final srsCount = allLogs.where((log) {
    if (log.reviewType == 'conversation') return false;
    return !log.reviewedAt.isBefore(todayStart) &&
        log.reviewedAt.isBefore(todayEnd);
  }).length;
  final effectiveToday = srsCount + convBonus;

  final remaining = (dailyChallengeTarget - effectiveToday).clamp(0, dailyChallengeTarget);
  final currentStreak = _calculateChallengeStreak(
    allLogs.map((log) => log.reviewedAt).toList(),
    target: dailyChallengeTarget,
  );

  return DailyChallengeStatus(
    target: dailyChallengeTarget,
    reviewedToday: effectiveToday,
    remaining: remaining,
    dueNow: dueNow,
    currentStreak: currentStreak,
    isCompleted: remaining == 0,
  );
});

int _calculateChallengeStreak(List<DateTime> reviewTimestamps, {required int target}) {
  if (reviewTimestamps.isEmpty) return 0;

  final byDay = <DateTime, int>{};
  for (final time in reviewTimestamps) {
    final utc = time.toUtc();
    final day = DateTime.utc(utc.year, utc.month, utc.day);
    byDay[day] = (byDay[day] ?? 0) + 1;
  }

  final now = DateTime.now().toUtc();
  DateTime cursor = DateTime.utc(now.year, now.month, now.day);
  int streak = 0;

  while (true) {
    final count = byDay[cursor] ?? 0;
    if (count < target) {
      if (streak == 0) {
        cursor = cursor.subtract(const Duration(days: 1));
        final yesterdayCount = byDay[cursor] ?? 0;
        if (yesterdayCount < target) return 0;
        streak = 1;
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      break;
    }
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return streak;
}


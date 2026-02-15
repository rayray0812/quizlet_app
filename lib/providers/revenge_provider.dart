import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/providers/stats_provider.dart';

/// Number of days to look back for wrong answers.
const int revengeLookbackDays = 7;

/// Unique card IDs that were rated Again (1) or Hard (2) in the last 7 days.
/// Sorted by most recent wrong answer first.
final revengeCardIdsProvider = Provider<List<String>>((ref) {
  final allLogs = ref.watch(allReviewLogsProvider);
  final now = DateTime.now().toUtc();
  final cutoff = DateTime.utc(now.year, now.month, now.day)
      .subtract(const Duration(days: revengeLookbackDays));

  // Collect card IDs with Again/Hard ratings in the lookback window,
  // keeping track of the most recent wrong answer time for sorting.
  final wrongCardTimes = <String, DateTime>{};

  for (final log in allLogs) {
    if (log.rating > 2) continue; // Only Again (1) and Hard (2)
    if (log.reviewedAt.isBefore(cutoff)) continue;

    final existing = wrongCardTimes[log.cardId];
    if (existing == null || log.reviewedAt.isAfter(existing)) {
      wrongCardTimes[log.cardId] = log.reviewedAt;
    }
  }

  // Sort by most recent wrong answer first
  final sorted = wrongCardTimes.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sorted.map((e) => e.key).toList();
});

/// Count of revenge-eligible cards.
final revengeCardCountProvider = Provider<int>((ref) {
  return ref.watch(revengeCardIdsProvider).length;
});

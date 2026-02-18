import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/providers/stats_provider.dart';

/// Default lookback days for wrong-answer revenge mode.
const int _defaultRevengeLookbackDays = 7;

/// Hive settings key for persisting the user's chosen lookback days.
const String _revengeLookbackKey = 'revenge_lookback_days';

/// User-configurable lookback days (3/7/14/30). Persisted in Hive settings.
final revengeLookbackDaysProvider =
    StateNotifierProvider<RevengeLookbackNotifier, int>((ref) {
  return RevengeLookbackNotifier();
});

class RevengeLookbackNotifier extends StateNotifier<int> {
  RevengeLookbackNotifier()
      : super(_defaultRevengeLookbackDays) {
    try {
      final box = Hive.box(AppConstants.hiveSettingsBox);
      state = box.get(_revengeLookbackKey,
          defaultValue: _defaultRevengeLookbackDays) as int;
    } catch (_) {
      // Box not open yet (e.g. during tests); keep default.
    }
  }

  void setDays(int days) {
    state = days;
    try {
      Hive.box(AppConstants.hiveSettingsBox).put(_revengeLookbackKey, days);
    } catch (_) {
      // Box not available; skip persistence.
    }
  }
}

/// Unique card IDs that were rated Again (1) or Hard (2) in the lookback window.
/// Sorted by most recent wrong answer first.
final revengeCardIdsProvider = Provider<List<String>>((ref) {
  final allLogs = ref.watch(allReviewLogsProvider);
  final lookbackDays = ref.watch(revengeLookbackDaysProvider);
  final now = DateTime.now().toUtc();
  final cutoff = DateTime.utc(now.year, now.month, now.day)
      .subtract(Duration(days: lookbackDays));

  final wrongCardTimes = <String, DateTime>{};

  for (final log in allLogs) {
    if (log.rating > 2) continue; // Only Again (1) and Hard (2)
    if (log.reviewedAt.isBefore(cutoff)) continue;

    final existing = wrongCardTimes[log.cardId];
    if (existing == null || log.reviewedAt.isAfter(existing)) {
      wrongCardTimes[log.cardId] = log.reviewedAt;
    }
  }

  final sorted = wrongCardTimes.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sorted.map((e) => e.key).toList();
});

/// Count of revenge-eligible cards.
final revengeCardCountProvider = Provider<int>((ref) {
  return ref.watch(revengeCardIdsProvider).length;
});

/// Revenge cards grouped by study set ID.
/// Returns a map from setId to list of cardIds.
final revengeCardsBySetProvider = Provider<Map<String, List<String>>>((ref) {
  final allLogs = ref.watch(allReviewLogsProvider);
  final lookbackDays = ref.watch(revengeLookbackDaysProvider);
  final now = DateTime.now().toUtc();
  final cutoff = DateTime.utc(now.year, now.month, now.day)
      .subtract(Duration(days: lookbackDays));

  // Track which cards are wrong + their setId
  final wrongCards = <String, String>{}; // cardId -> setId

  for (final log in allLogs) {
    if (log.rating > 2) continue;
    if (log.reviewedAt.isBefore(cutoff)) continue;
    wrongCards[log.cardId] = log.setId;
  }

  final result = <String, List<String>>{};
  for (final entry in wrongCards.entries) {
    result.putIfAbsent(entry.value, () => []).add(entry.key);
  }
  return result;
});

/// Statistics for the revenge mode dashboard.
class RevengeStats {
  final int totalWrong;
  final int clearedCount;
  final double clearRate;
  final List<({String cardId, String setId, int wrongCount})> topWrong;

  const RevengeStats({
    required this.totalWrong,
    required this.clearedCount,
    required this.clearRate,
    required this.topWrong,
  });
}

/// Computes revenge stats from review logs in the lookback window.
final revengeStatsProvider = Provider<RevengeStats>((ref) {
  final allLogs = ref.watch(allReviewLogsProvider);
  final lookbackDays = ref.watch(revengeLookbackDaysProvider);
  final now = DateTime.now().toUtc();
  final cutoff = DateTime.utc(now.year, now.month, now.day)
      .subtract(Duration(days: lookbackDays));

  // Count wrong answers per card in the lookback window
  final wrongCounts = <String, int>{}; // cardId -> wrong count
  final cardSetMap = <String, String>{}; // cardId -> setId
  final wrongCardIds = <String>{}; // all cards that were ever wrong

  for (final log in allLogs) {
    if (log.reviewedAt.isBefore(cutoff)) continue;
    if (log.rating <= 2) {
      wrongCounts[log.cardId] = (wrongCounts[log.cardId] ?? 0) + 1;
      cardSetMap[log.cardId] = log.setId;
      wrongCardIds.add(log.cardId);
    }
  }

  // Cleared = cards that were wrong but later rated Good/Easy in lookback window
  final clearedIds = <String>{};
  for (final log in allLogs) {
    if (log.reviewedAt.isBefore(cutoff)) continue;
    if (log.rating >= 3 && wrongCardIds.contains(log.cardId)) {
      clearedIds.add(log.cardId);
    }
  }

  final totalWrong = wrongCardIds.length;
  final clearedCount = clearedIds.length;
  final clearRate = totalWrong > 0 ? clearedCount / totalWrong : 0.0;

  // Top 10 most wrong cards
  final sortedWrong = wrongCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topWrong = sortedWrong.take(10).map((e) {
    return (
      cardId: e.key,
      setId: cardSetMap[e.key] ?? '',
      wrongCount: e.value,
    );
  }).toList();

  return RevengeStats(
    totalWrong: totalWrong,
    clearedCount: clearedCount,
    clearRate: clearRate,
    topWrong: topWrong,
  );
});

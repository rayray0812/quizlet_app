import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/models/review_log.dart';
import 'package:recall_app/providers/stats_provider.dart';

bool _isConversationLog(ReviewLog log) {
  return log.reviewType == 'conversation';
}

/// Total conversation turn count across all sessions.
final totalConversationTurnsProvider = Provider<int>((ref) {
  final allLogs = ref.watch(allReviewLogsProvider);
  return allLogs.where(_isConversationLog).length;
});

/// Today's conversation turn count.
final todayConversationTurnsProvider = Provider<int>((ref) {
  final allLogs = ref.watch(allReviewLogsProvider);
  final now = DateTime.now().toUtc();
  final todayStart = DateTime.utc(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));
  return allLogs.where((log) {
    return _isConversationLog(log) &&
        !log.reviewedAt.isBefore(todayStart) &&
        log.reviewedAt.isBefore(todayEnd);
  }).length;
});

/// Count of distinct conversation sessions (by unique timestamp date+setId grouping).
final totalConversationSessionsProvider = Provider<int>((ref) {
  final allLogs = ref.watch(allReviewLogsProvider);
  final sessions = <String>{};
  for (final log in allLogs.where(_isConversationLog)) {
    // Group by setId + date to approximate session count
    final d = log.reviewedAt.toUtc();
    final dateKey = '${d.year}-${d.month}-${d.day}';
    sessions.add('${log.setId}::$dateKey');
  }
  return sessions.length;
});

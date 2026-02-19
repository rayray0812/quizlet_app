import 'package:recall_app/services/local_storage_service.dart';

class BadgeChecker {
  final LocalStorageService _localStorage;

  BadgeChecker(this._localStorage);

  Map<String, bool> checkAll() {
    final allProgress = _localStorage.getAllCardProgress();
    final allReviewLogs = _localStorage.getAllReviewLogs();
    final allSets = _localStorage.getAllStudySets();
    final totalReviews = allReviewLogs.length;

    // Streak calculation
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    var streak = 0;
    var checkDate = today;
    while (true) {
      final hasReview = allReviewLogs.any((log) {
        final d = log.reviewedAt.toUtc();
        return d.year == checkDate.year &&
            d.month == checkDate.month &&
            d.day == checkDate.day;
      });
      if (!hasReview) break;
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Mastered cards (stability > 21 days)
    final masteredCount = allProgress.where((p) => p.stability > 21).length;

    // Daily challenge completions from settings
    // We approximate from review logs: days with 10+ reviews
    final dailyChallengeCompletions = <String>{};
    for (final log in allReviewLogs) {
      final d = log.reviewedAt.toUtc();
      dailyChallengeCompletions.add('${d.year}-${d.month}-${d.day}');
    }

    // Conversation session counting: distinct setId+date combos with reviewType='conversation'
    final convLogs =
        allReviewLogs.where((l) => l.reviewType == 'conversation').toList();
    final convSessionKeys = <String>{};
    final convDays = <String>{};
    for (final log in convLogs) {
      final d = log.reviewedAt.toUtc();
      final dateKey = '${d.year}-${d.month}-${d.day}';
      convSessionKeys.add('${log.setId}::$dateKey');
      convDays.add(dateKey);
    }

    // Conversation streak: consecutive days with conversation logs
    var convStreak = 0;
    var convCheckDate = today;
    while (true) {
      final key =
          '${convCheckDate.year}-${convCheckDate.month}-${convCheckDate.day}';
      if (!convDays.contains(key)) break;
      convStreak++;
      convCheckDate = convCheckDate.subtract(const Duration(days: 1));
    }

    return {
      'first_review': totalReviews >= 1,
      'streak_7': streak >= 7,
      'streak_30': streak >= 30,
      'reviews_100': totalReviews >= 100,
      'reviews_1000': totalReviews >= 1000,
      'cards_mastered_50': masteredCount >= 50,
      'revenge_clear': false, // Checked at runtime after revenge clear
      'sets_created_10': allSets.length >= 10,
      'perfect_quiz': false, // Checked at runtime after quiz
      'daily_challenge_30': dailyChallengeCompletions.length >= 30,
      'photo_import_10': false, // Checked at runtime
      'speedrun_match': false, // Checked at runtime
      'conversation_10': convSessionKeys.length >= 10,
      'conversation_streak_7': convStreak >= 7,
      'conversation_perfect': false, // Checked at runtime after session
    };
  }
}

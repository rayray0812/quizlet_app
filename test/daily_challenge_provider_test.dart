import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/models/review_log.dart';
import 'package:recall_app/providers/daily_challenge_provider.dart';
import 'package:recall_app/providers/fsrs_provider.dart';
import 'package:recall_app/providers/stats_provider.dart';

ReviewLog _logAt(
  DateTime reviewedAt,
  int index, {
  String reviewType = 'srs',
}) {
  return ReviewLog(
    id: 'log-$index-${reviewedAt.toIso8601String()}',
    cardId: 'card-$index',
    setId: 'set-1',
    rating: 3,
    state: 2,
    reviewedAt: reviewedAt,
    reviewType: reviewType,
  );
}

List<ReviewLog> _logsForDay(
  DateTime dayUtc,
  int count,
  int startIndex, {
  String reviewType = 'srs',
}) {
  return List<ReviewLog>.generate(
    count,
    (i) => _logAt(
      dayUtc.add(Duration(minutes: i)),
      startIndex + i,
      reviewType: reviewType,
    ),
  );
}

void main() {
  DateTime todayUtc() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day);
  }

  ProviderContainer buildContainer({
    required List<ReviewLog> logs,
    int todayCount = 0,
    int dueNow = 0,
  }) {
    return ProviderContainer(
      overrides: [
        allReviewLogsProvider.overrideWithValue(logs),
        todayReviewCountProvider.overrideWithValue(todayCount),
        dueCountProvider.overrideWithValue(dueNow),
      ],
    );
  }

  test('streak is zero when both today and yesterday are below target', () {
    final today = todayUtc();
    final yesterday = today.subtract(const Duration(days: 1));
    final logs = <ReviewLog>[
      ..._logsForDay(today, 2, 0),
      ..._logsForDay(yesterday, 9, 100),
    ];

    final container = buildContainer(logs: logs);
    addTearDown(container.dispose);

    final status = container.read(dailyChallengeStatusProvider);
    expect(status.currentStreak, 0);
  });

  test('streak starts from yesterday when today is below target', () {
    final today = todayUtc();
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    final logs = <ReviewLog>[
      ..._logsForDay(today, 3, 0),
      ..._logsForDay(yesterday, 10, 100),
      ..._logsForDay(twoDaysAgo, 10, 200),
    ];

    final container = buildContainer(logs: logs);
    addTearDown(container.dispose);

    final status = container.read(dailyChallengeStatusProvider);
    expect(status.currentStreak, 2);
  });

  test('streak counts consecutive qualifying days and stops at first miss', () {
    final today = todayUtc();
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    final threeDaysAgo = today.subtract(const Duration(days: 3));
    final logs = <ReviewLog>[
      ..._logsForDay(today, 10, 0),
      ..._logsForDay(yesterday, 12, 100),
      ..._logsForDay(twoDaysAgo, 5, 200),
      ..._logsForDay(threeDaysAgo, 11, 300),
    ];

    final container = buildContainer(logs: logs, todayCount: 10, dueNow: 4);
    addTearDown(container.dispose);

    final status = container.read(dailyChallengeStatusProvider);
    expect(status.currentStreak, 2);
    expect(status.isCompleted, isTrue);
    expect(status.remaining, 0);
  });

  test('streak is zero with no review logs', () {
    final container = buildContainer(logs: []);
    addTearDown(container.dispose);

    final status = container.read(dailyChallengeStatusProvider);
    expect(status.currentStreak, 0);
    expect(status.isCompleted, isFalse);
    expect(status.remaining, 10);
  });

  test('streak is 1 when only today meets target exactly', () {
    final today = todayUtc();
    final logs = _logsForDay(today, 10, 0);

    final container = buildContainer(logs: logs, todayCount: 10);
    addTearDown(container.dispose);

    final status = container.read(dailyChallengeStatusProvider);
    expect(status.currentStreak, 1);
    expect(status.isCompleted, isTrue);
  });

  test('long streak counts all consecutive qualifying days', () {
    final today = todayUtc();
    final logs = <ReviewLog>[];
    for (int d = 0; d < 7; d++) {
      logs.addAll(_logsForDay(
        today.subtract(Duration(days: d)),
        10 + d,
        d * 100,
      ));
    }

    final container = buildContainer(logs: logs, todayCount: 10, dueNow: 3);
    addTearDown(container.dispose);

    final status = container.read(dailyChallengeStatusProvider);
    expect(status.currentStreak, 7);
  });

  test('remaining clamps to zero when reviewed exceeds target', () {
    final today = todayUtc();
    final logs = _logsForDay(today, 15, 0);

    final container = buildContainer(logs: logs, dueNow: 5);
    addTearDown(container.dispose);

    final status = container.read(dailyChallengeStatusProvider);
    expect(status.remaining, 0);
    expect(status.isCompleted, isTrue);
    expect(status.reviewedToday, 15);
  });

  test('conversation turns count at half weight, not double-counted', () {
    final today = todayUtc();
    // 4 SRS reviews + 6 conversation turns
    // Expected: srsCount=4, convBonus=6~/2=3, effectiveToday=7
    final logs = <ReviewLog>[
      ..._logsForDay(today, 4, 0, reviewType: 'srs'),
      ..._logsForDay(today, 6, 100, reviewType: 'conversation'),
    ];

    final container = buildContainer(logs: logs);
    addTearDown(container.dispose);

    final status = container.read(dailyChallengeStatusProvider);
    expect(status.reviewedToday, 7);
    expect(status.remaining, 3);
    expect(status.isCompleted, isFalse);
  });

  test('pure conversation session contributes via half-weight rule only', () {
    final today = todayUtc();
    // 20 conversation turns -> 10 progress (20 ~/ 2)
    final logs = _logsForDay(today, 20, 0, reviewType: 'conversation');

    final container = buildContainer(logs: logs);
    addTearDown(container.dispose);

    final status = container.read(dailyChallengeStatusProvider);
    expect(status.reviewedToday, 10);
    expect(status.isCompleted, isTrue);
  });
}

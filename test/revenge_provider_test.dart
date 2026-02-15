import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/models/review_log.dart';
import 'package:recall_app/providers/revenge_provider.dart';
import 'package:recall_app/providers/stats_provider.dart';

ReviewLog _log({
  required String cardId,
  required int rating,
  required DateTime reviewedAt,
  String id = '',
}) {
  return ReviewLog(
    id: id.isEmpty ? 'log-$cardId-${reviewedAt.toIso8601String()}' : id,
    cardId: cardId,
    setId: 'set-1',
    rating: rating,
    state: 2,
    reviewedAt: reviewedAt,
  );
}

void main() {
  DateTime todayUtc() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day);
  }

  ProviderContainer buildContainer(List<ReviewLog> logs) {
    return ProviderContainer(
      overrides: [
        allReviewLogsProvider.overrideWithValue(logs),
      ],
    );
  }

  test('returns empty list when no review logs', () {
    final container = buildContainer([]);
    addTearDown(container.dispose);

    expect(container.read(revengeCardIdsProvider), isEmpty);
    expect(container.read(revengeCardCountProvider), 0);
  });

  test('returns empty when all ratings are Good or Easy', () {
    final today = todayUtc();
    final logs = [
      _log(cardId: 'c1', rating: 3, reviewedAt: today),
      _log(cardId: 'c2', rating: 4, reviewedAt: today),
    ];

    final container = buildContainer(logs);
    addTearDown(container.dispose);

    expect(container.read(revengeCardIdsProvider), isEmpty);
  });

  test('includes cards with Again (1) rating', () {
    final today = todayUtc();
    final logs = [
      _log(cardId: 'c1', rating: 1, reviewedAt: today),
      _log(cardId: 'c2', rating: 3, reviewedAt: today),
    ];

    final container = buildContainer(logs);
    addTearDown(container.dispose);

    expect(container.read(revengeCardIdsProvider), ['c1']);
    expect(container.read(revengeCardCountProvider), 1);
  });

  test('includes cards with Hard (2) rating', () {
    final today = todayUtc();
    final logs = [
      _log(cardId: 'c1', rating: 2, reviewedAt: today),
    ];

    final container = buildContainer(logs);
    addTearDown(container.dispose);

    expect(container.read(revengeCardIdsProvider), ['c1']);
  });

  test('deduplicates card IDs', () {
    final today = todayUtc();
    final logs = [
      _log(cardId: 'c1', rating: 1, reviewedAt: today, id: 'log-1'),
      _log(
        cardId: 'c1',
        rating: 1,
        reviewedAt: today.add(const Duration(hours: 1)),
        id: 'log-2',
      ),
    ];

    final container = buildContainer(logs);
    addTearDown(container.dispose);

    expect(container.read(revengeCardIdsProvider), ['c1']);
  });

  test('excludes cards older than 7 days', () {
    final today = todayUtc();
    final oldDate = today.subtract(const Duration(days: 8));
    final logs = [
      _log(cardId: 'c-old', rating: 1, reviewedAt: oldDate),
      _log(cardId: 'c-recent', rating: 1, reviewedAt: today),
    ];

    final container = buildContainer(logs);
    addTearDown(container.dispose);

    final ids = container.read(revengeCardIdsProvider);
    expect(ids, ['c-recent']);
    expect(ids, isNot(contains('c-old')));
  });

  test('sorts by most recent wrong answer first', () {
    final today = todayUtc();
    final logs = [
      _log(
        cardId: 'c1',
        rating: 1,
        reviewedAt: today.subtract(const Duration(days: 2)),
      ),
      _log(
        cardId: 'c2',
        rating: 2,
        reviewedAt: today.subtract(const Duration(days: 1)),
      ),
      _log(
        cardId: 'c3',
        rating: 1,
        reviewedAt: today,
      ),
    ];

    final container = buildContainer(logs);
    addTearDown(container.dispose);

    expect(container.read(revengeCardIdsProvider), ['c3', 'c2', 'c1']);
  });

  test('mixed ratings: only latest wrong time matters for sorting', () {
    final today = todayUtc();
    final logs = [
      // c1: wrong 3 days ago, then correct today
      _log(
        cardId: 'c1',
        rating: 1,
        reviewedAt: today.subtract(const Duration(days: 3)),
        id: 'log-1',
      ),
      _log(cardId: 'c1', rating: 3, reviewedAt: today, id: 'log-2'),
      // c2: wrong today
      _log(cardId: 'c2', rating: 1, reviewedAt: today, id: 'log-3'),
    ];

    final container = buildContainer(logs);
    addTearDown(container.dispose);

    final ids = container.read(revengeCardIdsProvider);
    // Both c1 and c2 should be included (c1 was wrong within 7 days)
    // c2 first (wrong today), c1 second (wrong 3 days ago)
    expect(ids, ['c2', 'c1']);
  });
}

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
  String setId = 'set-1',
}) {
  return ReviewLog(
    id: id.isEmpty ? 'log-$cardId-${reviewedAt.toIso8601String()}' : id,
    cardId: cardId,
    setId: setId,
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

  ProviderContainer buildContainer(List<ReviewLog> logs, {int? lookbackDays}) {
    final container = ProviderContainer(
      overrides: [
        allReviewLogsProvider.overrideWithValue(logs),
        if (lookbackDays != null)
          revengeLookbackDaysProvider.overrideWith(
            (ref) {
              final notifier = RevengeLookbackNotifier();
              // Override state directly
              Future.microtask(() => notifier.setDays(lookbackDays));
              return notifier;
            },
          ),
      ],
    );
    // If lookback was set via microtask, flush it
    if (lookbackDays != null) {
      container.read(revengeLookbackDaysProvider.notifier).setDays(lookbackDays);
    }
    return container;
  }

  group('revengeCardIdsProvider', () {
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

    test('excludes cards older than default 7 days', () {
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
        _log(
          cardId: 'c1',
          rating: 1,
          reviewedAt: today.subtract(const Duration(days: 3)),
          id: 'log-1',
        ),
        _log(cardId: 'c1', rating: 3, reviewedAt: today, id: 'log-2'),
        _log(cardId: 'c2', rating: 1, reviewedAt: today, id: 'log-3'),
      ];

      final container = buildContainer(logs);
      addTearDown(container.dispose);

      final ids = container.read(revengeCardIdsProvider);
      expect(ids, ['c2', 'c1']);
    });
  });

  group('lookback days', () {
    test('3-day lookback excludes cards older than 3 days', () {
      final today = todayUtc();
      final logs = [
        _log(cardId: 'c-old', rating: 1,
            reviewedAt: today.subtract(const Duration(days: 4))),
        _log(cardId: 'c-recent', rating: 1,
            reviewedAt: today.subtract(const Duration(days: 2))),
      ];

      final container = buildContainer(logs, lookbackDays: 3);
      addTearDown(container.dispose);

      final ids = container.read(revengeCardIdsProvider);
      expect(ids, ['c-recent']);
    });

    test('30-day lookback includes older cards', () {
      final today = todayUtc();
      final logs = [
        _log(cardId: 'c-old', rating: 1,
            reviewedAt: today.subtract(const Duration(days: 20))),
        _log(cardId: 'c-recent', rating: 1, reviewedAt: today),
      ];

      final container = buildContainer(logs, lookbackDays: 30);
      addTearDown(container.dispose);

      final ids = container.read(revengeCardIdsProvider);
      expect(ids.length, 2);
      expect(ids, contains('c-old'));
      expect(ids, contains('c-recent'));
    });
  });

  group('revengeCardsBySetProvider', () {
    test('groups cards by setId', () {
      final today = todayUtc();
      final logs = [
        _log(cardId: 'c1', rating: 1, reviewedAt: today, setId: 'set-A'),
        _log(cardId: 'c2', rating: 2, reviewedAt: today, setId: 'set-A'),
        _log(cardId: 'c3', rating: 1, reviewedAt: today, setId: 'set-B'),
      ];

      final container = buildContainer(logs);
      addTearDown(container.dispose);

      final bySet = container.read(revengeCardsBySetProvider);
      expect(bySet.keys, containsAll(['set-A', 'set-B']));
      expect(bySet['set-A'], containsAll(['c1', 'c2']));
      expect(bySet['set-B'], ['c3']);
    });

    test('empty when no wrong answers', () {
      final container = buildContainer([]);
      addTearDown(container.dispose);

      expect(container.read(revengeCardsBySetProvider), isEmpty);
    });
  });

  group('revengeStatsProvider', () {
    test('computes correct stats', () {
      final today = todayUtc();
      final logs = [
        _log(cardId: 'c1', rating: 1, reviewedAt: today, id: 'l1', setId: 's1'),
        _log(cardId: 'c1', rating: 1,
            reviewedAt: today.add(const Duration(hours: 1)), id: 'l2', setId: 's1'),
        _log(cardId: 'c1', rating: 3,
            reviewedAt: today.add(const Duration(hours: 2)), id: 'l3', setId: 's1'),
        _log(cardId: 'c2', rating: 2, reviewedAt: today, id: 'l4', setId: 's1'),
        _log(cardId: 'c3', rating: 1, reviewedAt: today, id: 'l5', setId: 's2'),
        _log(cardId: 'c3', rating: 4,
            reviewedAt: today.add(const Duration(hours: 1)), id: 'l6', setId: 's2'),
      ];

      final container = buildContainer(logs);
      addTearDown(container.dispose);

      final stats = container.read(revengeStatsProvider);
      expect(stats.totalWrong, 3);
      expect(stats.clearedCount, 2);
      expect(stats.clearRate, closeTo(2 / 3, 0.01));
      expect(stats.topWrong.length, 3);
      expect(stats.topWrong.first.cardId, 'c1');
      expect(stats.topWrong.first.wrongCount, 2);
    });

    test('empty stats when no logs', () {
      final container = buildContainer([]);
      addTearDown(container.dispose);

      final stats = container.read(revengeStatsProvider);
      expect(stats.totalWrong, 0);
      expect(stats.clearedCount, 0);
      expect(stats.clearRate, 0.0);
      expect(stats.topWrong, isEmpty);
    });

    test('top wrong limited to 10 entries', () {
      final today = todayUtc();
      final logs = <ReviewLog>[];
      for (int i = 0; i < 15; i++) {
        logs.add(_log(
          cardId: 'c$i',
          rating: 1,
          reviewedAt: today,
          id: 'l$i',
          setId: 's1',
        ));
      }

      final container = buildContainer(logs);
      addTearDown(container.dispose);

      final stats = container.read(revengeStatsProvider);
      expect(stats.topWrong.length, 10);
    });
  });
}

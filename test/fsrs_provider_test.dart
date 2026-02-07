import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/models/card_progress.dart';
import 'package:recall_app/providers/fsrs_provider.dart';

void main() {
  test('dueCardsProvider filters by due date using injected clock', () {
    final now = DateTime.utc(2026, 2, 7, 12);
    final cards = <CardProgress>[
      CardProgress(
        cardId: 'due',
        setId: 's1',
        due: now.subtract(const Duration(minutes: 1)),
      ),
      CardProgress(
        cardId: 'at-now',
        setId: 's1',
        due: now,
      ),
      CardProgress(
        cardId: 'future',
        setId: 's1',
        due: now.add(const Duration(minutes: 1)),
      ),
      const CardProgress(
        cardId: 'new',
        setId: 's1',
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        allCardProgressProvider.overrideWith((ref) => cards),
        dueClockProvider.overrideWith((ref) => () => now),
        dueTickerProvider.overrideWith((ref) => Stream.value(0)),
      ],
    );
    addTearDown(container.dispose);

    final due = container.read(dueCardsProvider).map((e) => e.cardId).toSet();

    expect(due, contains('due'));
    expect(due, contains('at-now'));
    expect(due, contains('new'));
    expect(due, isNot(contains('future')));
  });
}

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/models/card_progress.dart';
import 'package:recall_app/features/study/screens/quiz_screen.dart';

void main() {
  final cards = List.generate(
    8,
    (i) => Flashcard(id: 'c$i', term: 'term$i', definition: 'def$i'),
  );

  group('selectQuizCards — weighted sampling', () {
    test('returns all cards when count >= allCards.length', () {
      final result = selectQuizCards(
        allCards: cards,
        count: 100,
        random: Random(42),
      );
      expect(result.length, cards.length);
    });

    test('returns requested count when count < allCards.length', () {
      final result = selectQuizCards(
        allCards: cards,
        count: 3,
        random: Random(42),
      );
      expect(result.length, 3);
    });

    test('single card always returns that card', () {
      final single = [cards.first];
      final result = selectQuizCards(
        allCards: single,
        count: 1,
        random: Random(42),
      );
      expect(result, [single.first]);
    });

    test('no duplicate cards in result', () {
      for (var seed = 0; seed < 50; seed++) {
        final result = selectQuizCards(
          allCards: cards,
          count: 5,
          random: Random(seed),
        );
        expect(result.toSet().length, result.length,
            reason: 'Seed $seed produced duplicates');
      }
    });

    test('pickedIdx fallback lands on last item (off-by-last fix)', () {
      // With a fixed seed, the weighted random loop should complete
      // without index-out-of-range or always picking index 0.
      // We run many seeds to stress-test the fallback path.
      for (var seed = 0; seed < 200; seed++) {
        final result = selectQuizCards(
          allCards: cards,
          count: cards.length,
          random: Random(seed),
          prioritizeWeak: true,
          progressMap: {
            for (final c in cards)
              c.id: CardProgress(cardId: c.id, setId: 'set1'),
          },
        );
        expect(result.length, cards.length,
            reason: 'Seed $seed failed');
        expect(result.toSet().length, result.length,
            reason: 'Seed $seed produced duplicates');
      }
    });

    test('weighted mode prioritizes overdue cards', () {
      final now = DateTime.now().toUtc();
      final progressMap = <String, CardProgress>{};
      // Make the first card overdue and high difficulty
      progressMap[cards[0].id] = CardProgress(
        cardId: cards[0].id,
        setId: 'set1',
        due: now.subtract(const Duration(days: 7)),
        difficulty: 9.0,
        lapses: 5,
        state: 3,
      );
      // All others are new (no progress)
      for (var i = 1; i < cards.length; i++) {
        progressMap[cards[i].id] = CardProgress(
          cardId: cards[i].id,
          setId: 'set1',
          state: 2,
          difficulty: 1.0,
          due: now.add(const Duration(days: 30)),
        );
      }

      // Run many iterations and count how often the overdue card appears first
      var overdueFirstCount = 0;
      const iterations = 200;
      for (var seed = 0; seed < iterations; seed++) {
        final result = selectQuizCards(
          allCards: cards,
          count: 1,
          random: Random(seed),
          prioritizeWeak: true,
          progressMap: progressMap,
        );
        if (result.first.id == cards[0].id) overdueFirstCount++;
      }

      // The overdue card should be picked far more often than random (1/8 = 12.5%)
      expect(overdueFirstCount, greaterThan(iterations * 0.3),
          reason: 'Overdue card should be prioritized');
    });

    test('non-weighted mode ignores progress map', () {
      final result = selectQuizCards(
        allCards: cards,
        count: 3,
        random: Random(42),
        prioritizeWeak: false,
        progressMap: {
          for (final c in cards)
            c.id: CardProgress(cardId: c.id, setId: 'set1'),
        },
      );
      expect(result.length, 3);
    });
  });
}

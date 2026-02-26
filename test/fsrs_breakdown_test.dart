import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/models/card_progress.dart';
import 'package:recall_app/providers/fsrs_provider.dart';

void main() {
  group('_breakdownFromCards helper (via dueBreakdownProvider logic)', () {
    CardProgress makeProgress(String id, {required int state}) {
      return CardProgress(cardId: id, setId: 'set1', state: state);
    }

    test('empty list returns all zeros', () {
      final result = breakdownFromCards([]);
      expect(result.newCount, 0);
      expect(result.learning, 0);
      expect(result.review, 0);
    });

    test('counts new cards (state 0)', () {
      final cards = [
        makeProgress('a', state: 0),
        makeProgress('b', state: 0),
      ];
      final result = breakdownFromCards(cards);
      expect(result.newCount, 2);
      expect(result.learning, 0);
      expect(result.review, 0);
    });

    test('counts learning cards (state 1)', () {
      final cards = [
        makeProgress('a', state: 1),
      ];
      final result = breakdownFromCards(cards);
      expect(result.newCount, 0);
      expect(result.learning, 1);
      expect(result.review, 0);
    });

    test('counts review cards (state 2) and relearning (state 3) together', () {
      final cards = [
        makeProgress('a', state: 2),
        makeProgress('b', state: 3),
      ];
      final result = breakdownFromCards(cards);
      expect(result.newCount, 0);
      expect(result.learning, 0);
      expect(result.review, 2);
    });

    test('mixed states counted correctly', () {
      final cards = [
        makeProgress('a', state: 0),
        makeProgress('b', state: 1),
        makeProgress('c', state: 2),
        makeProgress('d', state: 3),
        makeProgress('e', state: 0),
      ];
      final result = breakdownFromCards(cards);
      expect(result.newCount, 2);
      expect(result.learning, 1);
      expect(result.review, 2);
    });
  });
}

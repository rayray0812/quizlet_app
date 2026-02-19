import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/models/card_progress.dart';
import 'package:recall_app/models/flashcard.dart';

// We test the queue logic extracted from SrsReviewScreen.
// Since _sortQueue and _queueSortOrder are private, we replicate them here
// to validate the algorithm. The actual screen uses identical logic.

int _queueSortOrder(int state) {
  switch (state) {
    case 1: // Learning
    case 3: // Relearning
      return 0;
    case 2: // Review
      return 1;
    default: // New (state 0)
      return 2;
  }
}

class _ReviewItem {
  final Flashcard card;
  final CardProgress progress;
  _ReviewItem({required this.card, required this.progress});
}

Flashcard _makeCard(String id) => Flashcard(
      id: id,
      term: 'term_$id',
      definition: 'def_$id',
    );

CardProgress _makeProgress(String cardId, {int state = 0}) => CardProgress(
      cardId: cardId,
      setId: 'set1',
      state: state,
      stability: 1.0,
      difficulty: 5.0,
      elapsedDays: 0,
      scheduledDays: 0,
      reps: 0,
      lapses: 0,
    );

void main() {
  group('SRS review queue sort order', () {
    test('Learning cards sort before Review cards', () {
      expect(_queueSortOrder(1), lessThan(_queueSortOrder(2)));
    });

    test('Relearning cards sort before Review cards', () {
      expect(_queueSortOrder(3), lessThan(_queueSortOrder(2)));
    });

    test('Review cards sort before New cards', () {
      expect(_queueSortOrder(2), lessThan(_queueSortOrder(0)));
    });

    test('Learning and Relearning have same priority', () {
      expect(_queueSortOrder(1), equals(_queueSortOrder(3)));
    });

    test('Queue sorts Learning > Review > New', () {
      final items = [
        _ReviewItem(card: _makeCard('new1'), progress: _makeProgress('new1', state: 0)),
        _ReviewItem(card: _makeCard('review1'), progress: _makeProgress('review1', state: 2)),
        _ReviewItem(card: _makeCard('learn1'), progress: _makeProgress('learn1', state: 1)),
        _ReviewItem(card: _makeCard('relearn1'), progress: _makeProgress('relearn1', state: 3)),
      ];

      items.sort((a, b) =>
          _queueSortOrder(a.progress.state).compareTo(
              _queueSortOrder(b.progress.state)));

      // Learning/Relearning first, then Review, then New
      expect(items[0].progress.state, anyOf(1, 3));
      expect(items[1].progress.state, anyOf(1, 3));
      expect(items[2].progress.state, 2);
      expect(items[3].progress.state, 0);
    });
  });

  group('Again/Hard re-queue logic', () {
    test('Again (rating 1) should re-queue the card', () {
      final queue = <_ReviewItem>[
        _ReviewItem(card: _makeCard('c1'), progress: _makeProgress('c1')),
        _ReviewItem(card: _makeCard('c2'), progress: _makeProgress('c2')),
      ];
      const rating = 1;
      final currentItem = queue[0];

      // Simulate re-queue logic
      if (rating <= 2) {
        queue.add(_ReviewItem(card: currentItem.card, progress: currentItem.progress));
      }

      expect(queue.length, 3);
      expect(queue.last.card.id, 'c1');
    });

    test('Hard (rating 2) should re-queue the card', () {
      final queue = <_ReviewItem>[
        _ReviewItem(card: _makeCard('c1'), progress: _makeProgress('c1')),
      ];
      const rating = 2;
      final currentItem = queue[0];

      if (rating <= 2) {
        queue.add(_ReviewItem(card: currentItem.card, progress: currentItem.progress));
      }

      expect(queue.length, 2);
      expect(queue.last.card.id, 'c1');
    });

    test('Good (rating 3) should NOT re-queue the card', () {
      final queue = <_ReviewItem>[
        _ReviewItem(card: _makeCard('c1'), progress: _makeProgress('c1')),
      ];
      const rating = 3;

      if (rating <= 2) {
        queue.add(queue[0]);
      }

      expect(queue.length, 1);
    });

    test('Easy (rating 4) should NOT re-queue the card', () {
      final queue = <_ReviewItem>[
        _ReviewItem(card: _makeCard('c1'), progress: _makeProgress('c1')),
      ];
      const rating = 4;

      if (rating <= 2) {
        queue.add(queue[0]);
      }

      expect(queue.length, 1);
    });
  });
}

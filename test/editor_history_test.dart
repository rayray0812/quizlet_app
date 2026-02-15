import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/features/home/utils/editor_history.dart';

CardSnapshot _snap(String id, String term) => CardSnapshot(
      id: id,
      term: term,
      definition: 'def',
      example: '',
      imageUrl: '',
      tags: [],
    );

void main() {
  group('EditorHistory', () {
    late EditorHistory history;

    setUp(() {
      history = EditorHistory();
    });

    test('initially cannot undo or redo', () {
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
    });

    test('pushState then undo returns previous state', () {
      final state1 = [_snap('1', 'hello')];
      final state2 = [_snap('1', 'world')];

      history.pushState(state1);
      final restored = history.undo(state2);

      expect(restored, isNotNull);
      expect(restored!.first.term, 'hello');
    });

    test('undo then redo returns forward state', () {
      final state1 = [_snap('1', 'a')];
      final state2 = [_snap('1', 'b')];

      history.pushState(state1);
      history.undo(state2);

      final restored = history.redo(state1);
      expect(restored, isNotNull);
      expect(restored!.first.term, 'b');
    });

    test('new push clears redo stack', () {
      final s1 = [_snap('1', 'a')];
      final s2 = [_snap('1', 'b')];
      final s3 = [_snap('1', 'c')];

      history.pushState(s1);
      history.undo(s2); // redo has s2
      expect(history.canRedo, isTrue);

      history.pushState(s3); // clears redo
      expect(history.canRedo, isFalse);
    });

    test('max 50 snapshots', () {
      for (var i = 0; i < 60; i++) {
        history.pushState([_snap('1', 'v$i')]);
      }
      expect(history.undoCount, EditorHistory.maxSnapshots);
    });

    test('undo on empty stack returns null', () {
      final result = history.undo([_snap('1', 'x')]);
      expect(result, isNull);
    });

    test('redo on empty stack returns null', () {
      final result = history.redo([_snap('1', 'x')]);
      expect(result, isNull);
    });

    test('clear empties both stacks', () {
      history.pushState([_snap('1', 'a')]);
      history.pushState([_snap('1', 'b')]);
      history.undo([_snap('1', 'c')]);

      history.clear();
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
    });

    test('deep copy ensures mutations do not affect history', () {
      final original = [_snap('1', 'hello')];
      history.pushState(original);

      // Mutate original list
      original.add(_snap('2', 'extra'));

      final restored = history.undo([_snap('1', 'world')]);
      expect(restored!.length, 1);
      expect(restored.first.term, 'hello');
    });
  });

  group('CardSnapshot', () {
    test('equality', () {
      final a = CardSnapshot(
        id: '1', term: 'a', definition: 'b',
        example: 'c', imageUrl: '', tags: ['t1'],
      );
      final b = CardSnapshot(
        id: '1', term: 'a', definition: 'b',
        example: 'c', imageUrl: '', tags: ['t1'],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality on different term', () {
      final a = _snap('1', 'hello');
      final b = _snap('1', 'world');
      expect(a, isNot(equals(b)));
    });
  });
}

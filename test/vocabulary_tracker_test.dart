import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/features/study/utils/vocabulary_tracker.dart';

void main() {
  group('VocabularyTracker', () {
    late VocabularyTracker tracker;

    setUp(() {
      tracker = VocabularyTracker.withTerms(
        targetTerms: ['apple', 'banana', 'cherry', 'date', 'elderberry'],
        termDefinitions: {
          'apple': 'a red fruit',
          'banana': 'a yellow fruit',
          'cherry': 'a small red fruit',
          'date': 'a sweet fruit',
          'elderberry': 'a dark berry',
        },
      );
    });

    test('extractUsedTerms finds exact word matches for Latin terms', () {
      final result = tracker.extractUsedTerms('I want an apple and banana');
      expect(result, containsAll(['apple', 'banana']));
      expect(result, isNot(contains('cherry')));
    });

    test('extractUsedTerms returns empty for no matches', () {
      final result = tracker.extractUsedTerms('I want some grapes');
      expect(result, isEmpty);
    });

    test('extractUsedTerms handles case insensitivity', () {
      final result = tracker.extractUsedTerms('I love APPLE and Cherry');
      expect(result, containsAll(['apple', 'cherry']));
    });

    test('extractUsedTerms handles empty input', () {
      expect(tracker.extractUsedTerms(''), isEmpty);
    });

    test('extractUsedTerms handles empty target terms', () {
      final emptyTracker = VocabularyTracker.withTerms(
        targetTerms: [],
        termDefinitions: {},
      );
      expect(emptyTracker.extractUsedTerms('hello world'), isEmpty);
    });

    test('nextPriorityTerms returns correct count from cursor', () {
      tracker.focusCursor = 0;
      final terms = tracker.nextPriorityTerms(count: 2);
      expect(terms.length, 2);
      expect(terms[0], 'apple');
      expect(terms[1], 'banana');
    });

    test('nextPriorityTerms wraps around', () {
      tracker.focusCursor = 4;
      final terms = tracker.nextPriorityTerms(count: 2);
      expect(terms.length, 2);
      expect(terms[0], 'elderberry');
      expect(terms[1], 'apple');
    });

    test('nextPriorityTerms with startOffset', () {
      final terms = tracker.nextPriorityTerms(count: 2, startOffset: 2);
      expect(terms[0], 'cherry');
      expect(terms[1], 'date');
    });

    test('advanceFocusCursor advances correctly', () {
      tracker.focusCursor = 0;
      tracker.advanceFocusCursor(3);
      expect(tracker.focusCursor, 3);
    });

    test('advanceFocusCursor wraps around', () {
      tracker.focusCursor = 3;
      tracker.advanceFocusCursor(4);
      expect(tracker.focusCursor, 2); // (3+4) % 5 = 2
    });

    test('advanceFocusCursor does nothing for empty terms', () {
      final emptyTracker = VocabularyTracker.withTerms(
        targetTerms: [],
        termDefinitions: {},
      );
      emptyTracker.advanceFocusCursor(5);
      expect(emptyTracker.focusCursor, 0);
    });

    test('targetTermsPerTurn returns correct values', () {
      expect(VocabularyTracker.targetTermsPerTurn('easy'), 1);
      expect(VocabularyTracker.targetTermsPerTurn('medium'), 2);
      expect(VocabularyTracker.targetTermsPerTurn('hard'), 3);
      expect(VocabularyTracker.targetTermsPerTurn('EASY'), 1);
      expect(VocabularyTracker.targetTermsPerTurn('  Hard  '), 3);
    });

    test('normalizeForMatch strips punctuation and lowercases', () {
      expect(VocabularyTracker.normalizeForMatch('Hello, World!'),
          'hello world');
      expect(VocabularyTracker.normalizeForMatch('  A  B  C  '), 'a b c');
      expect(VocabularyTracker.normalizeForMatch(''), '');
    });

    test('practicedTerms tracking works', () {
      expect(tracker.practicedTerms, isEmpty);
      final used = tracker.extractUsedTerms('I ate an apple');
      tracker.practicedTerms.addAll(used);
      expect(tracker.practicedTerms, contains('apple'));
      expect(tracker.practicedTerms.length, 1);
    });

    test('CJK term matching works without word boundaries', () {
      final cjkTracker = VocabularyTracker.withTerms(
        targetTerms: ['\u86CB\u7CD5', '\u5496\u5561'],
        termDefinitions: {
          '\u86CB\u7CD5': 'cake',
          '\u5496\u5561': 'coffee',
        },
      );
      final result =
          cjkTracker.extractUsedTerms('\u6211\u60F3\u8981\u86CB\u7CD5\u548C\u5496\u5561');
      expect(result, containsAll(['\u86CB\u7CD5', '\u5496\u5561']));
    });

    test('constructor deduplicates terms', () {
      final tracker = VocabularyTracker(
        allTerms: ['apple', 'Apple', 'APPLE', 'banana'],
        allTermDefinitions: {'apple': 'fruit', 'Apple': 'fruit', 'banana': 'fruit'},
        maxTargetCount: 10,
      );
      // After normalization, apple/Apple/APPLE are the same
      // Only unique normalized forms should remain
      expect(tracker.targetTerms.length, lessThanOrEqualTo(2));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/features/study/utils/fuzzy_match.dart';

void main() {
  group('isFuzzyMatch', () {
    test('exact match returns true', () {
      expect(isFuzzyMatch('hello', 'hello'), isTrue);
    });

    test('case-insensitive exact match', () {
      expect(isFuzzyMatch('Hello', 'hello'), isTrue);
      expect(isFuzzyMatch('WORLD', 'world'), isTrue);
    });

    test('trims whitespace', () {
      expect(isFuzzyMatch('  hello  ', 'hello'), isTrue);
    });

    test('near match within 20% distance', () {
      // "photo" (5 chars) → threshold = ceil(5*0.2) = 1
      expect(isFuzzyMatch('phato', 'photo'), isTrue); // distance 1
      expect(isFuzzyMatch('phxto', 'photo'), isTrue); // distance 1
    });

    test('mismatch beyond threshold', () {
      expect(isFuzzyMatch('pxxxx', 'photo'), isFalse); // distance 4
      expect(isFuzzyMatch('abcde', 'photo'), isFalse);
    });

    test('short strings (<=3) require exact match', () {
      expect(isFuzzyMatch('cat', 'cat'), isTrue);
      expect(isFuzzyMatch('ca', 'cat'), isFalse);
      expect(isFuzzyMatch('cot', 'cat'), isFalse);
      expect(isFuzzyMatch('ab', 'ab'), isTrue);
    });

    test('empty strings', () {
      expect(isFuzzyMatch('', 'hello'), isFalse);
      expect(isFuzzyMatch('hello', ''), isFalse);
      expect(isFuzzyMatch('', ''), isTrue);
    });

    test('longer strings allow more distance', () {
      // "photosynthesis" (14 chars) → threshold = ceil(14*0.2) = 3
      expect(isFuzzyMatch('photosintesis', 'photosynthesis'), isTrue); // dist 2
      expect(isFuzzyMatch('fotosintesis', 'photosynthesis'), isTrue); // dist 3
      expect(isFuzzyMatch('xotosintesiz', 'photosynthesis'), isFalse); // dist 4
    });

    test('CJK characters', () {
      expect(isFuzzyMatch('\u4F60\u597D', '\u4F60\u597D'), isTrue);
      // 2 chars: exact required
      expect(isFuzzyMatch('\u4F60\u58DE', '\u4F60\u597D'), isFalse);
    });
  });
}

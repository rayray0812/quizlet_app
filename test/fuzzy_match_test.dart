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

    test('CJK exact match', () {
      expect(isFuzzyMatch('\u4F60\u597D', '\u4F60\u597D'), isTrue);
    });

    test('CJK 2-char allows 1 edit distance', () {
      // 你好 vs 你壞 — 1 character different out of 2
      expect(isFuzzyMatch('\u4F60\u58DE', '\u4F60\u597D'), isTrue);
    });

    test('CJK 2-char rejects 2 edits', () {
      // 我壞 vs 你好 — 2 characters different
      expect(isFuzzyMatch('\u6211\u58DE', '\u4F60\u597D'), isFalse);
    });

    test('CJK single char requires exact match', () {
      expect(isFuzzyMatch('\u4F60', '\u4F60'), isTrue);
      expect(isFuzzyMatch('\u6211', '\u4F60'), isFalse);
    });

    test('CJK 4-char allows 1 edit', () {
      // 光合作用 vs 光合做用 — 1 char different, threshold ceil(4*0.33)=2
      expect(
        isFuzzyMatch(
          '\u5149\u5408\u505A\u7528',
          '\u5149\u5408\u4F5C\u7528',
        ),
        isTrue,
      );
    });

    test('CJK 3-char allows 1 edit', () {
      // 三角形 vs 三角型 — 1 char different, threshold ceil(3*0.33)=1
      expect(
        isFuzzyMatch('\u4E09\u89D2\u578B', '\u4E09\u89D2\u5F62'),
        isTrue,
      );
    });

    test('CJK does not apply ph→f normalization', () {
      // Ensure Chinese text is not mangled by Latin normalization
      expect(isFuzzyMatch('\u7269\u7406', '\u7269\u7406'), isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/services/gemini_service.dart';

void main() {
  group('GeminiService.parseResponse', () {
    test('parses plain JSON array', () {
      final input = '[{"term":"hello","definition":"你好"},{"term":"world","definition":"世界"}]';
      final result = GeminiService.parseResponse(input);
      expect(result.length, 2);
      expect(result[0]['term'], 'hello');
      expect(result[1]['definition'], '世界');
    });

    test('parses {cards: [...]} wrapper', () {
      final input = '{"cards":[{"term":"a","definition":"b"}]}';
      final result = GeminiService.parseResponse(input);
      expect(result.length, 1);
      expect(result[0]['term'], 'a');
    });

    test('parses {flashcards: [...]} wrapper', () {
      final input = '{"flashcards":[{"term":"x","definition":"y"}]}';
      final result = GeminiService.parseResponse(input);
      expect(result.length, 1);
      expect(result[0]['term'], 'x');
    });

    test('strips markdown code fences', () {
      final input = '```json\n[{"term":"a","definition":"b"}]\n```';
      final result = GeminiService.parseResponse(input);
      expect(result.length, 1);
    });

    test('handles leading text before JSON', () {
      final input = 'Here are the flashcards:\n[{"term":"a","definition":"b"}]';
      final result = GeminiService.parseResponse(input);
      expect(result.length, 1);
    });

    test('handles trailing text after JSON', () {
      final input = '[{"term":"a","definition":"b"}]\nHope this helps!';
      final result = GeminiService.parseResponse(input);
      expect(result.length, 1);
    });

    test('filters out empty term/definition', () {
      final input = '[{"term":"a","definition":"b"},{"term":"","definition":"empty"},{"term":"c","definition":""}]';
      final result = GeminiService.parseResponse(input);
      expect(result.length, 1);
      expect(result[0]['term'], 'a');
    });

    test('throws FormatException on completely invalid input', () {
      expect(
        () => GeminiService.parseResponse('not json at all'),
        throwsA(isA<FormatException>()),
      );
    });

    test('returns empty list for object with no list value', () {
      final input = '{"message":"no cards found"}';
      final result = GeminiService.parseResponse(input);
      expect(result, isEmpty);
    });

    test('handles whitespace and newlines in JSON', () {
      final input = '''
      [
        { "term" : "  hello  " , "definition" : "  world  " }
      ]
      ''';
      final result = GeminiService.parseResponse(input);
      expect(result.length, 1);
      expect(result[0]['term'], 'hello');
      expect(result[0]['definition'], 'world');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/services/on_device_ai_service.dart';

void main() {
  group('OnDeviceAiService.parseLocalModelResponse', () {
    test('parses well-formed JSON array', () {
      final input = '[{"term":"apple","definition":"蘋果"},{"term":"banana","definition":"香蕉"}]';
      final results = OnDeviceAiService.parseLocalModelResponse(input);
      expect(results.length, 2);
      expect(results[0]['term'], 'apple');
      expect(results[0]['definition'], '蘋果');
      expect(results[1]['term'], 'banana');
    });

    test('parses output that continues from prompt (no leading [)', () {
      // The prompt ends with "Output:\n[" so model output starts after [
      final input = '{"term":"hello","definition":"你好"},{"term":"world","definition":"世界"}]';
      final results = OnDeviceAiService.parseLocalModelResponse(input);
      expect(results.length, 2);
      expect(results[0]['term'], 'hello');
    });

    test('handles truncated JSON (missing closing bracket)', () {
      final input = '[{"term":"cat","definition":"貓"},{"term":"dog","definition":"狗"}';
      final results = OnDeviceAiService.parseLocalModelResponse(input);
      expect(results.length, 2);
    });

    test('handles trailing comma before ]', () {
      final input = '[{"term":"red","definition":"紅色"},{"term":"blue","definition":"藍色"},]';
      final results = OnDeviceAiService.parseLocalModelResponse(input);
      expect(results.length, 2);
    });

    test('handles extra text before JSON', () {
      final input = 'Here are the flashcards:\n[{"term":"sun","definition":"太陽"}]';
      final results = OnDeviceAiService.parseLocalModelResponse(input);
      expect(results.length, 1);
      expect(results[0]['term'], 'sun');
    });

    test('handles extra text after JSON', () {
      final input = '[{"term":"moon","definition":"月亮"}]\nI hope this helps!';
      final results = OnDeviceAiService.parseLocalModelResponse(input);
      expect(results.length, 1);
      expect(results[0]['term'], 'moon');
    });

    test('extracts via regex when JSON is badly broken', () {
      final input = '{"term":"star","definition":"星星"} some garbage {"term":"sky","definition":"天空"}';
      final results = OnDeviceAiService.parseLocalModelResponse(input);
      expect(results.length, 2);
      expect(results[0]['term'], 'star');
      expect(results[1]['term'], 'sky');
    });

    test('passes through items where term equals definition (filtering is caller responsibility)', () {
      final input = '[{"term":"test","definition":"test"},{"term":"good","definition":"好"}]';
      final results = OnDeviceAiService.parseLocalModelResponse(input);
      expect(results.length, 2);
    });

    test('handles reversed key order (definition before term)', () {
      final input = '[{"definition":"水","term":"water"}]';
      final results = OnDeviceAiService.parseLocalModelResponse(input);
      expect(results.length, 1);
      expect(results[0]['term'], 'water');
      expect(results[0]['definition'], '水');
    });

    test('returns empty for completely unparseable input', () {
      final input = 'I cannot process this image.';
      final results = OnDeviceAiService.parseLocalModelResponse(input);
      expect(results, isEmpty);
    });

    test('handles markdown code fences around JSON', () {
      final input = '```json\n[{"term":"fire","definition":"火"}]\n```';
      final results = OnDeviceAiService.parseLocalModelResponse(input);
      expect(results.length, 1);
      expect(results[0]['term'], 'fire');
    });

    test('handles partially truncated last object', () {
      final input = '[{"term":"a","definition":"1"},{"term":"b","definition":"2"},{"term":"c","defini';
      final results = OnDeviceAiService.parseLocalModelResponse(input);
      // Should recover at least the first 2 complete objects
      expect(results.length, greaterThanOrEqualTo(2));
    });

    test('handles exampleSentence field when present', () {
      final input = '[{"term":"run","definition":"跑","exampleSentence":"I run every day."}]';
      final results = OnDeviceAiService.parseLocalModelResponse(input);
      expect(results.length, 1);
      expect(results[0]['term'], 'run');
    });
  });
}

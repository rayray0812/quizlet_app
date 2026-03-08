import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/services/gemini_service.dart';
import 'package:recall_app/services/groq_vision_service.dart';

void main() {
  group('GroqVisionService.buildRequestBody (Vision)', () {
    test('builds correct request structure with image', () {
      final body = GroqVisionService.buildRequestBody(
        prompt: 'Extract flashcards',
        dataUri: 'data:image/jpeg;base64,/9j/4AAQ...',
      );

      expect(body['model'], 'meta-llama/llama-4-scout-17b-16e-instruct');
      expect(body['temperature'], 0);
      expect(body['max_tokens'], 8192);
      expect(body['response_format'], {'type': 'json_object'});

      final messages = body['messages'] as List;
      expect(messages.length, 1);

      final content = messages[0]['content'] as List;
      expect(content.length, 2);
      expect(content[0]['type'], 'text');
      expect(content[0]['text'], 'Extract flashcards');
      expect(content[1]['type'], 'image_url');
      expect(content[1]['image_url']['url'], 'data:image/jpeg;base64,/9j/4AAQ...');
    });

    test('user role is set correctly', () {
      final body = GroqVisionService.buildRequestBody(
        prompt: 'test',
        dataUri: 'data:image/png;base64,abc',
      );
      final messages = body['messages'] as List;
      expect(messages[0]['role'], 'user');
    });
  });

  group('GroqVisionService.buildTextRequestBody (Text-only)', () {
    test('builds correct text-only request structure', () {
      final body = GroqVisionService.buildTextRequestBody(
        prompt: 'Structure this OCR text into flashcards',
      );

      expect(body['model'], 'meta-llama/llama-4-scout-17b-16e-instruct');
      expect(body['temperature'], 0);
      expect(body['max_tokens'], 8192);
      expect(body['response_format'], {'type': 'json_object'});

      final messages = body['messages'] as List;
      expect(messages.length, 1);
      expect(messages[0]['role'], 'user');

      // Text-only: content is a string, not a list
      final content = messages[0]['content'];
      expect(content, isA<String>());
      expect(content, contains('Structure this OCR text'));
    });

    test('text-only request has no image_url part', () {
      final body = GroqVisionService.buildTextRequestBody(
        prompt: 'test prompt',
      );

      final messages = body['messages'] as List;
      final content = messages[0]['content'];
      // Content is a plain string, not a list with image_url
      expect(content, isA<String>());
      expect(content, isNot(contains('image_url')));
    });
  });

  group('GroqVisionService.canUseTextOnly', () {
    test('returns false for null', () {
      expect(GroqVisionService.canUseTextOnly(null), false);
    });

    test('returns false for empty string', () {
      expect(GroqVisionService.canUseTextOnly(''), false);
    });

    test('returns false for short text', () {
      expect(GroqVisionService.canUseTextOnly('hello world'), false);
    });

    test('returns true for sufficient text', () {
      final longText = 'apple 蘋果 banana 香蕉 cherry 櫻桃 dog 狗 elephant 大象';
      expect(GroqVisionService.canUseTextOnly(longText), true);
    });

    test('returns false for whitespace-only text under threshold', () {
      expect(GroqVisionService.canUseTextOnly('   \n\t   '), false);
    });
  });

  group('Groq response parsing (via GeminiService.parseResponse)', () {
    test('parses Groq JSON-mode response with wrapper object', () {
      // Groq JSON mode often wraps arrays in an object
      const response = '{"flashcards":[{"term":"apple","definition":"a fruit","exampleSentence":"I ate an apple."}]}';
      final result = GeminiService.parseResponse(response);
      expect(result.length, 1);
      expect(result[0]['term'], 'apple');
      expect(result[0]['definition'], 'a fruit');
      expect(result[0]['exampleSentence'], 'I ate an apple.');
    });

    test('parses Groq direct array response', () {
      const response = '[{"term":"cat","definition":"a pet","exampleSentence":""}]';
      final result = GeminiService.parseResponse(response);
      expect(result.length, 1);
      expect(result[0]['term'], 'cat');
    });

    test('parses Groq response with "results" key', () {
      const response = '{"results":[{"term":"sun","definition":"a star","exampleSentence":"The sun is bright."}]}';
      final result = GeminiService.parseResponse(response);
      expect(result.length, 1);
      expect(result[0]['term'], 'sun');
    });

    test('filters empty terms from Groq response', () {
      const response = '[{"term":"good","definition":"nice","exampleSentence":""},{"term":"","definition":"bad","exampleSentence":""}]';
      final result = GeminiService.parseResponse(response);
      expect(result.length, 1);
      expect(result[0]['term'], 'good');
    });
  });

  group('Error classification', () {
    test('ScanFailureReason enum has expected values', () {
      expect(ScanFailureReason.values, contains(ScanFailureReason.timeout));
      expect(ScanFailureReason.values, contains(ScanFailureReason.quotaExceeded));
      expect(ScanFailureReason.values, contains(ScanFailureReason.authError));
      expect(ScanFailureReason.values, contains(ScanFailureReason.networkError));
      expect(ScanFailureReason.values, contains(ScanFailureReason.parseError));
    });

    test('ScanException carries reason and message', () {
      final e = ScanException(ScanFailureReason.authError, 'Invalid API key');
      expect(e.reason, ScanFailureReason.authError);
      expect(e.message, 'Invalid API key');
      expect(e.toString(), 'Invalid API key');
    });
  });
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:recall_app/services/gemini_service.dart';
import 'package:recall_app/services/ocr_service.dart';

/// Gemma-backed vocabulary extraction using an OpenAI-compatible endpoint.
///
/// This service is optimized for vocabulary-list import:
/// 1. OCR reads the image on-device
/// 2. OCR text + spatial layout are sent to Gemma
/// 3. Gemma cleans noise and returns structured term-definition pairs
class GemmaVisionService {
  static const _timeout = Duration(seconds: 45);
  static const _maxCards = 300;

  static Future<List<Map<String, String>>> extractVocabularyFlashcards({
    required String apiKey,
    required String endpoint,
    required String model,
    required OcrResult ocrResult,
  }) async {
    if (endpoint.trim().isEmpty) {
      throw ScanException(
        ScanFailureReason.invalidRequest,
        'Gemma endpoint is not configured.',
      );
    }
    if (!ocrResult.hasEnoughText) {
      throw ScanException(
        ScanFailureReason.invalidRequest,
        'OCR did not detect enough text for Gemma vocabulary import.',
      );
    }

    final prompt = _buildVocabularyPrompt(ocrResult);
    final body = jsonEncode(_buildRequestBody(prompt: prompt, model: model));

    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw ScanException(
          _classifyHttpError(response.statusCode, response.body),
          'Gemma API error ${response.statusCode}: ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) return <Map<String, String>>[];

      final message = choices.first['message'] as Map<String, dynamic>?;
      final text = message?['content']?.toString() ?? '';
      if (text.trim().isEmpty) return <Map<String, String>>[];

      final parsed = GeminiService.parseResponse(text);
      if (parsed.length > _maxCards) {
        return parsed.sublist(0, _maxCards);
      }
      return parsed;
    } on TimeoutException {
      throw ScanException(ScanFailureReason.timeout, 'Gemma request timed out.');
    } on ScanException {
      rethrow;
    } on FormatException catch (e) {
      throw ScanException(ScanFailureReason.parseError, e.toString());
    } catch (e) {
      if (kDebugMode) debugPrint('GemmaVisionService error: $e');
      throw ScanException(ScanFailureReason.networkError, e.toString());
    }
  }

  static Map<String, dynamic> _buildRequestBody({
    required String prompt,
    required String model,
  }) {
    return {
      'model': model.trim().isEmpty ? 'gemma-4' : model.trim(),
      'messages': [
        {
          'role': 'system',
          'content':
              'You convert OCR + layout data from vocabulary sheets into clean flashcard JSON.',
        },
        {
          'role': 'user',
          'content': prompt,
        },
      ],
      'temperature': 0.1,
      'max_tokens': 4096,
    };
  }

  static String _buildVocabularyPrompt(OcrResult ocrResult) {
    final width = ocrResult.imageSize.width <= 0 ? 1.0 : ocrResult.imageSize.width;
    final height =
        ocrResult.imageSize.height <= 0 ? 1.0 : ocrResult.imageSize.height;
    final layoutLines = ocrResult.lines.map((line) {
      final left = (line.left / width).toStringAsFixed(3);
      final top = (line.top / height).toStringAsFixed(3);
      final right = (line.right / width).toStringAsFixed(3);
      final bottom = (line.bottom / height).toStringAsFixed(3);
      return '[l=$left,t=$top,r=$right,b=$bottom] ${line.text.trim()}';
    }).join('\n');

    return '''
You are extracting flashcards from a photographed vocabulary list.

Your job:
1. Use OCR text and normalized bounding-box positions to determine which text is a vocabulary term and which text is its meaning.
2. Rely on relative position, row alignment, column structure, spacing, and repeated layout patterns.
3. Ignore noise such as page titles, lesson names, headers, numbering-only rows, labels, page numbers, scores, dates, and decorative text.
4. Keep original language. Do not translate.
5. Only include exampleSentence when an actual example sentence is visible in the same row/group. Otherwise use empty string.
6. Do not hallucinate missing meanings.

Return ONLY a valid JSON array.
Each item must be:
{"term":"...","definition":"...","exampleSentence":"..."}

OCR full text:
---
${ocrResult.fullText.trim()}
---

OCR lines with normalized boxes:
---
$layoutLines
---
''';
  }

  static ScanFailureReason _classifyHttpError(int statusCode, String body) {
    if (statusCode == 429) return ScanFailureReason.quotaExceeded;
    if (statusCode == 401 || statusCode == 403) {
      return ScanFailureReason.authError;
    }
    if (statusCode == 400 || statusCode == 404) {
      return ScanFailureReason.invalidRequest;
    }
    if (statusCode >= 500) return ScanFailureReason.serverError;

    final msg = body.toLowerCase();
    if (msg.contains('rate limit')) return ScanFailureReason.quotaExceeded;
    if (msg.contains('api key') || msg.contains('unauthorized')) {
      return ScanFailureReason.authError;
    }
    return ScanFailureReason.unknown;
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

enum PhotoScanMode { vocabularyList, textbookPage }

/// Specific failure reasons for UI to display.
enum ScanFailureReason { timeout, quotaExceeded, parseError, networkError, unknown }

class ScanException implements Exception {
  final ScanFailureReason reason;
  final String message;

  ScanException(this.reason, this.message);

  @override
  String toString() => message;
}

class GeminiService {
  static const _models = ['gemini-2.0-flash', 'gemini-3-flash-preview'];
  static const _timeout = Duration(seconds: 30);
  static const maxCards = 50;

  static const _vocabularyPrompt =
      'Extract all term-definition pairs from this vocabulary list/word table image. '
      'Keep original language. For bilingual content, use one language as term and the other as definition. '
      'Skip headers and page numbers. '
      'Also include an example sentence for each term in the same language when possible. '
      'If no clear sentence is available, return empty string for exampleSentence.';

  static const _textbookPrompt =
      'Extract 5-15 key concepts from this textbook/study material image as flashcard pairs. '
      'Create concise term (question/concept) and definition (answer/explanation). '
      'Keep original language. Focus on testable knowledge points. '
      'Also provide an example sentence in the same language when possible; otherwise use empty string.';

  static final _responseSchema = Schema.array(
    items: Schema.object(
      properties: {
        'term': Schema.string(description: 'The term or question'),
        'definition': Schema.string(description: 'The definition or answer'),
        'exampleSentence': Schema.string(
          description:
              'Optional example sentence for the term. Empty string when unavailable.',
        ),
      },
      requiredProperties: ['term', 'definition'],
    ),
  );

  /// Extract flashcards from an image using Gemini Flash.
  /// Tries models in order; falls back to the next on quota/rate errors.
  /// Returns a list of {term, definition, exampleSentence} maps.
  /// Throws [ScanException] with a specific reason on failure.
  static Future<List<Map<String, String>>> extractFlashcards({
    required String apiKey,
    required Uint8List imageBytes,
    required String mimeType,
    required PhotoScanMode mode,
  }) async {
    final prompt = switch (mode) {
      PhotoScanMode.vocabularyList => _vocabularyPrompt,
      PhotoScanMode.textbookPage => _textbookPrompt,
    };

    final content = Content.multi([
      TextPart(prompt),
      DataPart(mimeType, imageBytes),
    ]);

    ScanException? lastError;

    for (final modelName in _models) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0,
            maxOutputTokens: 4096,
            responseMimeType: 'application/json',
            responseSchema: _responseSchema,
          ),
        );
        final response =
            await model.generateContent([content]).timeout(_timeout);
        final text = response.text;
        if (text == null || text.trim().isEmpty) return [];

        final results = parseResponse(text);
        if (results.length > maxCards) {
          return results.sublist(0, maxCards);
        }
        return results;
      } on TimeoutException {
        lastError =
            ScanException(ScanFailureReason.timeout, 'Request timed out');
      } on GenerativeAIException catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('quota') ||
            msg.contains('rate limit') ||
            msg.contains('rate_limit') ||
            msg.contains('429') ||
            msg.contains('resource has been exhausted') ||
            msg.contains('resource_exhausted')) {
          // Quota/rate error — try next model
          lastError =
              ScanException(ScanFailureReason.quotaExceeded, e.toString());
          continue;
        }
        lastError = ScanException(ScanFailureReason.unknown, e.toString());
      } on FormatException catch (e) {
        lastError =
            ScanException(ScanFailureReason.parseError, e.toString());
      } catch (e) {
        if (e is ScanException) rethrow;
        lastError =
            ScanException(ScanFailureReason.networkError, e.toString());
      }
    }

    throw lastError ??
        ScanException(ScanFailureReason.unknown, 'All models failed');
  }

  /// Parses Gemini response text into flashcard maps.
  /// Visible for testing.
  static List<Map<String, String>> parseResponse(String raw) {
    var cleaned = raw.trim();

    // Strip markdown code fences if present
    if (cleaned.startsWith('```')) {
      final firstNewline = cleaned.indexOf('\n');
      if (firstNewline != -1) {
        cleaned = cleaned.substring(firstNewline + 1);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3).trim();
      }
    }

    // Extract JSON from response - find first [ or { and last ] or }
    final bracketIdx = cleaned.indexOf('[');
    final braceIdx = cleaned.indexOf('{');
    int startIdx = -1;
    if (bracketIdx != -1 && braceIdx != -1) {
      startIdx = bracketIdx < braceIdx ? bracketIdx : braceIdx;
    } else if (bracketIdx != -1) {
      startIdx = bracketIdx;
    } else if (braceIdx != -1) {
      startIdx = braceIdx;
    }
    if (startIdx != -1) {
      cleaned = cleaned.substring(startIdx);
      final lastBracket = cleaned.lastIndexOf(']');
      final lastBrace = cleaned.lastIndexOf('}');
      final endIdx = lastBracket > lastBrace ? lastBracket : lastBrace;
      if (endIdx != -1) {
        cleaned = cleaned.substring(0, endIdx + 1);
      }
    }

    final decoded = jsonDecode(cleaned);
    List<dynamic> items;

    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map) {
      // Support {"cards": [...]} or {"flashcards": [...]} or any key with a list value
      final listValue = decoded.values.firstWhere(
        (v) => v is List,
        orElse: () => null,
      );
      if (listValue is List) {
        items = listValue;
      } else {
        return [];
      }
    } else {
      return [];
    }

    final results = <Map<String, String>>[];

    for (final item in items) {
      if (item is Map) {
        final term = (item['term'] ?? '').toString().trim();
        final definition = (item['definition'] ?? '').toString().trim();
        final exampleSentence = (item['exampleSentence'] ?? '')
            .toString()
            .trim();
        if (term.isNotEmpty && definition.isNotEmpty) {
          results.add({
            'term': term,
            'definition': definition,
            'exampleSentence': exampleSentence,
          });
        }
      }
    }

    return results;
  }
}

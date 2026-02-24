import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:recall_app/features/study/utils/vocabulary_tracker.dart';

/// Feedback for a single conversation turn.
class TurnFeedback {
  final int grammarScore; // 0-5
  final int vocabScore; // 0-5
  final int relevanceScore; // 0-5
  final String correction;
  final String grammarNote;

  const TurnFeedback({
    required this.grammarScore,
    required this.vocabScore,
    required this.relevanceScore,
    this.correction = '',
    this.grammarNote = '',
  });

  double get overallScore =>
      (grammarScore + vocabScore + relevanceScore) / 3.0;

  int get overallScoreRounded => overallScore.round().clamp(1, 5);
}

/// Evaluates student responses in conversation practice.
class ConversationScorer {
  static const _models = ['gemini-2.0-flash-lite'];
  static const _timeout = Duration(seconds: 15);

  /// Evaluate a student's turn using Gemini API (non-blocking).
  static Future<TurnFeedback?> evaluateTurn({
    required String apiKey,
    required String aiQuestion,
    required String userResponse,
    required String scenarioTitle,
    required String difficulty,
    required List<String> targetTerms,
  }) async {
    if (apiKey.isEmpty || userResponse.trim().isEmpty) return null;

    final prompt = '''
Evaluate this student's English conversation response.
Context: "$scenarioTitle" scenario, $difficulty difficulty.
AI asked: "$aiQuestion"
Student replied: "$userResponse"
Target vocabulary: ${targetTerms.take(5).join(', ')}

Score each dimension 0-5 (0=no attempt, 5=excellent):
- grammar: sentence structure and correctness
- vocabulary: use of target words and word choice
- relevance: how well the response answers the question

If there are errors, provide a brief correction and grammar note.
If no errors, leave correction and grammarNote as empty strings.

Return ONLY valid JSON:
{"grammar":N,"vocabulary":N,"relevance":N,"correction":"...","grammarNote":"..."}
''';

    for (final modelName in _models) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0,
            maxOutputTokens: 256,
            responseMimeType: 'application/json',
          ),
        );
        final response = await model
            .generateContent([Content.text(prompt)]).timeout(_timeout);
        final text = response.text?.trim() ?? '';
        if (text.isEmpty) continue;
        return _parseFeedback(text);
      } catch (e) {
        // Stop on rate limit — retrying worsens the 429
        if (_isRateLimitError(e)) return null;
        continue;
      }
    }
    return null;
  }

  static bool _isRateLimitError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('429') ||
        msg.contains('rate limit') ||
        msg.contains('rate_limit') ||
        msg.contains('too many requests');
  }

  /// Offline fallback evaluation based on heuristics.
  static TurnFeedback evaluateOffline({
    required String userResponse,
    required List<String> targetTerms,
    String aiQuestion = '',
  }) {
    final text = userResponse.trim();
    if (text.isEmpty) {
      return const TurnFeedback(
        grammarScore: 0,
        vocabScore: 0,
        relevanceScore: 0,
      );
    }

    // Grammar heuristic: length, structure, basic tense/agreement checks
    final words = text.split(RegExp(r'\s+')).length;
    final hasCapital = text[0] == text[0].toUpperCase();
    final hasPunctuation = RegExp(r'[.!?]$').hasMatch(text);
    var grammarScore = 3;
    if (words >= 5) grammarScore++;
    if (hasCapital && hasPunctuation) grammarScore++;
    // Check basic subject-verb agreement issues
    final lower = text.toLowerCase();
    final svErrors = RegExp(
      r'\b(i is|he are|she are|they is|we is|i are|he have not|she have not)\b',
    );
    if (svErrors.hasMatch(lower)) grammarScore--;
    // Check for tense consistency hints (mixing "yesterday" with present tense markers)
    if ((lower.contains('yesterday') || lower.contains('last week')) &&
        RegExp(r'\b(is|are|am)\b').hasMatch(lower) &&
        !lower.contains('was') &&
        !lower.contains('were')) {
      grammarScore--;
    }
    grammarScore = grammarScore.clamp(1, 5);

    // Vocab heuristic: term coverage
    final tracker = VocabularyTracker.withTerms(
      targetTerms: targetTerms,
      termDefinitions: {},
    );
    final used = tracker.extractUsedTerms(text);
    final vocabRatio =
        targetTerms.isEmpty ? 0.5 : used.length / targetTerms.length;
    var vocabScore = (vocabRatio * 5).round().clamp(1, 5);

    // Relevance heuristic: response length + question keyword overlap
    var relevanceScore = 3;
    if (words >= 8) relevanceScore++;
    if (words >= 15) relevanceScore++;
    // Check if response contains keywords from the AI question
    if (aiQuestion.isNotEmpty) {
      final questionWords = aiQuestion
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((w) => w.length >= 4) // skip short function words
          .toSet();
      final responseWords = lower.split(RegExp(r'\s+')).toSet();
      final overlap = questionWords.intersection(responseWords);
      if (overlap.isNotEmpty) {
        relevanceScore++;
      } else if (questionWords.length >= 3) {
        // No keyword overlap at all — likely off-topic
        relevanceScore--;
      }
    }
    relevanceScore = relevanceScore.clamp(1, 5);

    return TurnFeedback(
      grammarScore: grammarScore,
      vocabScore: vocabScore,
      relevanceScore: relevanceScore,
    );
  }

  static TurnFeedback? _parseFeedback(String text) {
    try {
      // Try to extract JSON from response
      var jsonStr = text;
      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(text);
      if (jsonMatch != null) {
        jsonStr = jsonMatch.group(0)!;
      }
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return TurnFeedback(
        grammarScore: (map['grammar'] as num?)?.toInt().clamp(0, 5) ?? 3,
        vocabScore: (map['vocabulary'] as num?)?.toInt().clamp(0, 5) ?? 3,
        relevanceScore:
            (map['relevance'] as num?)?.toInt().clamp(0, 5) ?? 3,
        correction: _cleanFeedbackText((map['correction'] as String?) ?? ''),
        grammarNote: _cleanFeedbackText((map['grammarNote'] as String?) ?? ''),
      );
    } catch (_) {
      return null;
    }
  }

  static String _cleanFeedbackText(String value) {
    var text = value.trim();
    if (text.isEmpty) return '';
    text = text.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    text = text.replaceFirst(RegExp(r'^(correction:)\s*', caseSensitive: false), '');
    text = text.replaceFirst(RegExp(r'^(grammar note:)\s*', caseSensitive: false), '');
    if (text.startsWith('"') && text.endsWith('"') && text.length > 1) {
      text = text.substring(1, text.length - 1).trim();
    }
    return text;
  }
}

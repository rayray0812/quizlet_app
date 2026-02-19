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
  static const _models = ['gemini-2.0-flash-lite', 'gemini-2.0-flash'];
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
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Offline fallback evaluation based on heuristics.
  static TurnFeedback evaluateOffline({
    required String userResponse,
    required List<String> targetTerms,
  }) {
    final text = userResponse.trim();
    if (text.isEmpty) {
      return const TurnFeedback(
        grammarScore: 0,
        vocabScore: 0,
        relevanceScore: 0,
      );
    }

    // Grammar heuristic: based on length and basic structure
    final words = text.split(RegExp(r'\s+')).length;
    final hasCapital = text[0] == text[0].toUpperCase();
    final hasPunctuation = RegExp(r'[.!?]$').hasMatch(text);
    var grammarScore = 3;
    if (words >= 5) grammarScore++;
    if (hasCapital && hasPunctuation) grammarScore++;
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

    // Relevance heuristic: response length
    var relevanceScore = 3;
    if (words >= 8) relevanceScore++;
    if (words >= 15) relevanceScore++;
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

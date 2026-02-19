import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/features/study/services/conversation_scorer.dart';

void main() {
  group('TurnFeedback', () {
    test('overallScore calculates average', () {
      const feedback = TurnFeedback(
        grammarScore: 4,
        vocabScore: 3,
        relevanceScore: 5,
      );
      expect(feedback.overallScore, 4.0);
    });

    test('overallScoreRounded clamps to 1-5', () {
      const low = TurnFeedback(
        grammarScore: 0,
        vocabScore: 0,
        relevanceScore: 0,
      );
      expect(low.overallScoreRounded, 1); // clamp to minimum 1

      const high = TurnFeedback(
        grammarScore: 5,
        vocabScore: 5,
        relevanceScore: 5,
      );
      expect(high.overallScoreRounded, 5);
    });

    test('default correction and grammarNote are empty', () {
      const feedback = TurnFeedback(
        grammarScore: 3,
        vocabScore: 3,
        relevanceScore: 3,
      );
      expect(feedback.correction, '');
      expect(feedback.grammarNote, '');
    });
  });

  group('ConversationScorer.evaluateOffline', () {
    test('empty response scores zero', () {
      final feedback = ConversationScorer.evaluateOffline(
        userResponse: '',
        targetTerms: ['apple', 'banana'],
      );
      expect(feedback.grammarScore, 0);
      expect(feedback.vocabScore, 0);
      expect(feedback.relevanceScore, 0);
    });

    test('short response without terms gets low vocab score', () {
      final feedback = ConversationScorer.evaluateOffline(
        userResponse: 'Hi.',
        targetTerms: ['apple', 'banana'],
      );
      expect(feedback.vocabScore, lessThanOrEqualTo(2));
      expect(feedback.grammarScore, greaterThanOrEqualTo(1));
    });

    test('response with target terms gets higher vocab score', () {
      final feedback = ConversationScorer.evaluateOffline(
        userResponse: 'I would like an apple and a banana please.',
        targetTerms: ['apple', 'banana'],
      );
      expect(feedback.vocabScore, greaterThanOrEqualTo(4));
    });

    test('long well-formed response gets higher scores', () {
      final feedback = ConversationScorer.evaluateOffline(
        userResponse:
            'I would like to order an apple pie and a banana smoothie for my friends today.',
        targetTerms: ['apple', 'banana'],
      );
      expect(feedback.grammarScore, greaterThanOrEqualTo(4));
      expect(feedback.relevanceScore, greaterThanOrEqualTo(4));
    });

    test('capitalized sentence with punctuation gets grammar bonus', () {
      final feedback = ConversationScorer.evaluateOffline(
        userResponse: 'Could you help me find the apple section?',
        targetTerms: ['apple'],
      );
      expect(feedback.grammarScore, greaterThanOrEqualTo(4));
    });

    test('empty target terms still produces valid scores', () {
      final feedback = ConversationScorer.evaluateOffline(
        userResponse: 'Hello, how are you?',
        targetTerms: [],
      );
      expect(feedback.grammarScore, greaterThanOrEqualTo(1));
      expect(feedback.vocabScore, greaterThanOrEqualTo(1));
      expect(feedback.relevanceScore, greaterThanOrEqualTo(1));
    });
  });

  group('ConversationScorer.evaluateTurn', () {
    test('returns null with empty API key', () async {
      final result = await ConversationScorer.evaluateTurn(
        apiKey: '',
        aiQuestion: 'What do you need?',
        userResponse: 'I need help.',
        scenarioTitle: 'Test',
        difficulty: 'medium',
        targetTerms: ['help'],
      );
      expect(result, isNull);
    });

    test('returns null with empty response', () async {
      final result = await ConversationScorer.evaluateTurn(
        apiKey: 'fake-key',
        aiQuestion: 'What do you need?',
        userResponse: '',
        scenarioTitle: 'Test',
        difficulty: 'medium',
        targetTerms: ['help'],
      );
      expect(result, isNull);
    });
  });
}

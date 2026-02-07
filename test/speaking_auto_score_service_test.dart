import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/features/study/services/speaking_auto_score_service.dart';

void main() {
  group('SpeakingAutoScoreService.computeScore', () {
    test('returns 5 for exact English sentence with normal confidence', () {
      final score = SpeakingAutoScoreService.computeScore(
        term: 'apple',
        sentence: 'I use apple every day.',
        combinedTarget: 'apple I use apple every day.',
        spoken: 'I use apple every day.',
        languageCode: 'en-US',
        confidence: 0.9,
      );

      expect(score, 5);
    });

    test('returns 0 for too short English input', () {
      final score = SpeakingAutoScoreService.computeScore(
        term: 'apple',
        sentence: 'I use apple every day.',
        combinedTarget: 'apple I use apple every day.',
        spoken: 'a',
        languageCode: 'en-US',
        confidence: 0.9,
      );

      expect(score, 0);
    });

    test('low confidence reduces score for otherwise exact match', () {
      final score = SpeakingAutoScoreService.computeScore(
        term: 'apple',
        sentence: 'I use apple every day.',
        combinedTarget: 'apple I use apple every day.',
        spoken: 'I use apple every day.',
        languageCode: 'en-US',
        confidence: 0.2,
      );

      expect(score, 3);
    });

    test('returns 0 for too short CJK input', () {
      final score = SpeakingAutoScoreService.computeScore(
        term: '蘋果',
        sentence: '我每天都會使用蘋果。',
        combinedTarget: '蘋果 我每天都會使用蘋果。',
        spoken: '我',
        languageCode: 'zh-TW',
        confidence: 0.9,
      );

      expect(score, 0);
    });

    test('returns high score for exact CJK sentence', () {
      final score = SpeakingAutoScoreService.computeScore(
        term: '蘋果',
        sentence: '我每天都會使用蘋果。',
        combinedTarget: '蘋果 我每天都會使用蘋果。',
        spoken: '我每天都會使用蘋果',
        languageCode: 'zh-TW',
        confidence: 0.9,
      );

      expect(score, greaterThanOrEqualTo(4));
    });
  });

  group('SpeakingAutoScoreService.scoreFromSimilarity', () {
    test('maps similarity thresholds correctly', () {
      expect(SpeakingAutoScoreService.scoreFromSimilarity(0.93), 5);
      expect(SpeakingAutoScoreService.scoreFromSimilarity(0.80), 4);
      expect(SpeakingAutoScoreService.scoreFromSimilarity(0.63), 3);
      expect(SpeakingAutoScoreService.scoreFromSimilarity(0.50), 2);
      expect(SpeakingAutoScoreService.scoreFromSimilarity(0.10), 1);
      expect(SpeakingAutoScoreService.scoreFromSimilarity(0.00), 0);
    });
  });
}

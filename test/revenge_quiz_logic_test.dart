import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/features/study/screens/revenge_quiz_screen.dart';

void main() {
  group('computeRevengeSummaryCounts', () {
    test('uses main-round totals for summary counts', () {
      final summary = computeRevengeSummaryCounts(
        mainQuestionCount: 10,
        mainScore: 7,
      );

      expect(summary.totalReviewed, 10);
      expect(summary.correctCount, 7);
      expect(summary.wrongCount, 3);
    });

    test('never returns negative wrongCount when inputs are inconsistent', () {
      final summary = computeRevengeSummaryCounts(
        mainQuestionCount: 3,
        mainScore: 7,
      );

      expect(summary.totalReviewed, 3);
      expect(summary.correctCount, 3);
      expect(summary.wrongCount, 0);
    });
  });
}

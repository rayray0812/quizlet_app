import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/services/widget_snapshot_service.dart';

void main() {
  group('WidgetSnapshotService.computeSnapshot', () {
    test('dueTotal=0 → celebration mood with correct copy', () {
      final result = WidgetSnapshotService.computeSnapshot(
        dueTotal: 0,
        dueNew: 0,
        dueLearning: 0,
        dueReview: 0,
        todayReviewed: 12,
        streakDays: 3,
        topSets: [],
        locale: 'zh',
      );

      expect(result['mood'], 'celebration');
      expect(result['emoji'], '\u{1F389}'); // 🎉
      expect(result['headline'], contains('\u5B8C\u6210')); // 完成
      expect(result['estimatedMinutes'], 0);
    });

    test('dueTotal=5 → normal mood, estimatedMinutes=3', () {
      final result = WidgetSnapshotService.computeSnapshot(
        dueTotal: 5,
        dueNew: 2,
        dueLearning: 1,
        dueReview: 2,
        todayReviewed: 8,
        streakDays: 0,
        topSets: [
          (setId: 'a', title: 'Biology', due: 3),
          (setId: 'b', title: 'English', due: 2),
        ],
        locale: 'en',
      );

      expect(result['mood'], 'normal');
      expect(result['emoji'], '\u{1F4DA}'); // 📚
      expect(result['estimatedMinutes'], 3);
      expect(result['headline'], '5 cards due');
    });

    test('dueTotal=15 → urgent mood with streak protection copy', () {
      final result = WidgetSnapshotService.computeSnapshot(
        dueTotal: 15,
        dueNew: 5,
        dueLearning: 5,
        dueReview: 5,
        todayReviewed: 0,
        streakDays: 7,
        topSets: [],
        locale: 'en',
      );

      expect(result['mood'], 'urgent');
      expect(result['emoji'], '\u{1F525}'); // 🔥
      expect(result['headline'], '15 cards waiting');
      expect(result['streakText'], contains('Protect'));
    });

    test('todayReviewed >= dailyTarget → progress=1.0, remaining=0', () {
      final result = WidgetSnapshotService.computeSnapshot(
        dueTotal: 3,
        dueNew: 1,
        dueLearning: 1,
        dueReview: 1,
        todayReviewed: 25,
        streakDays: 2,
        topSets: [],
        locale: 'en',
      );

      expect(result['dailyProgress'], 1.0);
      expect(result['remaining'], 0);
    });

    test('topSets sorted by due desc, max 3', () {
      final result = WidgetSnapshotService.computeSnapshot(
        dueTotal: 20,
        dueNew: 5,
        dueLearning: 5,
        dueReview: 10,
        todayReviewed: 0,
        streakDays: 0,
        topSets: [
          (setId: 'a', title: 'A', due: 2),
          (setId: 'b', title: 'B', due: 8),
          (setId: 'c', title: 'C', due: 5),
          (setId: 'd', title: 'D', due: 3),
        ],
        locale: 'en',
      );

      final topSetsStr = result['topSets'] as String;
      // B(8) should come first, then C(5), then D(3) — A(2) dropped
      expect(topSetsStr, 'B(8), C(5), D(3)');
    });

    test('locale zh vs en produce different copy', () {
      final zhResult = WidgetSnapshotService.computeSnapshot(
        dueTotal: 5,
        dueNew: 2,
        dueLearning: 1,
        dueReview: 2,
        todayReviewed: 5,
        streakDays: 3,
        topSets: [],
        locale: 'zh',
      );

      final enResult = WidgetSnapshotService.computeSnapshot(
        dueTotal: 5,
        dueNew: 2,
        dueLearning: 1,
        dueReview: 2,
        todayReviewed: 5,
        streakDays: 3,
        topSets: [],
        locale: 'en',
      );

      // Headlines should be different languages
      expect(zhResult['headline'], isNot(equals(enResult['headline'])));
      // Both should contain the number 5
      expect(zhResult['headline'], contains('5'));
      expect(enResult['headline'], contains('5'));
      // CTA should differ
      expect(zhResult['ctaText'], isNot(equals(enResult['ctaText'])));
    });
  });
}

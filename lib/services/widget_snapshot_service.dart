import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:recall_app/core/constants/app_constants.dart';

/// Static service that pushes snapshot data to native home-screen widgets.
///
/// Follows the same static pattern as [NotificationService].
class WidgetSnapshotService {
  WidgetSnapshotService._();

  /// Initialize the home_widget plugin (sets App Group for iOS).
  static Future<void> init() async {
    await HomeWidget.setAppGroupId(AppConstants.widgetAppGroupId);
  }

  /// Push a snapshot to native widgets.
  ///
  /// Accepts raw data from providers, computes derived values (mood, copy,
  /// estimated time), then persists each field individually via
  /// [HomeWidget.saveWidgetData] and triggers a native refresh.
  static Future<void> pushSnapshot({
    required int dueTotal,
    required int dueNew,
    required int dueLearning,
    required int dueReview,
    required int todayReviewed,
    required int streakDays,
    required List<({String setId, String title, int due})> topSets,
    required String locale,
  }) async {
    final data = computeSnapshot(
      dueTotal: dueTotal,
      dueNew: dueNew,
      dueLearning: dueLearning,
      dueReview: dueReview,
      todayReviewed: todayReviewed,
      streakDays: streakDays,
      topSets: topSets,
      locale: locale,
    );

    // Persist each field for RemoteViews on Android.
    for (final entry in data.entries) {
      await HomeWidget.saveWidgetData<String>(entry.key, entry.value.toString());
    }

    // Trigger native widget refresh.
    await HomeWidget.updateWidget(
      androidName: AppConstants.widgetAndroidDailyMission,
    );
    await HomeWidget.updateWidget(
      androidName: AppConstants.widgetAndroidPressureBar,
    );

    debugPrint('Widget snapshot pushed: dueTotal=$dueTotal mood=${data["mood"]}');
  }

  /// Pure computation — returns all derived widget fields.
  ///
  /// Exposed as `@visibleForTesting` so unit tests can verify without
  /// touching the platform channel.
  @visibleForTesting
  static Map<String, dynamic> computeSnapshot({
    required int dueTotal,
    required int dueNew,
    required int dueLearning,
    required int dueReview,
    required int todayReviewed,
    required int streakDays,
    required List<({String setId, String title, int due})> topSets,
    required String locale,
  }) {
    // --- Mood ---
    final String mood;
    if (dueTotal == 0) {
      mood = 'celebration';
    } else if (dueTotal <= 10) {
      mood = 'normal';
    } else {
      mood = 'urgent';
    }

    // --- Emoji ---
    final String emoji;
    switch (mood) {
      case 'celebration':
        emoji = '\u{1F389}'; // 🎉
      case 'urgent':
        emoji = '\u{1F525}'; // 🔥
      default:
        emoji = '\u{1F4DA}'; // 📚
    }

    // --- Estimated minutes (approx 30s per card) ---
    final int estimatedMinutes = (dueTotal * 0.5).ceil();

    // --- Daily progress ---
    final int dailyTarget = AppConstants.defaultDailyTarget;
    final double dailyProgress =
        dailyTarget > 0 ? (todayReviewed / dailyTarget).clamp(0.0, 1.0) : 1.0;
    final int remaining =
        (dailyTarget - todayReviewed).clamp(0, dailyTarget);

    // --- Top sets (max 3, sorted by due desc) ---
    final sorted = List<({String setId, String title, int due})>.from(topSets)
      ..sort((a, b) => b.due.compareTo(a.due));
    final top3 = sorted.take(3).toList();
    final topSetsStr = top3.map((s) => '${s.title}(${s.due})').join(', ');

    // --- i18n copy ---
    final bool isZh = locale.startsWith('zh');

    final String headline;
    final String subtitle;
    final String ctaText;
    final String progressText;
    final String streakText;

    if (mood == 'celebration') {
      headline = isZh ? '\u4ECA\u5929\u5168\u90E8\u5B8C\u6210\uFF01' : 'All clear today!';
      subtitle = isZh ? '\u4F60\u592A\u68D2\u4E86' : 'You nailed it.';
      ctaText = isZh ? '\u700F\u89BD\u5361\u7247' : 'Browse';
    } else if (mood == 'urgent') {
      headline = isZh
          ? '$dueTotal \u5F35\u5361\u7247\u7B49\u8457\u4F60'
          : '$dueTotal cards waiting';
      subtitle = isZh
          ? '\u7D04 $estimatedMinutes \u5206\u9418'
          : '~$estimatedMinutes min';
      ctaText = isZh ? '\u958B\u59CB\u8907\u7FD2' : 'Review now';
    } else {
      headline = isZh
          ? '$dueTotal \u5F35\u5F85\u8907\u7FD2'
          : '$dueTotal cards due';
      subtitle = isZh
          ? '\u7D04 $estimatedMinutes \u5206\u9418'
          : '~$estimatedMinutes min';
      ctaText = isZh ? '\u8907\u7FD2' : 'Review';
    }

    if (streakDays > 0 && dueTotal > 0) {
      streakText = isZh
          ? '\u{1F525} $streakDays \u5929\u9023\u7E8C\uFF0C\u5225\u65B7\u4E86\uFF01'
          : '\u{1F525} $streakDays-day streak. Protect it!';
    } else if (streakDays > 0) {
      streakText = isZh
          ? '\u{1F525} \u9023\u7E8C $streakDays \u5929'
          : '\u{1F525} $streakDays-day streak';
    } else {
      streakText = isZh
          ? '\u4ECA\u5929\u958B\u59CB\u9023\u7E8C\uFF01'
          : 'Start a streak today!';
    }

    progressText = isZh
        ? '\u5269\u4F59 $remaining \u5F35'
        : '$remaining left';

    return {
      'mood': mood,
      'emoji': emoji,
      'dueTotal': dueTotal,
      'dueNew': dueNew,
      'dueLearning': dueLearning,
      'dueReview': dueReview,
      'todayReviewed': todayReviewed,
      'streakDays': streakDays,
      'estimatedMinutes': estimatedMinutes,
      'dailyProgress': dailyProgress,
      'remaining': remaining,
      'topSets': topSetsStr,
      'headline': headline,
      'subtitle': subtitle,
      'ctaText': ctaText,
      'progressText': progressText,
      'streakText': streakText,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/providers/fsrs_provider.dart';
import 'package:recall_app/providers/stats_provider.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/providers/locale_provider.dart';
import 'package:recall_app/services/widget_snapshot_service.dart';

/// Provides a callback that reads current app state and pushes a snapshot
/// to native home-screen widgets.
///
/// Usage: `ref.read(widgetRefreshProvider)();`
final widgetRefreshProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    try {
      final dueTotal = ref.read(dueCountProvider);
      final breakdown = ref.read(dueBreakdownProvider);
      final todayReviewed = ref.read(todayReviewCountProvider);
      final streak = ref.read(streakProvider);
      final locale = ref.read(localeProvider);
      final studySets = ref.read(studySetsProvider);
      final dueCards = ref.read(dueCardsProvider);

      // Aggregate due counts per study set for topSets.
      final setDueCounts = <String, int>{};
      for (final card in dueCards) {
        setDueCounts[card.setId] = (setDueCounts[card.setId] ?? 0) + 1;
      }

      final topSets = <({String setId, String title, int due})>[];
      for (final entry in setDueCounts.entries) {
        final set = studySets.where((s) => s.id == entry.key).firstOrNull;
        if (set != null) {
          topSets.add((setId: set.id, title: set.title, due: entry.value));
        }
      }

      await WidgetSnapshotService.pushSnapshot(
        dueTotal: dueTotal,
        dueNew: breakdown.newCount,
        dueLearning: breakdown.learning,
        dueReview: breakdown.review,
        todayReviewed: todayReviewed,
        streakDays: streak,
        topSets: topSets,
        locale: locale.languageCode,
      );
    } catch (e) {
      debugPrint('Widget refresh failed: $e');
    }
  };
});

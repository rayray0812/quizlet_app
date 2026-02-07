import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/providers/stats_provider.dart';
import 'package:recall_app/features/stats/widgets/daily_chart.dart';
import 'package:recall_app/features/stats/widgets/review_heatmap.dart';
import 'package:recall_app/features/stats/widgets/accuracy_donut.dart';

class StatsScreen extends ConsumerWidget {
  final bool embedded;

  const StatsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final todayCount = ref.watch(todayReviewCountProvider);
    final streakDays = ref.watch(streakProvider);
    final totalCount = ref.watch(totalReviewCountProvider);
    final dailyCounts = ref.watch(dailyCountsProvider);
    final ratingCounts = ref.watch(ratingCountsProvider);
    final speakingTotal = ref.watch(totalSpeakingCountProvider);
    final speakingTodayAvg = ref.watch(todaySpeakingAverageProvider);
    final speakingLast30Avg = ref.watch(last30DaysSpeakingAverageProvider);

    final content = ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Summary cards
          Row(
            children: [
              _SummaryCard(
                label: l10n.todayReviews,
                value: '$todayCount',
                icon: Icons.menu_book_rounded,
                color: AppTheme.indigo,
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                label: l10n.streak,
                value: l10n.nDays(streakDays),
                icon: Icons.local_fire_department_rounded,
                color: AppTheme.orange,
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                label: l10n.totalReviews,
                value: '$totalCount',
                icon: Icons.bar_chart_rounded,
                color: AppTheme.green,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            l10n.speakingPractice,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SummaryCard(
                label: l10n.todaySpeakingAvg,
                value: speakingTodayAvg == null
                    ? '--'
                    : speakingTodayAvg.toStringAsFixed(1),
                icon: Icons.record_voice_over_rounded,
                color: AppTheme.cyan,
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                label: l10n.last30SpeakingAvg,
                value: speakingLast30Avg == null
                    ? '--'
                    : speakingLast30Avg.toStringAsFixed(1),
                icon: Icons.timeline_rounded,
                color: AppTheme.indigo,
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                label: l10n.speakingAttempts,
                value: '$speakingTotal',
                icon: Icons.mic_rounded,
                color: AppTheme.green,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Daily chart
          Text(
            l10n.last30Days,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: DailyChart(dailyCounts: dailyCounts),
          ),
          const SizedBox(height: 28),

          // Heatmap
          const ReviewHeatmap(),
          const SizedBox(height: 28),

          // Rating breakdown
          Text(
            l10n.ratingBreakdown,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: AccuracyDonut(ratingCounts: ratingCounts),
          ),
        ],
      );

    if (!embedded) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.statistics)),
        body: content,
      );
    }

    return content;
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: AppTheme.softCardDecoration(
          fillColor: Theme.of(context).cardColor,
          borderRadius: 16,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


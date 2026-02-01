import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizlet_app/core/l10n/app_localizations.dart';
import 'package:quizlet_app/providers/stats_provider.dart';
import 'package:quizlet_app/features/stats/widgets/daily_chart.dart';
import 'package:quizlet_app/features/stats/widgets/review_heatmap.dart';
import 'package:quizlet_app/features/stats/widgets/accuracy_donut.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final todayCount = ref.watch(todayReviewCountProvider);
    final streakDays = ref.watch(streakProvider);
    final totalCount = ref.watch(totalReviewCountProvider);
    final dailyCounts = ref.watch(dailyCountsProvider);
    final ratingCounts = ref.watch(ratingCountsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statistics)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Summary cards
          Row(
            children: [
              _SummaryCard(
                label: l10n.todayReviews,
                value: '$todayCount',
                icon: Icons.today,
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                label: l10n.streak,
                value: l10n.nDays(streakDays),
                icon: Icons.local_fire_department,
              ),
              const SizedBox(width: 12),
              _SummaryCard(
                label: l10n.totalReviews,
                value: '$totalCount',
                icon: Icons.bar_chart,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Daily chart
          Text(
            l10n.last30Days,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
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
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: AccuracyDonut(ratingCounts: ratingCounts),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';

class AccuracyDonut extends StatelessWidget {
  final ({int again, int hard, int good, int easy}) ratingCounts;

  const AccuracyDonut({super.key, required this.ratingCounts});

  @override
  Widget build(BuildContext context) {
    final total =
        ratingCounts.again + ratingCounts.hard + ratingCounts.good + ratingCounts.easy;

    if (total == 0) {
      return Center(
        child: Text(
          '--',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: ratingCounts.again.toDouble(),
                  color: Colors.red,
                  title: '${(ratingCounts.again / total * 100).round()}%',
                  titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  radius: 50,
                ),
                PieChartSectionData(
                  value: ratingCounts.hard.toDouble(),
                  color: Colors.orange,
                  title: '${(ratingCounts.hard / total * 100).round()}%',
                  titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  radius: 50,
                ),
                PieChartSectionData(
                  value: ratingCounts.good.toDouble(),
                  color: Colors.green,
                  title: '${(ratingCounts.good / total * 100).round()}%',
                  titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  radius: 50,
                ),
                PieChartSectionData(
                  value: ratingCounts.easy.toDouble(),
                  color: Colors.blue,
                  title: '${(ratingCounts.easy / total * 100).round()}%',
                  titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  radius: 50,
                ),
              ],
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Legend(color: Colors.red, label: l10n.ratingAgain, count: ratingCounts.again),
            const SizedBox(height: 6),
            _Legend(color: Colors.orange, label: l10n.ratingHard, count: ratingCounts.hard),
            const SizedBox(height: 6),
            _Legend(color: Colors.green, label: l10n.ratingGood, count: ratingCounts.good),
            const SizedBox(height: 6),
            _Legend(color: Colors.blue, label: l10n.ratingEasy, count: ratingCounts.easy),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _Legend({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text('$label ($count)', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

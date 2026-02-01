import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DailyChart extends StatelessWidget {
  final List<({DateTime date, int count})> dailyCounts;

  const DailyChart({super.key, required this.dailyCounts});

  @override
  Widget build(BuildContext context) {
    final maxY = dailyCounts.fold<int>(0, (max, e) => e.count > max ? e.count : max);

    return BarChart(
      BarChartData(
        maxY: (maxY + 2).toDouble(),
        barGroups: dailyCounts.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.count.toDouble(),
                color: Theme.of(context).colorScheme.primary,
                width: 6,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                // Show label every 7 days
                if (idx % 7 != 0 || idx >= dailyCounts.length) {
                  return const SizedBox.shrink();
                }
                final date = dailyCounts[idx].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${date.month}/${date.day}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = dailyCounts[group.x];
              return BarTooltipItem(
                '${item.date.month}/${item.date.day}: ${item.count}',
                TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

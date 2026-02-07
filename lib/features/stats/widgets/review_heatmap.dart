import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/providers/stats_provider.dart';

/// GitHub-style 7?52 heatmap for the last 365 days.
class ReviewHeatmap extends ConsumerWidget {
  const ReviewHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(heatmapDataProvider);
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);

    // Calculate the start date (364 days ago, aligned to start of week)
    final startDate = today.subtract(const Duration(days: 364));
    // Align to Monday
    final alignedStart =
        startDate.subtract(Duration(days: (startDate.weekday - 1) % 7));

    // Find max count for color scaling
    final maxCount = data.values.fold<int>(0, (m, v) => v > m ? v : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 7 * 14.0, // 7 rows ? (10 box + 4 gap)
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(53, (weekIndex) {
                return Column(
                  children: List.generate(7, (dayIndex) {
                    final date =
                        alignedStart.add(Duration(days: weekIndex * 7 + dayIndex));
                    if (date.isAfter(today)) {
                      return const SizedBox(width: 14, height: 14);
                    }
                    final count = data[date] ?? 0;
                    return Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _getColor(context, count, maxCount),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Color _getColor(BuildContext context, int count, int maxCount) {
    if (count == 0) {
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
    final primary = Theme.of(context).colorScheme.primary;
    if (maxCount == 0) return primary;
    final ratio = count / maxCount;
    if (ratio < 0.25) return primary.withValues(alpha: 0.3);
    if (ratio < 0.5) return primary.withValues(alpha: 0.5);
    if (ratio < 0.75) return primary.withValues(alpha: 0.75);
    return primary;
  }
}


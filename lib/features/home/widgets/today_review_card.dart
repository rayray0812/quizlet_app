import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizlet_app/providers/fsrs_provider.dart';
import 'package:quizlet_app/core/l10n/app_localizations.dart';

/// Banner shown at top of home screen showing total due cards + breakdown.
class TodayReviewCard extends ConsumerWidget {
  const TodayReviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueCount = ref.watch(dueCountProvider);
    final breakdown = ref.watch(dueBreakdownProvider);
    final l10n = AppLocalizations.of(context);

    if (dueCount == 0) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        onTap: () => context.push('/review'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Large due count
              Column(
                children: [
                  Text(
                    '$dueCount',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    l10n.todayReview,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Breakdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BreakdownRow(
                      label: l10n.newCards,
                      count: breakdown.newCount,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 6),
                    _BreakdownRow(
                      label: l10n.learningCards,
                      count: breakdown.learning,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 6),
                    _BreakdownRow(
                      label: l10n.reviewCards,
                      count: breakdown.review,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_circle_filled,
                size: 40,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _BreakdownRow({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '$count $label',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quizlet_app/core/l10n/app_localizations.dart';

class ReviewSummaryScreen extends StatelessWidget {
  final int totalReviewed;
  final int againCount;
  final int hardCount;
  final int goodCount;
  final int easyCount;

  const ReviewSummaryScreen({
    super.key,
    required this.totalReviewed,
    required this.againCount,
    required this.hardCount,
    required this.goodCount,
    required this.easyCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final correctCount = goodCount + easyCount;
    final percent = totalReviewed > 0
        ? (correctCount / totalReviewed * 100).round()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reviewComplete),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                percent >= 80 ? Icons.celebration : Icons.bar_chart,
                size: 72,
                color: percent >= 80
                    ? Colors.amber
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.reviewComplete,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.reviewedNCards(totalReviewed),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              // Rating breakdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatColumn(
                    label: 'Again',
                    count: againCount,
                    color: Colors.red,
                  ),
                  _StatColumn(
                    label: 'Hard',
                    count: hardCount,
                    color: Colors.orange,
                  ),
                  _StatColumn(
                    label: 'Good',
                    count: goodCount,
                    color: Colors.green,
                  ),
                  _StatColumn(
                    label: 'Easy',
                    count: easyCount,
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Accuracy
              Text(
                l10n.percentCorrect(percent),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: () => context.go('/'),
                child: Text(l10n.done),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

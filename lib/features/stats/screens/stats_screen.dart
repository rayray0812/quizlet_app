import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/app_back_button.dart';
import 'package:recall_app/features/stats/widgets/accuracy_donut.dart';
import 'package:recall_app/features/stats/widgets/daily_chart.dart';
import 'package:recall_app/features/stats/widgets/review_heatmap.dart';
import 'package:recall_app/providers/stats_provider.dart';

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

    final content = Stack(
      children: [
        Positioned(
          top: -40,
          right: -20,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.indigo.withValues(alpha: 0.14),
                  AppTheme.indigo.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        ListView(
          padding: EdgeInsets.fromLTRB(16, embedded ? 22 : 16, 16, 28),
          children: [
            if (!embedded) ...[
              Text(
                l10n.statistics,
                style: GoogleFonts.notoSerifTc(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Every review builds your memory map',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      letterSpacing: 0.4,
                    ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              decoration: AppTheme.softCardDecoration(
                fillColor: Colors.white,
                borderRadius: 12,
                borderColor: Theme.of(context).colorScheme.outlineVariant,
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _HeroMetric(
                          value: '$todayCount',
                          label: l10n.todayReviews,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      Expanded(
                        child: _HeroMetric(
                          value: '$streakDays',
                          label: l10n.streak,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      Expanded(
                        child: _HeroMetric(
                          value: '$totalCount',
                          label: l10n.totalReviews,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push('/achievements'),
              icon: const Icon(Icons.emoji_events_rounded, size: 18),
              label: Text(l10n.achievements),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                side: BorderSide(
                  color: AppTheme.indigo.withValues(alpha: 0.32),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _SectionTitle(title: l10n.speakingPractice),
            const SizedBox(height: 8),
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
                const SizedBox(width: 10),
                _SummaryCard(
                  label: l10n.last30SpeakingAvg,
                  value: speakingLast30Avg == null
                      ? '--'
                      : speakingLast30Avg.toStringAsFixed(1),
                  icon: Icons.timeline_rounded,
                  color: AppTheme.indigo,
                ),
                const SizedBox(width: 10),
                _SummaryCard(
                  label: l10n.speakingAttempts,
                  value: '$speakingTotal',
                  icon: Icons.mic_rounded,
                  color: AppTheme.green,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionTitle(title: l10n.last30Days),
            const SizedBox(height: 8),
            _Panel(
              child: SizedBox(height: 210, child: DailyChart(dailyCounts: dailyCounts)),
            ),
            const SizedBox(height: 16),
            _Panel(child: const ReviewHeatmap()),
            const SizedBox(height: 20),
            _SectionTitle(title: l10n.ratingBreakdown),
            const SizedBox(height: 8),
            _Panel(
              child: SizedBox(
                height: 210,
                child: AccuracyDonut(ratingCounts: ratingCounts),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Learning is visible in your streaks.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    if (!embedded) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: Text(l10n.statistics),
        ),
        body: content,
      );
    }

    return content;
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.indigo,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.notoSerifTc(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String value;
  final String label;

  const _HeroMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.notoSerifTc(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppTheme.indigo,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.softCardDecoration(
        fillColor: Theme.of(context).cardColor,
        borderRadius: 12,
      ),
      padding: const EdgeInsets.all(12),
      child: child,
    );
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
          borderRadius: 12,
          borderColor: color.withValues(alpha: 0.2),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.notoSerifTc(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}



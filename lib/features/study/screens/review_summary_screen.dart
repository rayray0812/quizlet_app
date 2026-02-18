import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/adaptive_glass_card.dart';
import 'package:recall_app/features/study/utils/encouragement_lines.dart';

class ReviewSummaryScreen extends StatefulWidget {
  final int totalReviewed;
  final int againCount;
  final int hardCount;
  final int goodCount;
  final int easyCount;
  final bool challengeMode;
  final int? challengeTarget;
  final bool challengeCompleted;
  final bool isRevengeMode;
  final int revengeCardCount;

  const ReviewSummaryScreen({
    super.key,
    required this.totalReviewed,
    required this.againCount,
    required this.hardCount,
    required this.goodCount,
    required this.easyCount,
    this.challengeMode = false,
    this.challengeTarget,
    this.challengeCompleted = false,
    this.isRevengeMode = false,
    this.revengeCardCount = 0,
  });

  @override
  State<ReviewSummaryScreen> createState() => _ReviewSummaryScreenState();
}

class _ReviewSummaryScreenState extends State<ReviewSummaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late final String _encouragement;

  int get _percent {
    final correctCount = widget.goodCount + widget.easyCount;
    return widget.totalReviewed > 0
        ? (correctCount / widget.totalReviewed * 100).round()
        : 0;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _encouragement = EncouragementLines.pick(_percent);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = _percent;
    final challengeTarget = widget.challengeTarget;
    final accentColor = percent >= 80 ? AppTheme.green : AppTheme.indigo;
    final needsMorePractice = widget.againCount + widget.hardCount > 0;

    void goHomeSmooth() {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.popUntil((route) => route.isFirst);
        return;
      }
      context.go('/');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reviewComplete),
        automaticallyImplyLeading: false,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerLowest,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: AdaptiveGlassCard(
                        borderRadius: 24,
                        fillColor: Theme.of(context).cardColor,
                        elevation: 1.6,
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: _AccuracyRing(
                              percent: percent,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.reviewComplete,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.reviewedNCards(widget.totalReviewed),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              l10n.percentCorrect(percent),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: accentColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            _encouragement,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _RatingChip(
                                label: l10n.ratingAgain,
                                count: widget.againCount,
                                color: AppTheme.red,
                                icon: Icons.replay_rounded,
                              ),
                              _RatingChip(
                                label: l10n.ratingHard,
                                count: widget.hardCount,
                                color: AppTheme.orange,
                                icon: Icons.trending_flat_rounded,
                              ),
                              _RatingChip(
                                label: l10n.ratingGood,
                                count: widget.goodCount,
                                color: AppTheme.green,
                                icon: Icons.check_rounded,
                              ),
                              _RatingChip(
                                label: l10n.ratingEasy,
                                count: widget.easyCount,
                                color: AppTheme.indigo,
                                icon: Icons.bolt_rounded,
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          if (widget.challengeMode && challengeTarget != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (widget.challengeCompleted
                                        ? AppTheme.green
                                        : AppTheme.orange)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.challengeCompleted
                                    ? l10n.challengeCompleteDetail(challengeTarget)
                                    : l10n.challengeProgressDetail(widget.totalReviewed, challengeTarget),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: widget.challengeCompleted
                                      ? AppTheme.green
                                      : AppTheme.orange,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (widget.isRevengeMode && widget.revengeCardCount > 0) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.verified_rounded, color: AppTheme.purple, size: 20),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      l10n.revengeClearedCount(widget.revengeCardCount),
                                      style: const TextStyle(
                                        color: AppTheme.purple,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (needsMorePractice) ...[
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => context.go('/review'),
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(l10n.startReview),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: goHomeSmooth,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(l10n.done),
                            ),
                          ),
                        ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _RatingChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccuracyRing extends StatelessWidget {
  final int percent;
  final Color color;

  const _AccuracyRing({required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: 122,
          height: 122,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 122,
                height: 122,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 10,
                  backgroundColor: color.withValues(alpha: 0.14),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    percent >= 80
                        ? Icons.celebration_rounded
                        : Icons.bar_chart_rounded,
                    color: color,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(value * 100).round()}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/providers/fsrs_provider.dart';

/// Banner shown at top of home screen showing total due cards + breakdown.
class TodayReviewCard extends ConsumerStatefulWidget {
  /// When false, the glow/arrow animation is paused to save resources.
  final bool animating;

  const TodayReviewCard({super.key, this.animating = true});

  @override
  ConsumerState<TodayReviewCard> createState() => _TodayReviewCardState();
}

class _TodayReviewCardState extends ConsumerState<TodayReviewCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
    if (widget.animating) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant TodayReviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animating && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.animating && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dueCount = ref.watch(dueCountProvider);
    final breakdown = ref.watch(dueBreakdownProvider);
    final l10n = AppLocalizations.of(context);

    if (dueCount == 0) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTap: () {
              setState(() => _pressed = false);
              context.push('/review');
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.98 : 1,
              duration: const Duration(milliseconds: 120),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                decoration: AppTheme.softCardDecoration(
                  fillColor: Colors.white,
                  borderRadius: 12,
                  borderColor: AppTheme.indigo.withValues(alpha: 0.26),
                  elevation: 1.0 + (_pulse.value * 0.4),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.todayReview,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.outline,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$dueCount',
                                  style: GoogleFonts.notoSerifTc(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.indigo,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => context.push('/review'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: Text(l10n.startReview),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _BreakdownChip(
                            label: l10n.newCards,
                            count: breakdown.newCount,
                            color: AppTheme.breakdownNew,
                          ),
                          _BreakdownChip(
                            label: l10n.learningCards,
                            count: breakdown.learning,
                            color: AppTheme.breakdownLearning,
                          ),
                          _BreakdownChip(
                            label: l10n.reviewCards,
                            count: breakdown.review,
                            color: AppTheme.breakdownReview,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BreakdownChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _BreakdownChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            '$count $label',
            style: GoogleFonts.notoSansTc(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3A3A38),
            ),
          ),
        ],
      ),
    );
  }
}

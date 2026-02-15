import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/providers/fsrs_provider.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/liquid_glass.dart';

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
  late final AnimationController _glowController;
  late final Animation<double> _glow;
  late final Animation<Offset> _arrowFloat;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    );
    if (widget.animating) _glowController.repeat(reverse: true);
    _glow = CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);
    _arrowFloat =
        Tween<Offset>(
          begin: const Offset(-0.08, 0),
          end: const Offset(0.08, 0),
        ).animate(
          CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
        );
  }

  @override
  void didUpdateWidget(covariant TodayReviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animating && !_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    } else if (!widget.animating && _glowController.isAnimating) {
      _glowController.stop();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dueCount = ref.watch(dueCountProvider);
    final breakdown = ref.watch(dueBreakdownProvider);
    final l10n = AppLocalizations.of(context);

    if (dueCount == 0) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              context.push('/review');
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: _buildCardShell(
                context,
                glowValue: _glow.value,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Large due count
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$dueCount',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.todayReview,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 28),
                      // Breakdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _BreakdownRow(
                              label: l10n.newCards,
                              count: breakdown.newCount,
                              color: AppTheme.breakdownNew,
                            ),
                            const SizedBox(height: 8),
                            _BreakdownRow(
                              label: l10n.learningCards,
                              count: breakdown.learning,
                              color: AppTheme.breakdownLearning,
                            ),
                            const SizedBox(height: 8),
                            _BreakdownRow(
                              label: l10n.reviewCards,
                              count: breakdown.review,
                              color: AppTheme.breakdownReview,
                            ),
                          ],
                        ),
                      ),
                      // Start arrow
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SlideTransition(
                          position: _arrowFloat,
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
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

  Widget _buildCardShell(
    BuildContext context, {
    required double glowValue,
    required Widget child,
  }) {
    if (isLiquidGlassSupported) {
      return LiquidGlass(
        borderRadius: 20,
        blurSigma: 24,
        tintColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
        shadows: [
          BoxShadow(
            color: AppTheme.indigo.withValues(alpha: 0.12 + (glowValue * 0.08)),
            blurRadius: 14 + (glowValue * 7),
            offset: const Offset(0, 8),
          ),
        ],
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.indigo.withValues(alpha: 0.2),
                AppTheme.purple.withValues(alpha: 0.16),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppTheme.indigo.withValues(alpha: 0.84),
            AppTheme.purple.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.indigo.withValues(alpha: 0.14 + (glowValue * 0.1)),
            blurRadius: 10 + (glowValue * 7),
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
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
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

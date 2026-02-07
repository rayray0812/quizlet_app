import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/providers/fsrs_provider.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';

/// Banner shown at top of home screen showing total due cards + breakdown.
class TodayReviewCard extends ConsumerStatefulWidget {
  const TodayReviewCard({super.key});

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
    )..repeat(reverse: true);
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
              child: Container(
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
                      color: AppTheme.indigo.withValues(
                        alpha: 0.14 + (_glow.value * 0.1),
                      ),
                      blurRadius: 10 + (_glow.value * 7),
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
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
                              color: const Color(0xFF82D9FF),
                            ),
                            const SizedBox(height: 8),
                            _BreakdownRow(
                              label: l10n.learningCards,
                              count: breakdown.learning,
                              color: const Color(0xFFFFD580),
                            ),
                            const SizedBox(height: 8),
                            _BreakdownRow(
                              label: l10n.reviewCards,
                              count: breakdown.review,
                              color: const Color(0xFF80FFB0),
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


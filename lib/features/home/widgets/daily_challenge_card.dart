import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/providers/daily_challenge_provider.dart';

class DailyChallengeCard extends ConsumerStatefulWidget {
  const DailyChallengeCard({super.key});

  @override
  ConsumerState<DailyChallengeCard> createState() => _DailyChallengeCardState();
}

class _DailyChallengeCardState extends ConsumerState<DailyChallengeCard> {
  bool _hasShownToast = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(dailyChallengeStatusProvider);
    final l10n = AppLocalizations.of(context);

    ref.listen<DailyChallengeStatus>(dailyChallengeStatusProvider, (prev, next) {
      if (next.isCompleted && !(prev?.isCompleted ?? false) && !_hasShownToast) {
        _hasShownToast = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.challengeCompletedToast),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    final canStart = !status.isCompleted && status.dueNow > 0;
    final sessionCount = (status.remaining == 0 || status.dueNow == 0)
        ? 0
        : status.remaining.clamp(1, status.dueNow).toInt();
    final progress = status.target == 0
        ? 0.0
        : (status.reviewedToday / status.target).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          if (canStart) {
            context.push(
              '/review',
              extra: {
                'maxCards': sessionCount,
                'challengeMode': true,
                'challengeTarget': status.target,
              },
            );
          }
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
                colors: status.isCompleted
                    ? [
                        AppTheme.green.withValues(alpha: 0.88),
                        AppTheme.cyan.withValues(alpha: 0.82),
                      ]
                    : [
                        AppTheme.orange.withValues(alpha: 0.92),
                        AppTheme.red.withValues(alpha: 0.86),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (status.isCompleted ? AppTheme.green : AppTheme.orange)
                      .withValues(alpha: _pressed ? 0.1 : 0.2),
                  blurRadius: _pressed ? 8 : 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        status.isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.local_fire_department_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.dailyChallenge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Text(
                        l10n.challengeStreak(status.currentStreak),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    status.isCompleted
                        ? l10n.challengeTodayComplete(status.target)
                        : l10n.challengeProgress(
                            status.reviewedToday, status.target),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          status.isCompleted
                              ? l10n.challengeCompleteMsg
                              : status.dueNow == 0
                                  ? l10n.challengeNoDueCards
                                  : l10n.challengeNextRun(sessionCount),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: canStart
                            ? () {
                                context.push(
                                  '/review',
                                  extra: {
                                    'maxCards': sessionCount,
                                    'challengeMode': true,
                                    'challengeTarget': status.target,
                                  },
                                );
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor:
                              status.isCompleted ? AppTheme.green : AppTheme.red,
                        ),
                        icon: Icon(status.isCompleted
                            ? Icons.check_rounded
                            : Icons.play_arrow_rounded),
                        label: Text(status.isCompleted ? l10n.done : l10n.play),
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
  }
}

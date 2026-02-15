import 'package:flutter/material.dart';
import 'package:recall_app/core/icons/material_icon_mapper.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/adaptive_glass_card.dart';
import 'package:recall_app/models/badge.dart';

class BadgeCard extends StatelessWidget {
  final AppBadge badge;

  const BadgeCard({super.key, required this.badge});

  String _getTitle(AppLocalizations l10n) {
    final map = {
      'badgeFirstReview': l10n.badgeFirstReview,
      'badgeStreak7': l10n.badgeStreak7,
      'badgeStreak30': l10n.badgeStreak30,
      'badgeReviews100': l10n.badgeReviews100,
      'badgeReviews1000': l10n.badgeReviews1000,
      'badgeMastered50': l10n.badgeMastered50,
      'badgeRevengeClear': l10n.badgeRevengeClear,
      'badgeSets10': l10n.badgeSets10,
      'badgePerfectQuiz': l10n.badgePerfectQuiz,
      'badgeChallenge30': l10n.badgeChallenge30,
      'badgePhoto10': l10n.badgePhoto10,
      'badgeSpeedrun': l10n.badgeSpeedrun,
    };
    return map[badge.titleKey] ?? badge.titleKey;
  }

  String _getDesc(AppLocalizations l10n) {
    final map = {
      'badgeFirstReviewDesc': l10n.badgeFirstReviewDesc,
      'badgeStreak7Desc': l10n.badgeStreak7Desc,
      'badgeStreak30Desc': l10n.badgeStreak30Desc,
      'badgeReviews100Desc': l10n.badgeReviews100Desc,
      'badgeReviews1000Desc': l10n.badgeReviews1000Desc,
      'badgeMastered50Desc': l10n.badgeMastered50Desc,
      'badgeRevengeClearDesc': l10n.badgeRevengeClearDesc,
      'badgeSets10Desc': l10n.badgeSets10Desc,
      'badgePerfectQuizDesc': l10n.badgePerfectQuizDesc,
      'badgeChallenge30Desc': l10n.badgeChallenge30Desc,
      'badgePhoto10Desc': l10n.badgePhoto10Desc,
      'badgeSpeedrunDesc': l10n.badgeSpeedrunDesc,
    };
    return map[badge.descKey] ?? badge.descKey;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unlocked = badge.isUnlocked;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(_getTitle(l10n)),
            content: Text(_getDesc(l10n)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.close),
              ),
            ],
          ),
        );
      },
      child: AdaptiveGlassCard(
        fillColor: unlocked
            ? AppTheme.orange.withValues(alpha: 0.06)
            : Theme.of(context).cardColor,
        borderRadius: 14,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              MaterialIconMapper.fromCodePoint(badge.iconCodePoint),
              size: 36,
              color: unlocked
                  ? AppTheme.orange
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              _getTitle(l10n),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: unlocked
                        ? null
                        : Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:recall_app/models/badge.dart';

class BadgeDefinitions {
  static List<AppBadge> all() => [
        const AppBadge(
          id: 'first_review',
          titleKey: 'badgeFirstReview',
          descKey: 'badgeFirstReviewDesc',
          iconCodePoint: 0xe838, // star
        ),
        const AppBadge(
          id: 'streak_7',
          titleKey: 'badgeStreak7',
          descKey: 'badgeStreak7Desc',
          iconCodePoint: 0xea15, // local_fire_department
        ),
        const AppBadge(
          id: 'streak_30',
          titleKey: 'badgeStreak30',
          descKey: 'badgeStreak30Desc',
          iconCodePoint: 0xe518, // whatshot
        ),
        const AppBadge(
          id: 'reviews_100',
          titleKey: 'badgeReviews100',
          descKey: 'badgeReviews100Desc',
          iconCodePoint: 0xe8e8, // thumb_up
        ),
        const AppBadge(
          id: 'reviews_1000',
          titleKey: 'badgeReviews1000',
          descKey: 'badgeReviews1000Desc',
          iconCodePoint: 0xf0674, // diamond
        ),
        const AppBadge(
          id: 'cards_mastered_50',
          titleKey: 'badgeMastered50',
          descKey: 'badgeMastered50Desc',
          iconCodePoint: 0xea23, // military_tech
        ),
        const AppBadge(
          id: 'revenge_clear',
          titleKey: 'badgeRevengeClear',
          descKey: 'badgeRevengeClearDesc',
          iconCodePoint: 0xe8ac, // shield
        ),
        const AppBadge(
          id: 'sets_created_10',
          titleKey: 'badgeSets10',
          descKey: 'badgeSets10Desc',
          iconCodePoint: 0xeb40, // library_books
        ),
        const AppBadge(
          id: 'perfect_quiz',
          titleKey: 'badgePerfectQuiz',
          descKey: 'badgePerfectQuizDesc',
          iconCodePoint: 0xe1b1, // emoji_events
        ),
        const AppBadge(
          id: 'daily_challenge_30',
          titleKey: 'badgeChallenge30',
          descKey: 'badgeChallenge30Desc',
          iconCodePoint: 0xea3b, // workspace_premium
        ),
        const AppBadge(
          id: 'photo_import_10',
          titleKey: 'badgePhoto10',
          descKey: 'badgePhoto10Desc',
          iconCodePoint: 0xe3b0, // photo_camera
        ),
        const AppBadge(
          id: 'speedrun_match',
          titleKey: 'badgeSpeedrun',
          descKey: 'badgeSpeedrunDesc',
          iconCodePoint: 0xe425, // timer
        ),
      ];
}

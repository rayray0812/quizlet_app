import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/core/constants/supabase_constants.dart';
import 'package:recall_app/models/review_log.dart';
import 'package:recall_app/services/supabase_service.dart';

void main() {
  group('ReviewLog row round-trip preserves all fields', () {
    test('SRS log with default reviewType survives serialize-deserialize', () {
      final original = ReviewLog(
        id: 'log-1',
        cardId: 'card-1',
        setId: 'set-1',
        rating: 3,
        state: 2,
        reviewedAt: DateTime.utc(2026, 4, 26, 10, 30),
        elapsedDays: 5,
        scheduledDays: 12,
        lastStability: 8.5,
        lastDifficulty: 4.2,
      );

      final row = SupabaseService.reviewLogToRow(original, 'user-1');
      final restored = SupabaseService.rowToReviewLog(row);

      expect(restored.id, original.id);
      expect(restored.cardId, original.cardId);
      expect(restored.setId, original.setId);
      expect(restored.rating, original.rating);
      expect(restored.state, original.state);
      expect(restored.reviewedAt, original.reviewedAt);
      expect(restored.reviewType, 'srs');
      expect(restored.speakingScore, isNull);
      expect(restored.elapsedDays, original.elapsedDays);
      expect(restored.scheduledDays, original.scheduledDays);
      expect(restored.lastStability, original.lastStability);
      expect(restored.lastDifficulty, original.lastDifficulty);
    });

    test('conversation log preserves reviewType and speakingScore', () {
      final original = ReviewLog(
        id: 'log-2',
        cardId: 'conversation_turn_3',
        setId: 'set-1',
        rating: 4,
        state: 0,
        reviewedAt: DateTime.utc(2026, 4, 26, 11, 0),
        reviewType: 'conversation',
        speakingScore: 85,
      );

      final row = SupabaseService.reviewLogToRow(original, 'user-1');
      final restored = SupabaseService.rowToReviewLog(row);

      expect(restored.reviewType, 'conversation');
      expect(restored.speakingScore, 85);
    });

    test('speaking log preserves reviewType and speakingScore', () {
      final original = ReviewLog(
        id: 'log-3',
        cardId: 'card-9',
        setId: 'set-1',
        rating: 3,
        state: 2,
        reviewedAt: DateTime.utc(2026, 4, 26, 12, 15),
        reviewType: 'speaking',
        speakingScore: 72,
      );

      final row = SupabaseService.reviewLogToRow(original, 'user-1');
      final restored = SupabaseService.rowToReviewLog(row);

      expect(restored.reviewType, 'speaking');
      expect(restored.speakingScore, 72);
    });

    test('row missing review_type defaults to srs (backward compatible)', () {
      final legacyRow = <String, dynamic>{
        'id': 'log-legacy',
        'card_id': 'card-1',
        'set_id': 'set-1',
        'user_id': 'user-1',
        'rating': 3,
        'state': 2,
        'reviewed_at': DateTime.utc(2026, 1, 1).toIso8601String(),
        'elapsed_days': 0,
        'scheduled_days': 0,
        'last_stability': 0.0,
        'last_difficulty': 0.0,
      };

      final restored = SupabaseService.rowToReviewLog(legacyRow);

      expect(restored.reviewType, 'srs');
      expect(restored.speakingScore, isNull);
    });
  });


  test('account deletion fallback covers all critical user data tables', () {
    final targets = {
      for (final target in accountDeletionFallbackTargets)
        '${target.table}:${target.userIdColumn}',
    };

    expect(
      targets,
      contains('${SupabaseConstants.reviewLogsTable}:user_id'),
    );
    expect(
      targets,
      contains('${SupabaseConstants.cardProgressTable}:user_id'),
    );
    expect(
      targets,
      contains('${SupabaseConstants.studySetsTable}:user_id'),
    );
    expect(
      targets,
      contains('${SupabaseConstants.foldersTable}:user_id'),
    );
    expect(
      targets,
      contains('${SupabaseConstants.studentAssignmentProgressTable}:student_id'),
    );
    expect(
      targets,
      contains('${SupabaseConstants.classMembersTable}:student_id'),
    );
    expect(
      targets,
      contains('${SupabaseConstants.classesTable}:teacher_id'),
    );
    expect(
      targets,
      contains('${SupabaseConstants.profilesTable}:user_id'),
    );
  });

  test('account deletion fallback avatar candidates cover common formats', () {
    expect(accountDeletionAvatarCandidates, contains('avatar.jpg'));
    expect(accountDeletionAvatarCandidates, contains('avatar.jpeg'));
    expect(accountDeletionAvatarCandidates, contains('avatar.png'));
    expect(accountDeletionAvatarCandidates, contains('avatar.webp'));
  });
}

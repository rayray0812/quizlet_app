import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/core/constants/supabase_constants.dart';
import 'package:recall_app/services/supabase_service.dart';

void main() {
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

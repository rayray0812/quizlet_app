class AdminAccountSummary {
  final String userId;
  final String email;
  final int studySetCount;
  final DateTime? lastActivityAt;
  final bool isBlocked;
  final String classroomRole;

  const AdminAccountSummary({
    required this.userId,
    required this.email,
    required this.studySetCount,
    required this.lastActivityAt,
    required this.isBlocked,
    required this.classroomRole,
  });
}

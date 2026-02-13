class AdminAccountSummary {
  final String userId;
  final int studySetCount;
  final DateTime? lastActivityAt;
  final bool isBlocked;

  const AdminAccountSummary({
    required this.userId,
    required this.studySetCount,
    required this.lastActivityAt,
    required this.isBlocked,
  });
}

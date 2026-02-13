class AdminAuditEntry {
  final int id;
  final String actorUserId;
  final String? targetUserId;
  final String action;
  final String reason;
  final DateTime createdAt;

  const AdminAuditEntry({
    required this.id,
    required this.actorUserId,
    required this.targetUserId,
    required this.action,
    required this.reason,
    required this.createdAt,
  });
}

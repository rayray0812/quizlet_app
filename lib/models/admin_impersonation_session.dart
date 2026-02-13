class AdminImpersonationSession {
  final int id;
  final String actorUserId;
  final String targetUserId;
  final String ticketId;
  final String reason;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime expiresAt;
  final String status;

  const AdminImpersonationSession({
    required this.id,
    required this.actorUserId,
    required this.targetUserId,
    required this.ticketId,
    required this.reason,
    required this.startedAt,
    required this.endedAt,
    required this.expiresAt,
    required this.status,
  });
}

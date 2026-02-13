class AdminImpersonationTelemetry {
  final int id;
  final int sessionId;
  final String actorUserId;
  final String targetUserId;
  final String eventType;
  final String eventMessage;
  final DateTime createdAt;

  const AdminImpersonationTelemetry({
    required this.id,
    required this.sessionId,
    required this.actorUserId,
    required this.targetUserId,
    required this.eventType,
    required this.eventMessage,
    required this.createdAt,
  });
}

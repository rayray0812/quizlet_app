class AdminBulkJob {
  final int id;
  final String actorUserId;
  final String jobType;
  final Map<String, dynamic> payload;
  final String status;
  final String summary;
  final int attemptCount;
  final int maxAttempts;
  final String lastError;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? workerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminBulkJob({
    required this.id,
    required this.actorUserId,
    required this.jobType,
    required this.payload,
    required this.status,
    required this.summary,
    required this.attemptCount,
    required this.maxAttempts,
    required this.lastError,
    required this.startedAt,
    required this.finishedAt,
    required this.workerId,
    required this.createdAt,
    required this.updatedAt,
  });
}

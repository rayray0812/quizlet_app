class AdminRiskAlert {
  final int id;
  final String targetUserId;
  final String riskType;
  final String severity;
  final String status;
  final String summary;
  final DateTime createdAt;

  const AdminRiskAlert({
    required this.id,
    required this.targetUserId,
    required this.riskType,
    required this.severity,
    required this.status,
    required this.summary,
    required this.createdAt,
  });
}

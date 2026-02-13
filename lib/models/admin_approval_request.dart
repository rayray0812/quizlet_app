class AdminApprovalRequest {
  final int id;
  final String requestedBy;
  final String actionType;
  final Map<String, dynamic> payload;
  final String reason;
  final String status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectedBy;
  final DateTime? rejectedAt;
  final DateTime createdAt;

  const AdminApprovalRequest({
    required this.id,
    required this.requestedBy,
    required this.actionType,
    required this.payload,
    required this.reason,
    required this.status,
    required this.approvedBy,
    required this.approvedAt,
    required this.rejectedBy,
    required this.rejectedAt,
    required this.createdAt,
  });
}

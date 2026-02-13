class SyncConflict {
  final String setId;
  final String title;
  final DateTime localUpdatedAt;
  final DateTime remoteUpdatedAt;

  const SyncConflict({
    required this.setId,
    required this.title,
    required this.localUpdatedAt,
    required this.remoteUpdatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'setId': setId,
      'title': title,
      'localUpdatedAt': localUpdatedAt.toIso8601String(),
      'remoteUpdatedAt': remoteUpdatedAt.toIso8601String(),
    };
  }

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      setId: json['setId'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      localUpdatedAt:
          DateTime.tryParse(json['localUpdatedAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      remoteUpdatedAt:
          DateTime.tryParse(json['remoteUpdatedAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}

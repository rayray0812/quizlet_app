import 'package:hive/hive.dart';
import 'package:recall_app/models/review_session.dart';

class ReviewSessionAdapter extends TypeAdapter<ReviewSession> {
  @override
  final int typeId = 5;

  @override
  ReviewSession read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return ReviewSession(
      id: map['id'] as String,
      userId: map['userId'] as String,
      modality: map['modality'] as String,
      startedAt: DateTime.parse(map['startedAt'] as String),
      endedAt: map['endedAt'] != null
          ? DateTime.parse(map['endedAt'] as String)
          : null,
      itemCount: map['itemCount'] as int? ?? 0,
      completedCount: map['completedCount'] as int? ?? 0,
      scoreAvg: (map['scoreAvg'] as num?)?.toDouble(),
      metadata: (map['metadata'] as Map?)?.cast<String, dynamic>(),
      isSynced: map['isSynced'] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, ReviewSession obj) {
    writer.writeMap({
      'id': obj.id,
      'userId': obj.userId,
      'modality': obj.modality,
      'startedAt': obj.startedAt.toUtc().toIso8601String(),
      'endedAt': obj.endedAt?.toUtc().toIso8601String(),
      'itemCount': obj.itemCount,
      'completedCount': obj.completedCount,
      'scoreAvg': obj.scoreAvg,
      'metadata': obj.metadata,
      'isSynced': obj.isSynced,
    });
  }
}

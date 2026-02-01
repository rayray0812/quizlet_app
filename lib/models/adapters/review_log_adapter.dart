import 'package:hive/hive.dart';
import 'package:quizlet_app/models/review_log.dart';

class ReviewLogAdapter extends TypeAdapter<ReviewLog> {
  @override
  final int typeId = 3;

  @override
  ReviewLog read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return ReviewLog(
      id: map['id'] as String,
      cardId: map['cardId'] as String,
      setId: map['setId'] as String,
      rating: map['rating'] as int,
      state: map['state'] as int,
      reviewedAt: DateTime.parse(map['reviewedAt'] as String),
      elapsedDays: map['elapsedDays'] as int? ?? 0,
      scheduledDays: map['scheduledDays'] as int? ?? 0,
      lastStability: (map['lastStability'] as num?)?.toDouble() ?? 0.0,
      lastDifficulty: (map['lastDifficulty'] as num?)?.toDouble() ?? 0.0,
      isSynced: map['isSynced'] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, ReviewLog obj) {
    writer.writeMap({
      'id': obj.id,
      'cardId': obj.cardId,
      'setId': obj.setId,
      'rating': obj.rating,
      'state': obj.state,
      'reviewedAt': obj.reviewedAt.toUtc().toIso8601String(),
      'elapsedDays': obj.elapsedDays,
      'scheduledDays': obj.scheduledDays,
      'lastStability': obj.lastStability,
      'lastDifficulty': obj.lastDifficulty,
      'isSynced': obj.isSynced,
    });
  }
}

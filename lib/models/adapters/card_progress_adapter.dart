import 'package:hive/hive.dart';
import 'package:quizlet_app/models/card_progress.dart';

class CardProgressAdapter extends TypeAdapter<CardProgress> {
  @override
  final int typeId = 2;

  @override
  CardProgress read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return CardProgress(
      cardId: map['cardId'] as String,
      setId: map['setId'] as String,
      stability: (map['stability'] as num?)?.toDouble() ?? 0.0,
      difficulty: (map['difficulty'] as num?)?.toDouble() ?? 0.0,
      reps: map['reps'] as int? ?? 0,
      lapses: map['lapses'] as int? ?? 0,
      state: map['state'] as int? ?? 0,
      lastReview: map['lastReview'] != null
          ? DateTime.parse(map['lastReview'] as String)
          : null,
      due: map['due'] != null ? DateTime.parse(map['due'] as String) : null,
      scheduledDays: map['scheduledDays'] as int? ?? 0,
      elapsedDays: map['elapsedDays'] as int? ?? 0,
      isSynced: map['isSynced'] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, CardProgress obj) {
    writer.writeMap({
      'cardId': obj.cardId,
      'setId': obj.setId,
      'stability': obj.stability,
      'difficulty': obj.difficulty,
      'reps': obj.reps,
      'lapses': obj.lapses,
      'state': obj.state,
      'lastReview': obj.lastReview?.toUtc().toIso8601String(),
      'due': obj.due?.toUtc().toIso8601String(),
      'scheduledDays': obj.scheduledDays,
      'elapsedDays': obj.elapsedDays,
      'isSynced': obj.isSynced,
    });
  }
}

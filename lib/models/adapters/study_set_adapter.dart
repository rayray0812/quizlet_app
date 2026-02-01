import 'package:hive/hive.dart';
import 'package:quizlet_app/models/flashcard.dart';
import 'package:quizlet_app/models/study_set.dart';

class StudySetAdapter extends TypeAdapter<StudySet> {
  @override
  final int typeId = 0;

  @override
  StudySet read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    final cardsList = (map['cards'] as List?)
            ?.map((c) => Flashcard(
                  id: c['id'] as String,
                  term: c['term'] as String,
                  definition: c['definition'] as String,
                  difficultyLevel: c['difficultyLevel'] as int? ?? 0,
                  imageUrl: c['imageUrl'] as String? ?? '',
                  tags: (c['tags'] as List?)?.cast<String>() ?? [],
                ))
            .toList() ??
        [];

    return StudySet(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      cards: cardsList,
      isSynced: map['isSynced'] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, StudySet obj) {
    writer.writeMap({
      'id': obj.id,
      'title': obj.title,
      'description': obj.description,
      'createdAt': obj.createdAt.toIso8601String(),
      'cards': obj.cards
          .map((c) => {
                'id': c.id,
                'term': c.term,
                'definition': c.definition,
                'difficultyLevel': c.difficultyLevel,
                'imageUrl': c.imageUrl,
                'tags': c.tags,
              })
          .toList(),
      'isSynced': obj.isSynced,
    });
  }
}

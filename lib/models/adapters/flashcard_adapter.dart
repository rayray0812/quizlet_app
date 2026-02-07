import 'package:hive/hive.dart';
import 'package:recall_app/models/flashcard.dart';

class FlashcardAdapter extends TypeAdapter<Flashcard> {
  @override
  final int typeId = 1;

  @override
  Flashcard read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return Flashcard(
      id: map['id'] as String,
      term: map['term'] as String,
      definition: map['definition'] as String,
      exampleSentence: map['exampleSentence'] as String? ?? '',
      difficultyLevel: map['difficultyLevel'] as int? ?? 0,
      imageUrl: map['imageUrl'] as String? ?? '',
      tags: (map['tags'] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, Flashcard obj) {
    writer.writeMap({
      'id': obj.id,
      'term': obj.term,
      'definition': obj.definition,
      'exampleSentence': obj.exampleSentence,
      'difficultyLevel': obj.difficultyLevel,
      'imageUrl': obj.imageUrl,
      'tags': obj.tags,
    });
  }
}


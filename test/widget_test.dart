import 'package:flutter_test/flutter_test.dart';
import 'package:quizlet_app/models/flashcard.dart';
import 'package:quizlet_app/models/study_set.dart';

void main() {
  test('StudySet can be created with cards', () {
    final set = StudySet(
      id: 'test-id',
      title: 'Test Set',
      createdAt: DateTime(2024, 1, 1),
      cards: [
        const Flashcard(id: '1', term: 'Hello', definition: 'World'),
        const Flashcard(id: '2', term: 'Foo', definition: 'Bar'),
      ],
    );

    expect(set.cards.length, 2);
    expect(set.title, 'Test Set');
    expect(set.isSynced, false);
  });

  test('Flashcard default difficulty is 0', () {
    const card = Flashcard(id: '1', term: 'A', definition: 'B');
    expect(card.difficultyLevel, 0);
  });
}

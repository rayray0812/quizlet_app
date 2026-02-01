import 'package:flutter_test/flutter_test.dart';
import 'package:quizlet_app/models/flashcard.dart';
import 'package:quizlet_app/models/study_set.dart';
import 'package:quizlet_app/models/card_progress.dart';
import 'package:quizlet_app/models/review_log.dart';
import 'package:quizlet_app/services/fsrs_service.dart';

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

  test('Flashcard supports tags', () {
    const card = Flashcard(
      id: '1',
      term: 'A',
      definition: 'B',
      tags: ['vocab', 'chapter1'],
    );
    expect(card.tags, ['vocab', 'chapter1']);
  });

  test('Flashcard default tags is empty', () {
    const card = Flashcard(id: '1', term: 'A', definition: 'B');
    expect(card.tags, isEmpty);
  });

  group('CardProgress', () {
    test('can be created with defaults', () {
      const progress = CardProgress(cardId: 'c1', setId: 's1');
      expect(progress.stability, 0.0);
      expect(progress.difficulty, 0.0);
      expect(progress.reps, 0);
      expect(progress.lapses, 0);
      expect(progress.state, 0); // New
      expect(progress.lastReview, isNull);
      expect(progress.due, isNull);
      expect(progress.isSynced, false);
    });

    test('copyWith preserves unmodified fields', () {
      const progress = CardProgress(cardId: 'c1', setId: 's1');
      final updated = progress.copyWith(stability: 5.0, reps: 1);
      expect(updated.cardId, 'c1');
      expect(updated.setId, 's1');
      expect(updated.stability, 5.0);
      expect(updated.reps, 1);
      expect(updated.difficulty, 0.0);
    });

    test('serializes to/from JSON', () {
      final now = DateTime.utc(2024, 6, 15);
      final progress = CardProgress(
        cardId: 'c1',
        setId: 's1',
        stability: 10.5,
        difficulty: 4.2,
        reps: 3,
        state: 2,
        lastReview: now,
        due: now.add(const Duration(days: 5)),
      );
      final json = progress.toJson();
      final restored = CardProgress.fromJson(json);
      expect(restored.cardId, 'c1');
      expect(restored.stability, 10.5);
      expect(restored.state, 2);
    });
  });

  group('ReviewLog', () {
    test('can be created', () {
      final log = ReviewLog(
        id: 'log1',
        cardId: 'c1',
        setId: 's1',
        rating: 3,
        state: 0,
        reviewedAt: DateTime.utc(2024, 6, 15),
      );
      expect(log.rating, 3);
      expect(log.state, 0);
    });

    test('serializes to/from JSON', () {
      final log = ReviewLog(
        id: 'log1',
        cardId: 'c1',
        setId: 's1',
        rating: 4,
        state: 2,
        reviewedAt: DateTime.utc(2024, 6, 15),
        lastStability: 5.0,
        lastDifficulty: 3.0,
      );
      final json = log.toJson();
      final restored = ReviewLog.fromJson(json);
      expect(restored.rating, 4);
      expect(restored.lastStability, 5.0);
    });
  });

  group('FsrsService', () {
    late FsrsService service;

    setUp(() {
      service = FsrsService();
    });

    test('reviewCard updates a new card', () {
      const progress = CardProgress(cardId: 'c1', setId: 's1');
      final result = service.reviewCard(progress, 3); // Good

      expect(result.progress.reps, 1);
      expect(result.progress.stability, greaterThan(0));
      expect(result.progress.difficulty, greaterThan(0));
      expect(result.progress.lastReview, isNotNull);
      expect(result.progress.due, isNotNull);

      expect(result.log.cardId, 'c1');
      expect(result.log.setId, 's1');
      expect(result.log.rating, 3);
      expect(result.log.state, 0); // was New before review
    });

    test('reviewCard with Again increments lapses', () {
      const progress = CardProgress(cardId: 'c1', setId: 's1');
      final result = service.reviewCard(progress, 1); // Again

      expect(result.progress.lapses, 1);
    });

    test('reviewCard with Easy on new card', () {
      const progress = CardProgress(cardId: 'c1', setId: 's1');
      final result = service.reviewCard(progress, 4); // Easy

      expect(result.progress.reps, 1);
      expect(result.progress.due, isNotNull);
      // Easy should give a longer interval than Again
      expect(result.progress.due!.isAfter(DateTime.now().toUtc()), isTrue);
    });

    test('getSchedulingPreview returns 4 entries', () {
      const progress = CardProgress(cardId: 'c1', setId: 's1');
      final preview = service.getSchedulingPreview(progress);

      expect(preview.length, 4);
      expect(preview.keys, containsAll([1, 2, 3, 4]));
      // Each should be a non-empty string
      for (final v in preview.values) {
        expect(v, isNotEmpty);
      }
    });

    test('getRetrievability for new card is 0', () {
      const progress = CardProgress(cardId: 'c1', setId: 's1');
      expect(service.getRetrievability(progress), 0.0);
    });

    test('multiple reviews increase reps', () {
      const progress = CardProgress(cardId: 'c1', setId: 's1');
      final r1 = service.reviewCard(progress, 3);
      final r2 = service.reviewCard(r1.progress, 3);
      expect(r2.progress.reps, 2);
    });
  });
}

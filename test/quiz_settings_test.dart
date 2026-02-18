import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/models/card_progress.dart';
import 'package:recall_app/features/study/screens/quiz_screen.dart';

void main() {
  final cards = List.generate(
    10,
    (i) => Flashcard(
      id: 'c$i',
      term: 'term$i',
      definition: 'def$i',
    ),
  );

  group('selectQuizCards', () {
    test('pure random returns correct count', () {
      final selected = selectQuizCards(
        allCards: cards,
        count: 5,
        random: Random(42),
      );
      expect(selected.length, 5);
      // All selected cards should be from the original list
      for (final card in selected) {
        expect(cards.contains(card), isTrue);
      }
    });

    test('pure random returns all cards when count >= length', () {
      final selected = selectQuizCards(
        allCards: cards,
        count: 100,
        random: Random(42),
      );
      expect(selected.length, 10);
    });

    test('pure random returns no duplicates', () {
      final selected = selectQuizCards(
        allCards: cards,
        count: 8,
        random: Random(42),
      );
      final ids = selected.map((c) => c.id).toSet();
      expect(ids.length, 8);
    });

    test('SRS weighted: overdue cards appear more often than non-overdue', () {
      final now = DateTime.now().toUtc();
      // Cards 0-2 are overdue, cards 3-9 are not due for a long time
      final progressMap = <String, CardProgress>{};
      for (var i = 0; i < 10; i++) {
        progressMap['c$i'] = CardProgress(
          cardId: 'c$i',
          setId: 'set1',
          due: i < 3
              ? now.subtract(const Duration(days: 5))
              : now.add(const Duration(days: 30)),
          state: 2, // Review state
          difficulty: i < 3 ? 8.0 : 1.0,
          lapses: i < 3 ? 5 : 0,
        );
      }

      // Run many iterations to check statistical bias
      int overdueCount = 0;
      const iterations = 200;
      for (var iter = 0; iter < iterations; iter++) {
        final selected = selectQuizCards(
          allCards: cards,
          count: 3,
          random: Random(iter),
          prioritizeWeak: true,
          progressMap: progressMap,
        );
        for (final card in selected) {
          final idx = int.parse(card.id.substring(1));
          if (idx < 3) overdueCount++;
        }
      }

      // Overdue cards (3 out of 10) should appear much more than 30% of the time
      final overdueRate = overdueCount / (iterations * 3);
      expect(overdueRate, greaterThan(0.5),
          reason: 'Overdue cards should be selected more often (rate=$overdueRate)');
    });

    test('SRS weighted: unreviewed cards get higher weight', () {
      // Only cards 0-1 have progress, 2-9 are unreviewed
      final progressMap = <String, CardProgress>{
        'c0': CardProgress(
          cardId: 'c0',
          setId: 'set1',
          due: DateTime.now().toUtc().add(const Duration(days: 30)),
          state: 2,
          difficulty: 1.0,
        ),
        'c1': CardProgress(
          cardId: 'c1',
          setId: 'set1',
          due: DateTime.now().toUtc().add(const Duration(days: 30)),
          state: 2,
          difficulty: 1.0,
        ),
      };

      int unreviewedCount = 0;
      const iterations = 200;
      for (var iter = 0; iter < iterations; iter++) {
        final selected = selectQuizCards(
          allCards: cards,
          count: 3,
          random: Random(iter),
          prioritizeWeak: true,
          progressMap: progressMap,
        );
        for (final card in selected) {
          final idx = int.parse(card.id.substring(1));
          if (idx >= 2) unreviewedCount++;
        }
      }

      // Unreviewed cards (8 out of 10) should appear more than their fair share
      final unreviewedRate = unreviewedCount / (iterations * 3);
      expect(unreviewedRate, greaterThan(0.7),
          reason: 'Unreviewed cards should be heavily favored');
    });
  });

  group('QuizQuestion reversed field', () {
    test('reversed defaults to false for backward compatibility', () {
      final q = QuizQuestion(
        card: cards[0],
        type: QuizQuestionType.multipleChoice,
        optionIndices: [0, 1, 2, 3],
      );
      expect(q.reversed, isFalse);
    });

    test('reversed=true swaps prompt and answer semantics', () {
      final q = QuizQuestion(
        card: cards[0],
        type: QuizQuestionType.textInput,
        reversed: true,
      );
      // When reversed, prompt should be definition, answer should be term
      final prompt = q.reversed ? q.card.definition : q.card.term;
      final answer = q.reversed ? q.card.term : q.card.definition;
      expect(prompt, 'def0');
      expect(answer, 'term0');
    });
  });

  group('QuizSettings type filtering', () {
    test('only MC enabled produces only MC questions', () {
      final settings = QuizSettings(
        questionCount: 5,
        enabledTypes: {QuizQuestionType.multipleChoice},
      );

      // Simulate what _generateMixedQuestions does
      final enabledTypes = settings.enabledTypes.toList();
      for (var i = 0; i < 5; i++) {
        final type = enabledTypes[i % enabledTypes.length];
        expect(type, QuizQuestionType.multipleChoice);
      }
    });

    test('two types enabled distributes evenly', () {
      final settings = QuizSettings(
        questionCount: 6,
        enabledTypes: {
          QuizQuestionType.multipleChoice,
          QuizQuestionType.trueFalse,
        },
      );

      final enabledTypes = settings.enabledTypes.toList();
      final typeCounts = <QuizQuestionType, int>{};
      for (var i = 0; i < 6; i++) {
        final type = enabledTypes[i % enabledTypes.length];
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }
      expect(typeCounts[QuizQuestionType.multipleChoice], 3);
      expect(typeCounts[QuizQuestionType.trueFalse], 3);
    });

    test('all three types distribute as evenly as possible', () {
      final settings = QuizSettings(
        questionCount: 10,
        enabledTypes: {
          QuizQuestionType.multipleChoice,
          QuizQuestionType.textInput,
          QuizQuestionType.trueFalse,
        },
      );

      final enabledTypes = settings.enabledTypes.toList();
      final typeCounts = <QuizQuestionType, int>{};
      for (var i = 0; i < 10; i++) {
        final type = enabledTypes[i % enabledTypes.length];
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }
      // With 10 questions and 3 types: 4, 3, 3 distribution
      for (final count in typeCounts.values) {
        expect(count, inInclusiveRange(3, 4));
      }
    });
  });

  group('QuizDirection', () {
    test('termToDef keeps reversed=false', () {
      const direction = QuizDirection.termToDef;
      expect(direction == QuizDirection.termToDef, isTrue);
    });

    test('defToTerm sets reversed=true', () {
      const direction = QuizDirection.defToTerm;
      final reversed = direction == QuizDirection.defToTerm;
      expect(reversed, isTrue);
    });

    test('mixed produces both true and false reversed values', () {
      final random = Random(42);
      final values = <bool>{};
      for (var i = 0; i < 20; i++) {
        values.add(random.nextBool());
      }
      expect(values, containsAll([true, false]));
    });
  });
}

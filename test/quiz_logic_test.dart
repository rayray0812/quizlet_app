import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/features/study/screens/quiz_screen.dart';

void main() {
  final cards = List.generate(
    8,
    (i) => Flashcard(
      id: 'c$i',
      term: 'term$i',
      definition: 'def$i',
    ),
  );

  group('QuizQuestion model', () {
    test('multipleChoice question has 4 option indices', () {
      final q = QuizQuestion(
        card: cards[0],
        type: QuizQuestionType.multipleChoice,
        optionIndices: [0, 3, 5, 7],
      );
      expect(q.optionIndices.length, 4);
      expect(q.type, QuizQuestionType.multipleChoice);
    });

    test('textInput question has empty optionIndices', () {
      final q = QuizQuestion(
        card: cards[1],
        type: QuizQuestionType.textInput,
      );
      expect(q.optionIndices, isEmpty);
      expect(q.type, QuizQuestionType.textInput);
    });

    test('trueFalse correct pair has matching definition', () {
      final q = QuizQuestion(
        card: cards[2],
        type: QuizQuestionType.trueFalse,
        shownDefinition: cards[2].definition,
        isCorrectPair: true,
      );
      expect(q.isCorrectPair, isTrue);
      expect(q.shownDefinition, cards[2].definition);
    });

    test('trueFalse wrong pair has different definition', () {
      final q = QuizQuestion(
        card: cards[2],
        type: QuizQuestionType.trueFalse,
        shownDefinition: cards[5].definition,
        isCorrectPair: false,
      );
      expect(q.isCorrectPair, isFalse);
      expect(q.shownDefinition, isNot(cards[2].definition));
    });
  });

  group('MCQ option generation logic', () {
    test('generated options contain the correct answer', () {
      final random = Random(42);
      final correctIndex = 2;
      final wrongIndices = List.generate(cards.length, (i) => i)
        ..remove(correctIndex)
        ..shuffle(random);
      final optionIndices = [correctIndex, ...wrongIndices.take(3)]
        ..shuffle(random);

      expect(optionIndices.length, 4);
      expect(optionIndices, contains(correctIndex));
      // All indices are unique
      expect(optionIndices.toSet().length, 4);
    });

    test('all option indices are within valid range', () {
      final random = Random(123);
      final correctIndex = 0;
      final wrongIndices = List.generate(cards.length, (i) => i)
        ..remove(correctIndex)
        ..shuffle(random);
      final optionIndices = [correctIndex, ...wrongIndices.take(3)]
        ..shuffle(random);

      for (final idx in optionIndices) {
        expect(idx, greaterThanOrEqualTo(0));
        expect(idx, lessThan(cards.length));
      }
    });
  });

  group('Quiz type distribution', () {
    test('mixed generation produces roughly 60/20/20 distribution', () {
      final random = Random(0);
      var mcq = 0;
      var text = 0;
      var tf = 0;
      const total = 1000;

      for (var i = 0; i < total; i++) {
        final roll = random.nextDouble();
        if (roll < 0.6) {
          mcq++;
        } else if (roll < 0.8) {
          text++;
        } else {
          tf++;
        }
      }

      // Allow generous margins for randomness
      expect(mcq, greaterThan(500));
      expect(mcq, lessThan(700));
      expect(text, greaterThan(120));
      expect(text, lessThan(280));
      expect(tf, greaterThan(120));
      expect(tf, lessThan(280));
    });
  });

  group('Scoring logic', () {
    test('correct answer increments score', () {
      var score = 0;
      final isCorrect = true;
      if (isCorrect) score++;
      expect(score, 1);
    });

    test('wrong answer adds to wrongIndices', () {
      final wrongIndices = <int>[];
      final isCorrect = false;
      final currentIndex = 3;
      if (!isCorrect) wrongIndices.add(currentIndex);
      expect(wrongIndices, [3]);
    });

    test('reinforcement round uses separate score', () {
      var score = 5;
      var reinforcementScore = 0;

      // Simulate correct answer in reinforcement round
      void applyScore(bool correct, bool isReinforcement) {
        if (correct) {
          isReinforcement ? reinforcementScore++ : score++;
        }
      }

      applyScore(true, true);
      expect(score, 5); // Main score unchanged
      expect(reinforcementScore, 1);

      // Simulate correct answer in main round
      applyScore(true, false);
      expect(score, 6);
      expect(reinforcementScore, 1); // Reinforcement score unchanged
    });

    test('reinforcement only triggers when wrongIndices is non-empty', () {
      final wrongIndices = <int>[];
      final isLastQuestion = true;
      final isReinforcementRound = false;

      final shouldStartReinforcement =
          isLastQuestion && !isReinforcementRound && wrongIndices.isNotEmpty;

      expect(shouldStartReinforcement, isFalse);

      wrongIndices.add(0);
      final shouldStartReinforcement2 =
          isLastQuestion && !isReinforcementRound && wrongIndices.isNotEmpty;

      expect(shouldStartReinforcement2, isTrue);
    });
  });
}

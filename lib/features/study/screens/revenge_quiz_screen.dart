import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/features/study/widgets/quiz_option_tile.dart';
import 'package:recall_app/features/study/widgets/text_input_question.dart';
import 'package:recall_app/features/study/widgets/true_false_question.dart';
import 'package:recall_app/features/study/widgets/rounded_progress_bar.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/app_back_button.dart';

enum _QuestionType { multipleChoice, textInput, trueFalse }

class _QuizQuestion {
  final Flashcard card;
  final _QuestionType type;
  final List<int> optionIndices;
  final String shownDefinition;
  final bool isCorrectPair;

  const _QuizQuestion({
    required this.card,
    required this.type,
    this.optionIndices = const [],
    this.shownDefinition = '',
    this.isCorrectPair = true,
  });
}

class RevengeQuizScreen extends ConsumerStatefulWidget {
  final List<String> cardIds;

  const RevengeQuizScreen({super.key, required this.cardIds});

  @override
  ConsumerState<RevengeQuizScreen> createState() => _RevengeQuizScreenState();
}

class _RevengeQuizScreenState extends ConsumerState<RevengeQuizScreen> {
  final _random = Random();
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedOption;
  late List<Flashcard> _allCards;
  late List<_QuizQuestion> _questions;
  final List<int> _wrongIndices = [];
  bool _isReinforcementRound = false;
  int _reinforcementScore = 0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initQuiz();
  }

  void _initQuiz() {
    // Collect all flashcards from all study sets
    final allSets = ref.read(studySetsProvider);
    final cardMap = <String, Flashcard>{};
    for (final s in allSets) {
      for (final c in s.cards) {
        cardMap[c.id] = c;
      }
    }

    // Resolve the revenge card IDs to actual Flashcard objects
    final revengeCards = <Flashcard>[];
    for (final id in widget.cardIds) {
      final card = cardMap[id];
      if (card != null) revengeCards.add(card);
    }

    if (revengeCards.length < 4) {
      _initialized = false;
      return;
    }

    // _allCards = all unique cards (for generating wrong options)
    _allCards = cardMap.values.toList();

    final shuffled = List.of(revengeCards)..shuffle(_random);
    _questions = _generateMixedQuestions(shuffled);
    _currentIndex = 0;
    _score = 0;
    _selectedOption = null;
    _wrongIndices.clear();
    _isReinforcementRound = false;
    _reinforcementScore = 0;
    _initialized = true;
  }

  List<_QuizQuestion> _generateMixedQuestions(List<Flashcard> cards) {
    final questions = <_QuizQuestion>[];
    for (final card in cards) {
      final roll = _random.nextDouble();
      _QuestionType type;
      if (roll < 0.6) {
        type = _QuestionType.multipleChoice;
      } else if (roll < 0.8) {
        type = _QuestionType.textInput;
      } else {
        type = _QuestionType.trueFalse;
      }
      questions.add(_buildQuestion(card, type));
    }
    return questions;
  }

  _QuizQuestion _buildQuestion(Flashcard card, _QuestionType type) {
    switch (type) {
      case _QuestionType.multipleChoice:
        final correctIndex = _allCards.indexOf(card);
        final wrongIndices = List.generate(_allCards.length, (i) => i)
          ..remove(correctIndex)
          ..shuffle(_random);
        final optionIndices = [correctIndex, ...wrongIndices.take(3)]
          ..shuffle(_random);
        return _QuizQuestion(
          card: card,
          type: type,
          optionIndices: optionIndices,
        );
      case _QuestionType.textInput:
        return _QuizQuestion(card: card, type: type);
      case _QuestionType.trueFalse:
        final isCorrect = _random.nextBool();
        String shownDef;
        if (isCorrect) {
          shownDef = card.definition;
        } else {
          final others = _allCards.where((c) => c.id != card.id).toList();
          others.shuffle(_random);
          shownDef = others.first.definition;
        }
        return _QuizQuestion(
          card: card,
          type: type,
          shownDefinition: shownDef,
          isCorrectPair: isCorrect,
        );
    }
  }

  void _onMultipleChoiceSelect(int optionIndex) {
    if (_selectedOption != null) return;
    final question = _questions[_currentIndex];
    final correctIndex = _allCards.indexOf(question.card);
    final isCorrect = question.optionIndices[optionIndex] == correctIndex;

    setState(() {
      _selectedOption = optionIndex;
      if (isCorrect) {
        _isReinforcementRound ? _reinforcementScore++ : _score++;
      } else if (!_isReinforcementRound) {
        _wrongIndices.add(_currentIndex);
      }
    });

    _advanceAfterDelay(1200);
  }

  void _onTextInputAnswered(bool isCorrect) {
    setState(() {
      if (isCorrect) {
        _isReinforcementRound ? _reinforcementScore++ : _score++;
      } else if (!_isReinforcementRound) {
        _wrongIndices.add(_currentIndex);
      }
    });
    _advanceAfterDelay(2000);
  }

  void _onTrueFalseAnswered(bool isCorrect) {
    setState(() {
      if (isCorrect) {
        _isReinforcementRound ? _reinforcementScore++ : _score++;
      } else if (!_isReinforcementRound) {
        _wrongIndices.add(_currentIndex);
      }
    });
    _advanceAfterDelay(1200);
  }

  void _advanceAfterDelay(int ms) {
    Future.delayed(Duration(milliseconds: ms), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedOption = null;
        });
      } else if (!_isReinforcementRound && _wrongIndices.isNotEmpty) {
        _startReinforcementRound();
      } else {
        _navigateToSummary();
      }
    });
  }

  void _startReinforcementRound() {
    final wrongCards = _wrongIndices.map((i) => _questions[i].card).toList();
    setState(() {
      _isReinforcementRound = true;
      _reinforcementScore = 0;
      _questions = wrongCards
          .map((c) => _buildQuestion(c, _QuestionType.multipleChoice))
          .toList();
      _currentIndex = 0;
      _selectedOption = null;
    });
  }

  void _navigateToSummary() {
    final mainTotal = _isReinforcementRound
        ? _wrongIndices.length
        : _questions.length;
    final wrongCount = mainTotal - _score;
    context.pushReplacement(
      '/review/summary',
      extra: {
        'totalReviewed': mainTotal,
        'againCount': wrongCount,
        'hardCount': 0,
        'goodCount': _score,
        'easyCount': 0,
        'isRevengeMode': true,
        'revengeCardCount': widget.cardIds.length,
      },
    );
  }

  void _goHomeSmooth() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
      return;
    }
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!_initialized) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: Text(l10n.revengeStartQuiz),
        ),
        body: Center(child: Text(l10n.revengeNeedMoreCards)),
      );
    }

    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text('${_currentIndex + 1} / ${_questions.length}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                l10n.scoreLabel(
                  _isReinforcementRound ? _reinforcementScore : _score,
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: _goHomeSmooth,
            tooltip: l10n.home,
          ),
        ],
      ),
      body: Column(
        children: [
          RoundedProgressBar(value: progress),
          if (_isReinforcementRound)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: AppTheme.cyan.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: AppTheme.cyan,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.reinforcementRound} \u2014 ${l10n.reinforcementDesc}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.cyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Revenge mode banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: AppTheme.purple.withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(
                  Icons.replay_rounded,
                  size: 16,
                  color: AppTheme.purple,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.revengeMode,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: _buildQuestionBody(question, l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionBody(_QuizQuestion question, AppLocalizations l10n) {
    switch (question.type) {
      case _QuestionType.multipleChoice:
        return _buildMultipleChoice(question, l10n);
      case _QuestionType.textInput:
        return _buildTextInput(question, l10n);
      case _QuestionType.trueFalse:
        return _buildTrueFalse(question);
    }
  }

  Widget _buildMultipleChoice(_QuizQuestion question, AppLocalizations l10n) {
    final correctIndex = _allCards.indexOf(question.card);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.whatIsDefinitionOf,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          question.card.term,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 32),
        ...List.generate(4, (i) {
          final optionCardIndex = question.optionIndices[i];
          final optionCard = _allCards[optionCardIndex];

          QuizOptionState state = QuizOptionState.normal;
          if (_selectedOption != null) {
            if (optionCardIndex == correctIndex) {
              state = QuizOptionState.correct;
            } else if (i == _selectedOption) {
              state = QuizOptionState.incorrect;
            }
          }

          return QuizOptionTile(
            text: optionCard.definition,
            state: state,
            onTap: _selectedOption == null
                ? () => _onMultipleChoiceSelect(i)
                : null,
          );
        }),
      ],
    );
  }

  Widget _buildTextInput(_QuizQuestion question, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.whatIsDefinitionOf,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 16),
        TextInputQuestion(
          key: ValueKey('revenge_text_${question.card.id}_$_currentIndex'),
          definition: question.card.definition,
          correctAnswer: question.card.term,
          onAnswered: _onTextInputAnswered,
        ),
      ],
    );
  }

  Widget _buildTrueFalse(_QuizQuestion question) {
    return TrueFalseQuestion(
      key: ValueKey('revenge_tf_${question.card.id}_$_currentIndex'),
      term: question.card.term,
      shownDefinition: question.shownDefinition,
      isCorrectPair: question.isCorrectPair,
      onAnswered: _onTrueFalseAnswered,
    );
  }
}

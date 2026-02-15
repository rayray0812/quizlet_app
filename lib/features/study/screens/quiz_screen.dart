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
import 'package:recall_app/features/study/widgets/study_result_widgets.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';

enum QuizQuestionType { multipleChoice, textInput, trueFalse }

class QuizQuestion {
  final Flashcard card;
  final QuizQuestionType type;

  /// For multiple choice: 4 indices into [_allCards].
  final List<int> optionIndices;

  /// For true/false: the definition shown (may be wrong).
  final String shownDefinition;

  /// For true/false: whether [shownDefinition] is the correct definition.
  final bool isCorrectPair;

  const QuizQuestion({
    required this.card,
    required this.type,
    this.optionIndices = const [],
    this.shownDefinition = '',
    this.isCorrectPair = true,
  });
}

class QuizScreen extends ConsumerStatefulWidget {
  final String setId;
  final int? questionCount;

  const QuizScreen({super.key, required this.setId, this.questionCount});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final _random = Random();
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedOption;
  late List<Flashcard> _allCards;
  late List<QuizQuestion> _questions;
  final List<int> _wrongIndices = [];
  bool _isReinforcementRound = false;
  int _reinforcementScore = 0;

  @override
  void initState() {
    super.initState();
    _initQuiz();
  }

  void _initQuiz() {
    final studySet =
        ref.read(studySetsProvider.notifier).getById(widget.setId);
    if (studySet == null || studySet.cards.length < 4) return;

    _allCards = studySet.cards;
    final shuffled = List.of(_allCards)..shuffle(_random);
    final limit = widget.questionCount ?? shuffled.length;
    final selected = shuffled.take(min(limit, shuffled.length)).toList();

    _questions = _generateMixedQuestions(selected);
    _currentIndex = 0;
    _score = 0;
    _selectedOption = null;
    _wrongIndices.clear();
    _isReinforcementRound = false;
    _reinforcementScore = 0;
  }

  List<QuizQuestion> _generateMixedQuestions(List<Flashcard> cards) {
    final questions = <QuizQuestion>[];
    for (var i = 0; i < cards.length; i++) {
      final roll = _random.nextDouble();
      QuizQuestionType type;
      if (roll < 0.6) {
        type = QuizQuestionType.multipleChoice;
      } else if (roll < 0.8) {
        type = QuizQuestionType.textInput;
      } else {
        type = QuizQuestionType.trueFalse;
      }
      questions.add(_buildQuestion(cards[i], type));
    }
    return questions;
  }

  QuizQuestion _buildQuestion(Flashcard card, QuizQuestionType type) {
    switch (type) {
      case QuizQuestionType.multipleChoice:
        final correctIndex = _allCards.indexOf(card);
        final wrongIndices = List.generate(_allCards.length, (i) => i)
          ..remove(correctIndex)
          ..shuffle(_random);
        final optionIndices = [correctIndex, ...wrongIndices.take(3)]
          ..shuffle(_random);
        return QuizQuestion(
          card: card,
          type: type,
          optionIndices: optionIndices,
        );
      case QuizQuestionType.textInput:
        return QuizQuestion(card: card, type: type);
      case QuizQuestionType.trueFalse:
        final isCorrect = _random.nextBool();
        String shownDef;
        if (isCorrect) {
          shownDef = card.definition;
        } else {
          final others = _allCards.where((c) => c.id != card.id).toList();
          others.shuffle(_random);
          shownDef = others.first.definition;
        }
        return QuizQuestion(
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
        _showResults();
      }
    });
  }

  void _startReinforcementRound() {
    final wrongCards =
        _wrongIndices.map((i) => _questions[i].card).toList();
    setState(() {
      _isReinforcementRound = true;
      _reinforcementScore = 0;
      _questions = wrongCards
          .map((c) => _buildQuestion(c, QuizQuestionType.multipleChoice))
          .toList();
      _currentIndex = 0;
      _selectedOption = null;
    });
  }

  void _showResults() {
    final l10n = AppLocalizations.of(context);
    final mainTotal =
        _isReinforcementRound ? _wrongIndices.length : _questions.length;
    final mainScore = _score;
    final percent = (mainScore / mainTotal * 100).round();
    final accent = percent >= 80 ? AppTheme.green : AppTheme.orange;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StudyResultHeader(
              accentColor: accent,
              icon: percent >= 80
                  ? Icons.emoji_events_rounded
                  : Icons.auto_graph_rounded,
              title: l10n.quizComplete,
              primaryText: l10n.quizResult(mainScore, mainTotal),
              badgeText: l10n.percentCorrect(percent),
            ),
            if (_isReinforcementRound) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${l10n.reinforcementRound}: $_reinforcementScore / ${_questions.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.cyan,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            StudyResultDialogActions(
              leftLabel: l10n.tryAgain,
              rightLabel: l10n.done,
              onLeft: () {
                Navigator.pop(context);
                setState(() => _initQuiz());
              },
              onRight: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
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
    final studySet = ref
        .watch(studySetsProvider)
        .where((s) => s.id == widget.setId)
        .firstOrNull;

    final l10n = AppLocalizations.of(context);

    if (studySet == null || studySet.cards.length < 4) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.quiz)),
        body: Center(child: Text(l10n.needAtLeast4Cards)),
      );
    }

    if (_questions.isEmpty) return const SizedBox();

    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / ${_questions.length}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                l10n.scoreLabel(
                    _isReinforcementRound ? _reinforcementScore : _score),
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
                  const Icon(Icons.refresh_rounded,
                      size: 18, color: AppTheme.cyan),
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

  Widget _buildQuestionBody(QuizQuestion question, AppLocalizations l10n) {
    switch (question.type) {
      case QuizQuestionType.multipleChoice:
        return _buildMultipleChoice(question, l10n);
      case QuizQuestionType.textInput:
        return _buildTextInput(question, l10n);
      case QuizQuestionType.trueFalse:
        return _buildTrueFalse(question);
    }
  }

  Widget _buildMultipleChoice(QuizQuestion question, AppLocalizations l10n) {
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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

  Widget _buildTextInput(QuizQuestion question, AppLocalizations l10n) {
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
          key: ValueKey('text_${question.card.id}_$_currentIndex'),
          definition: question.card.definition,
          correctAnswer: question.card.term,
          onAnswered: _onTextInputAnswered,
        ),
      ],
    );
  }

  Widget _buildTrueFalse(QuizQuestion question) {
    return TrueFalseQuestion(
      key: ValueKey('tf_${question.card.id}_$_currentIndex'),
      term: question.card.term,
      shownDefinition: question.shownDefinition,
      isCorrectPair: question.isCorrectPair,
      onAnswered: _onTrueFalseAnswered,
    );
  }
}

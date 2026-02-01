import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizlet_app/models/flashcard.dart';
import 'package:quizlet_app/providers/study_set_provider.dart';
import 'package:quizlet_app/features/study/widgets/quiz_option_tile.dart';
import 'package:quizlet_app/core/l10n/app_localizations.dart';

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
  late List<Flashcard> _shuffledCards;
  late List<Flashcard> _allCards;
  late List<List<int>> _options; // indices into _allCards for each question

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
    _shuffledCards = List.of(_allCards)..shuffle(_random);

    // Limit to questionCount if specified
    final limit = widget.questionCount ?? _shuffledCards.length;
    _shuffledCards = _shuffledCards.take(min(limit, _shuffledCards.length)).toList();

    _options = [];

    for (var i = 0; i < _shuffledCards.length; i++) {
      final correctIndex = _allCards.indexOf(_shuffledCards[i]);
      final wrongIndices = List.generate(_allCards.length, (i) => i)
        ..remove(correctIndex)
        ..shuffle(_random);

      final optionIndices = [
        correctIndex,
        ...wrongIndices.take(3),
      ]..shuffle(_random);

      _options.add(optionIndices);
    }

    _currentIndex = 0;
    _score = 0;
    _selectedOption = null;
  }

  void _selectOption(int optionIndex) {
    if (_selectedOption != null) return;

    final correctIndex = _allCards.indexOf(_shuffledCards[_currentIndex]);

    setState(() {
      _selectedOption = optionIndex;
      if (_options[_currentIndex][optionIndex] == correctIndex) {
        _score++;
      }
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_currentIndex < _shuffledCards.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedOption = null;
        });
      } else {
        _showResults();
      }
    });
  }

  void _showResults() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.quizComplete),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.quizResult(_score, _shuffledCards.length),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.percentCorrect(
                  (_score / _shuffledCards.length * 100).round()),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _initQuiz());
            },
            child: Text(l10n.tryAgain),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studySet =
        ref.watch(studySetsProvider.notifier).getById(widget.setId);

    final l10n = AppLocalizations.of(context);

    if (studySet == null || studySet.cards.length < 4) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.quiz)),
        body: Center(child: Text(l10n.needAtLeast4Cards)),
      );
    }

    if (_options.isEmpty) return const SizedBox();

    final currentCard = _shuffledCards[_currentIndex];
    final correctIndex = _allCards.indexOf(currentCard);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / ${_shuffledCards.length}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                l10n.scoreLabel(_score),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
            tooltip: l10n.home,
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _shuffledCards.length,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    l10n.whatIsDefinitionOf,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentCard.term,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 32),
                  ...List.generate(4, (i) {
                    final optionCardIndex = _options[_currentIndex][i];
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
                      onTap:
                          _selectedOption == null ? () => _selectOption(i) : null,
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

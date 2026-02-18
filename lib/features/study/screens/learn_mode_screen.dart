import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/app_back_button.dart';
import 'package:recall_app/features/study/utils/encouragement_lines.dart';
import 'package:recall_app/features/study/widgets/quiz_option_tile.dart';
import 'package:recall_app/features/study/widgets/rounded_progress_bar.dart';
import 'package:recall_app/features/study/widgets/study_result_widgets.dart';
import 'package:recall_app/features/study/widgets/text_input_question.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/providers/study_set_provider.dart';

enum _LearnQuestionType { multipleChoice, textInput }

class LearnModeScreen extends ConsumerStatefulWidget {
  final String setId;

  const LearnModeScreen({super.key, required this.setId});

  @override
  ConsumerState<LearnModeScreen> createState() => _LearnModeScreenState();
}

class _LearnModeScreenState extends ConsumerState<LearnModeScreen> {
  static const int _masteryStage = 2;

  final Random _random = Random();
  final Map<String, int> _stageByCardId = <String, int>{};
  final List<String> _queue = <String>[];

  late List<Flashcard> _allCards;
  late Map<String, Flashcard> _cardById;
  String? _currentCardId;
  int _attempts = 0;
  int _correct = 0;
  int? _selectedOption;
  String? _choiceSeedCardId;
  List<Flashcard> _choiceSeedOptions = <Flashcard>[];
  late DateTime _startedAt;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _initSession();
  }

  void _initSession() {
    final studySet = ref.read(studySetsProvider.notifier).getById(widget.setId);
    if (studySet == null || studySet.cards.isEmpty) return;

    _allCards = List<Flashcard>.of(studySet.cards);
    _cardById = {for (final c in _allCards) c.id: c};
    _stageByCardId
      ..clear()
      ..addEntries(_allCards.map((c) => MapEntry(c.id, 0)));
    _queue
      ..clear()
      ..addAll(_allCards.map((c) => c.id));
    _queue.shuffle(_random);

    _attempts = 0;
    _correct = 0;
    _selectedOption = null;
    _choiceSeedCardId = null;
    _choiceSeedOptions = <Flashcard>[];
    _startedAt = DateTime.now();
    _currentCardId = _queue.isNotEmpty ? _queue.first : null;
    _isInitialized = true;
    if (mounted) setState(() {});
  }

  _LearnQuestionType _questionTypeFor(String cardId) {
    if (_allCards.length < 4) return _LearnQuestionType.textInput;
    final stage = _stageByCardId[cardId] ?? 0;
    return stage <= 0 ? _LearnQuestionType.multipleChoice : _LearnQuestionType.textInput;
  }

  List<Flashcard> _choicesFor(Flashcard correctCard) {
    final others = _allCards.where((c) => c.id != correctCard.id).toList()..shuffle(_random);
    final selected = <Flashcard>[correctCard, ...others.take(3)]..shuffle(_random);
    return selected;
  }

  Future<void> _advance(bool isCorrect) async {
    if (_currentCardId == null) return;
    final cardId = _currentCardId!;
    _attempts++;
    if (isCorrect) _correct++;

    final currentStage = _stageByCardId[cardId] ?? 0;
    final nextStage = isCorrect ? currentStage + 1 : 0;
    _stageByCardId[cardId] = nextStage.clamp(0, _masteryStage);

    if (_queue.isNotEmpty && _queue.first == cardId) {
      _queue.removeAt(0);
    } else {
      _queue.remove(cardId);
    }

    if ((_stageByCardId[cardId] ?? 0) < _masteryStage) {
      _queue.add(cardId);
    }

    if (_queue.isEmpty) {
      _showResult();
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    setState(() {
      _selectedOption = null;
      _currentCardId = _queue.first;
      _choiceSeedCardId = null;
      _choiceSeedOptions = <Flashcard>[];
    });
  }

  void _showResult() {
    final l10n = AppLocalizations.of(context);
    final accuracy = _attempts == 0 ? 0 : (_correct / _attempts * 100).round().clamp(0, 100);
    final elapsedSeconds = DateTime.now().difference(_startedAt).inSeconds;
    final accent = accuracy >= 80 ? AppTheme.green : AppTheme.orange;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StudyResultHeader(
              accentColor: accent,
              icon: accuracy >= 80 ? Icons.school_rounded : Icons.auto_graph_rounded,
              title: 'Learn 完成',
              primaryText: '$accuracy%',
              badgeText: '${_allCards.length} 張已掌握',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                StudyResultChip(
                  label: '正確',
                  value: '$_correct/$_attempts',
                  color: AppTheme.green,
                ),
                StudyResultChip(
                  label: '時間',
                  value: '${elapsedSeconds}s',
                  color: AppTheme.indigo,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              EncouragementLines.pick(accuracy),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            StudyResultDialogActions(
              leftLabel: l10n.tryAgain,
              rightLabel: l10n.done,
              onLeft: () {
                Navigator.pop(context);
                _initSession();
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
    final studySet = ref.watch(studySetsProvider).where((s) => s.id == widget.setId).firstOrNull;
    final l10n = AppLocalizations.of(context);

    if (studySet == null || studySet.cards.length < 2) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Learn'),
        ),
        body: Center(child: Text(l10n.needAtLeast2Cards)),
      );
    }

    if (!_isInitialized || _currentCardId == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Learn'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentCard = _cardById[_currentCardId]!;
    final type = _questionTypeFor(currentCard.id);
    final masteredCount = _stageByCardId.values.where((v) => v >= _masteryStage).length;
    final progress = _allCards.isEmpty ? 0.0 : masteredCount / _allCards.length;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Learn'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                '$masteredCount / ${_allCards.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.green,
                      fontWeight: FontWeight.w700,
                    ),
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                decoration: AppTheme.softCardDecoration(
                  fillColor: Colors.white,
                  borderRadius: 16,
                  borderColor: AppTheme.indigo.withValues(alpha: 0.24),
                ),
                child: type == _LearnQuestionType.multipleChoice
                    ? _buildMultipleChoice(currentCard)
                    : _buildTextInput(currentCard),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleChoice(Flashcard card) {
    final l10n = AppLocalizations.of(context);
    if (_choiceSeedCardId != card.id || _choiceSeedOptions.isEmpty) {
      _choiceSeedCardId = card.id;
      _choiceSeedOptions = _choicesFor(card);
    }
    final options = _choiceSeedOptions;
    final correctIndex = options.indexWhere((c) => c.id == card.id);

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
          card.term,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 28),
        ...List.generate(options.length, (i) {
          QuizOptionState state = QuizOptionState.normal;
          if (_selectedOption != null) {
            if (i == correctIndex) {
              state = QuizOptionState.correct;
            } else if (i == _selectedOption) {
              state = QuizOptionState.incorrect;
            }
          }
          return QuizOptionTile(
            text: options[i].definition,
            state: state,
            onTap: _selectedOption == null
                ? () async {
                    final isCorrect = i == correctIndex;
                    setState(() => _selectedOption = i);
                    await Future<void>.delayed(const Duration(milliseconds: 700));
                    if (!mounted) return;
                    await _advance(isCorrect);
                  }
                : null,
          );
        }),
      ],
    );
  }

  Widget _buildTextInput(Flashcard card) {
    final l10n = AppLocalizations.of(context);
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
          key: ValueKey('learn_text_${card.id}_${_stageByCardId[card.id]}'),
          definition: card.term,
          correctAnswer: card.definition,
          onAnswered: (isCorrect) {
            Future<void>.delayed(const Duration(milliseconds: 900), () {
              if (!mounted) return;
              _advance(isCorrect);
            });
          },
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/features/study/widgets/swipe_card_stack.dart';
import 'package:recall_app/features/study/widgets/rounded_progress_bar.dart';
import 'package:recall_app/features/study/widgets/study_result_widgets.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  final String setId;

  const FlashcardScreen({super.key, required this.setId});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  late List<Flashcard> _currentCards;
  final List<Flashcard> _knownCards = [];
  final List<Flashcard> _unknownCards = [];
  int _swipedCount = 0;
  bool _roundDone = false;

  @override
  void initState() {
    super.initState();
    _startRound(null);
  }

  void _startRound(List<Flashcard>? cards) {
    final studySet = ref.read(studySetsProvider.notifier).getById(widget.setId);
    if (studySet == null) return;

    setState(() {
      _currentCards = List.of(cards ?? studySet.cards)..shuffle();
      _knownCards.clear();
      _unknownCards.clear();
      _swipedCount = 0;
      _roundDone = false;
    });
  }

  void _onSwiped(int index, bool remembered) {
    final card = _currentCards[index];
    setState(() {
      if (remembered) {
        _knownCards.add(card);
      } else {
        _unknownCards.add(card);
      }
      _swipedCount++;
      if (_swipedCount >= _currentCards.length) {
        _roundDone = true;
      }
    });
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

    if (studySet == null || studySet.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.flashcards)),
        body: Center(child: Text(l10n.noCardsAvailable)),
      );
    }

    final progress = _currentCards.isEmpty
        ? 0.0
        : _swipedCount / _currentCards.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('$_swipedCount / ${_currentCards.length}'),
        actions: [
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
          const SizedBox(height: 4),
          // Score row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.close_rounded,
                        color: AppTheme.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_unknownCards.length}',
                        style: const TextStyle(
                          color: AppTheme.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.swipeToSort,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_knownCards.length}',
                        style: const TextStyle(
                          color: AppTheme.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.check_rounded,
                        color: AppTheme.green,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Card stack or round-end summary
          Expanded(
            child: _roundDone ? _buildRoundEnd(context) : _buildCardStack(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack() {
    final swipeCards = _currentCards
        .map(
          (c) => SwipeCardData(
            term: c.term,
            definition: c.definition,
            imageUrl: c.imageUrl,
          ),
        )
        .toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SwipeCardStack(
        key: ValueKey(_currentCards.hashCode),
        cards: swipeCards,
        onSwiped: _onSwiped,
      ),
    );
  }

  Widget _buildRoundEnd(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allKnown = _unknownCards.isEmpty;
    final total = _knownCards.length + _unknownCards.length;
    final percent = total == 0 ? 0 : (_knownCards.length / total * 100).round();
    final accent = allKnown ? AppTheme.green : AppTheme.indigo;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StudyResultCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StudyResultHeader(
                accentColor: accent,
                icon: allKnown
                    ? Icons.celebration_rounded
                    : Icons.stacked_bar_chart_rounded,
                title: allKnown ? l10n.greatJob : l10n.roundComplete,
                primaryText: l10n.percentCorrect(percent),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StatBox(
                    label: l10n.know,
                    count: _knownCards.length,
                    color: AppTheme.green,
                  ),
                  _StatBox(
                    label: l10n.dontKnow,
                    count: _unknownCards.length,
                    color: AppTheme.red,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              if (_unknownCards.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _startRound(_unknownCards),
                    icon: const Icon(Icons.replay_rounded),
                    label: Text(l10n.reviewNUnknownCards(_unknownCards.length)),
                  ),
                ),
              if (_unknownCards.isNotEmpty) const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(l10n.done),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBox({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return StudyResultChip(
      label: label,
      value: '$count',
      color: color,
      minWidth: 130,
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizlet_app/models/flashcard.dart';
import 'package:quizlet_app/providers/study_set_provider.dart';
import 'package:quizlet_app/features/study/widgets/swipe_card_stack.dart';

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
    final studySet =
        ref.read(studySetsProvider.notifier).getById(widget.setId);
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

  @override
  Widget build(BuildContext context) {
    final studySet =
        ref.watch(studySetsProvider.notifier).getById(widget.setId);

    if (studySet == null || studySet.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flashcards')),
        body: const Center(child: Text('No cards available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$_swipedCount / ${_currentCards.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
            tooltip: 'Home',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: _currentCards.isEmpty
                ? 0
                : _swipedCount / _currentCards.length,
          ),
          // Score row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.close, color: Colors.red, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${_unknownCards.length}',
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  'Swipe to sort',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Row(
                  children: [
                    Text(
                      '${_knownCards.length}',
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.check, color: Colors.green, size: 20),
                  ],
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
        .map((c) => SwipeCardData(term: c.term, definition: c.definition))
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
    final allKnown = _unknownCards.isEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              allKnown ? Icons.celebration : Icons.bar_chart,
              size: 64,
              color: allKnown
                  ? Colors.amber
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              allKnown ? 'Great job!' : 'Round Complete',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatBox(
                  label: 'Know',
                  count: _knownCards.length,
                  color: Colors.green,
                ),
                const SizedBox(width: 24),
                _StatBox(
                  label: "Don't know",
                  count: _unknownCards.length,
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_unknownCards.isNotEmpty)
              FilledButton.icon(
                onPressed: () => _startRound(_unknownCards),
                icon: const Icon(Icons.replay),
                label: Text(
                    'Review ${_unknownCards.length} unknown cards'),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
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
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

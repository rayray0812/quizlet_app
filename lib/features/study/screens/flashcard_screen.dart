import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizlet_app/providers/study_set_provider.dart';
import 'package:quizlet_app/features/study/widgets/flip_card.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  final String setId;

  const FlashcardScreen({super.key, required this.setId});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

    final cards = studySet.cards;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / ${cards.length}'),
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_currentIndex + 1) / cards.length,
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: cards.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final card = cards[index];
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FlipCardWidget(
                        frontText: card.term,
                        backText: card.definition,
                      ),
                      const SizedBox(height: 24),
                      // Difficulty rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _DifficultyButton(
                            label: 'Hard',
                            color: Colors.red.shade300,
                            onTap: () => _rateDifficulty(index, 2),
                          ),
                          const SizedBox(width: 12),
                          _DifficultyButton(
                            label: 'Medium',
                            color: Colors.orange.shade300,
                            onTap: () => _rateDifficulty(index, 1),
                          ),
                          const SizedBox(width: 12),
                          _DifficultyButton(
                            label: 'Easy',
                            color: Colors.green.shade300,
                            onTap: () => _rateDifficulty(index, 0),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filled(
                  onPressed: _currentIndex > 0
                      ? () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                      : null,
                  icon: const Icon(Icons.arrow_back),
                ),
                Text(
                  'Swipe or tap arrows',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                IconButton.filled(
                  onPressed: _currentIndex < cards.length - 1
                      ? () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _rateDifficulty(int cardIndex, int difficulty) {
    final studySet =
        ref.read(studySetsProvider.notifier).getById(widget.setId);
    if (studySet == null) return;

    final updatedCards = List.of(studySet.cards);
    updatedCards[cardIndex] =
        updatedCards[cardIndex].copyWith(difficultyLevel: difficulty);

    ref
        .read(studySetsProvider.notifier)
        .update(studySet.copyWith(cards: updatedCards));
  }
}

class _DifficultyButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

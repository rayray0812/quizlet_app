import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizlet_app/models/card_progress.dart';
import 'package:quizlet_app/models/flashcard.dart';
import 'package:quizlet_app/providers/study_set_provider.dart';
import 'package:quizlet_app/providers/fsrs_provider.dart';
import 'package:quizlet_app/features/study/widgets/rating_buttons.dart';
import 'package:quizlet_app/core/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';

/// SRS review screen: show card front → tap to flip → rate Again/Hard/Good/Easy.
/// Can work with a single set (setId) or across all sets (setId == null, cross-set review).
class SrsReviewScreen extends ConsumerStatefulWidget {
  final String? setId;

  const SrsReviewScreen({super.key, this.setId});

  @override
  ConsumerState<SrsReviewScreen> createState() => _SrsReviewScreenState();
}

class _SrsReviewScreenState extends ConsumerState<SrsReviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showFront = true;
  bool _isFlipped = false;

  List<_ReviewItem> _queue = [];
  int _currentIndex = 0;
  int _againCount = 0;
  int _hardCount = 0;
  int _goodCount = 0;
  int _easyCount = 0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _flipAnimation.addListener(() {
      if (_flipAnimation.value >= 0.5 && _showFront) {
        setState(() => _showFront = false);
      } else if (_flipAnimation.value < 0.5 && !_showFront) {
        setState(() => _showFront = true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _buildQueue());
  }

  void _buildQueue() {
    final localStorage = ref.read(localStorageServiceProvider);
    final studySets = ref.read(studySetsProvider);

    final List<_ReviewItem> items = [];

    if (widget.setId != null) {
      // Single set review
      final studySet = localStorage.getStudySet(widget.setId!);
      if (studySet == null) return;
      for (final card in studySet.cards) {
        final progress = localStorage.getCardProgress(card.id);
        if (progress != null) {
          final isDue = progress.due == null ||
              progress.due!.isBefore(DateTime.now().toUtc());
          if (isDue) {
            items.add(_ReviewItem(card: card, progress: progress));
          }
        }
      }
    } else {
      // Cross-set review: all due cards
      final dueProgress = localStorage.getDueCardProgress();
      for (final progress in dueProgress) {
        // Find the card content
        Flashcard? card;
        for (final set in studySets) {
          for (final c in set.cards) {
            if (c.id == progress.cardId) {
              card = c;
              break;
            }
          }
          if (card != null) break;
        }
        if (card != null) {
          items.add(_ReviewItem(card: card, progress: progress));
        }
      }
    }

    items.shuffle();
    setState(() => _queue = items);
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flip() {
    if (_flipController.isAnimating) return;
    setState(() => _isFlipped = true);
    _flipController.forward();
  }

  void _onRate(int rating) {
    final item = _queue[_currentIndex];
    final fsrsService = ref.read(fsrsServiceProvider);
    final localStorage = ref.read(localStorageServiceProvider);

    // Perform review
    final result = fsrsService.reviewCard(item.progress, rating);

    // Save updated progress and log
    localStorage.saveCardProgress(result.progress);
    localStorage.saveReviewLog(result.log);

    // Track counts
    switch (rating) {
      case 1:
        _againCount++;
        break;
      case 2:
        _hardCount++;
        break;
      case 3:
        _goodCount++;
        break;
      case 4:
        _easyCount++;
        break;
    }

    // Move to next card or finish
    if (_currentIndex + 1 >= _queue.length) {
      // Done — navigate to summary
      final total = _againCount + _hardCount + _goodCount + _easyCount;
      context.go('/review/summary', extra: {
        'totalReviewed': total,
        'againCount': _againCount,
        'hardCount': _hardCount,
        'goodCount': _goodCount,
        'easyCount': _easyCount,
      });
    } else {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
        _showFront = true;
      });
      _flipController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_queue.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.srsReview)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
              const SizedBox(height: 16),
              Text(l10n.noDueCards,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.pop(),
                child: Text(l10n.done),
              ),
            ],
          ),
        ),
      );
    }

    final item = _queue[_currentIndex];
    final fsrsService = ref.read(fsrsServiceProvider);
    final intervals = fsrsService.getSchedulingPreview(item.progress);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / ${_queue.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/'),
            tooltip: l10n.home,
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: _queue.isEmpty ? 0 : _currentIndex / _queue.length,
          ),
          // Card
          Expanded(
            child: GestureDetector(
              onTap: _isFlipped ? null : _flip,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    final angle = _flipAnimation.value * pi;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: _showFront
                          ? _buildCardSide(
                              text: item.card.term,
                              label: l10n.tapToFlip,
                              bgColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              textColor: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              imageUrl: item.card.imageUrl,
                            )
                          : Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(pi),
                              child: _buildCardSide(
                                text: item.card.definition,
                                label: l10n.definitionLabel,
                                bgColor: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                textColor: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                              ),
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Rating buttons (only visible after flip)
          if (_isFlipped)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: RatingButtons(
                intervals: intervals,
                onRating: _onRate,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text(
                l10n.tapToFlip,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardSide({
    required String text,
    required String label,
    required Color bgColor,
    required Color textColor,
    String imageUrl = '',
  }) {
    final hasImage = imageUrl.isNotEmpty;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight * 0.5;

    return Container(
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: screenHeight * 0.18,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewItem {
  final Flashcard card;
  final CardProgress progress;

  _ReviewItem({required this.card, required this.progress});
}

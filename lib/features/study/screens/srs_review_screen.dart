import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizlet_app/models/card_progress.dart';
import 'package:quizlet_app/models/flashcard.dart';
import 'package:quizlet_app/providers/study_set_provider.dart';
import 'package:quizlet_app/providers/fsrs_provider.dart';
import 'package:quizlet_app/features/study/widgets/rating_buttons.dart';
import 'package:quizlet_app/features/study/widgets/rounded_progress_bar.dart';
import 'package:quizlet_app/core/l10n/app_localizations.dart';
import 'package:quizlet_app/core/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';

/// SRS review screen: show card front -> tap to flip -> rate Again/Hard/Good/Easy.
class SrsReviewScreen extends ConsumerStatefulWidget {
  final String? setId;
  final List<String>? filterTags;

  const SrsReviewScreen({super.key, this.setId, this.filterTags});

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
    final now = DateTime.now().toUtc();

    final List<_ReviewItem> items = [];

    if (widget.setId != null) {
      final studySet = localStorage.getStudySet(widget.setId!);
      if (studySet == null) return;
      for (final card in studySet.cards) {
        final progress = localStorage.getCardProgress(card.id);
        if (progress != null) {
          final isDue = progress.due == null || !progress.due!.isAfter(now);
          if (isDue) {
            items.add(_ReviewItem(card: card, progress: progress));
          }
        }
      }
    } else {
      final dueProgress = localStorage.getDueCardProgress();
      final cardsById = <String, Flashcard>{};
      for (final set in studySets) {
        for (final card in set.cards) {
          cardsById[card.id] = card;
        }
      }

      final tags = widget.filterTags;

      for (final progress in dueProgress) {
        final card = cardsById[progress.cardId];
        if (card == null) continue;

        // If tags are specified (custom study), only include matching cards
        if (tags != null && tags.isNotEmpty) {
          if (!card.tags.any((t) => tags.contains(t))) continue;
        }

        items.add(_ReviewItem(card: card, progress: progress));
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

  Future<void> _onRate(int rating) async {
    final item = _queue[_currentIndex];
    final fsrsService = ref.read(fsrsServiceProvider);
    final localStorage = ref.read(localStorageServiceProvider);

    final result = fsrsService.reviewCard(item.progress, rating);
    await localStorage.saveCardProgress(result.progress);
    await localStorage.saveReviewLog(result.log);
    ref.invalidate(allCardProgressProvider);
    if (!mounted) return;

    switch (rating) {
      case 1:
        _againCount++;
      case 2:
        _hardCount++;
      case 3:
        _goodCount++;
      case 4:
        _easyCount++;
    }

    if (_currentIndex + 1 >= _queue.length) {
      final total = _againCount + _hardCount + _goodCount + _easyCount;
      context.go(
        '/review/summary',
        extra: {
          'totalReviewed': total,
          'againCount': _againCount,
          'hardCount': _hardCount,
          'goodCount': _goodCount,
          'easyCount': _easyCount,
        },
      );
    } else {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
        _showFront = true;
      });
      _flipController.reset();
    }
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

    if (_queue.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.srsReview)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppTheme.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: AppTheme.green,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.noDueCards,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 28),
              ElevatedButton(
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
    final progress = _queue.isEmpty ? 0.0 : _currentIndex / _queue.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / ${_queue.length}'),
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
          Expanded(
            child: GestureDetector(
              onTap: _isFlipped ? null : _flip,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
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
                              bgColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              textColor: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              imageUrl: item.card.imageUrl,
                            )
                          : Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(pi),
                              child: _buildCardSide(
                                text: item.card.definition,
                                label: l10n.definitionLabel,
                                bgColor: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                textColor: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                              ),
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (_isFlipped)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
              child: RatingButtons(intervals: intervals, onRating: _onRate),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 36),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: screenHeight * 0.18,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.45),
              letterSpacing: 1.2,
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.3,
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

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:quizlet_app/core/l10n/app_localizations.dart';
import 'package:quizlet_app/features/study/widgets/flip_card.dart';

/// A single card in the swipe stack, with term/definition and swipe gesture.
class SwipeCardStack extends StatefulWidget {
  final List<SwipeCardData> cards;
  final void Function(int index, bool remembered) onSwiped;

  const SwipeCardStack({
    super.key,
    required this.cards,
    required this.onSwiped,
  });

  @override
  State<SwipeCardStack> createState() => SwipeCardStackState();
}

class SwipeCardStackState extends State<SwipeCardStack>
    with SingleTickerProviderStateMixin {
  int _topIndex = 0;
  Offset _dragOffset = Offset.zero;
  late AnimationController _animController;
  late Animation<Offset> _animOffset;
  bool _isAnimating = false;
  bool _isDragging = false;

  double get _screenWidth => MediaQuery.of(context).size.width;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get isDone => _topIndex >= widget.cards.length;

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    if (!_isDragging) {
      setState(() => _isDragging = true);
    }
    if (details.delta.distanceSquared < 0.3) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimating) return;
    final threshold = _screenWidth * 0.3;
    if (_dragOffset.dx.abs() > threshold) {
      final remembered = _dragOffset.dx > 0;
      _animateOut(remembered);
    } else {
      _animateBack();
    }
  }

  void _animateOut(bool remembered) {
    _isAnimating = true;
    final currentIndex = _topIndex;
    _animOffset = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(
        remembered ? _screenWidth * 1.5 : -_screenWidth * 1.5,
        _dragOffset.dy,
      ),
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward(from: 0).then((_) {
      widget.onSwiped(currentIndex, remembered);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _topIndex++;
            _dragOffset = Offset.zero;
            _isAnimating = false;
            _isDragging = false;
          });
        }
      });
    });
  }

  void _animateBack() {
    _isAnimating = true;
    _animOffset = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward(from: 0).then((_) {
      setState(() {
        _dragOffset = Offset.zero;
        _isAnimating = false;
        _isDragging = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isDone) return const SizedBox();

    final stackSize = min(3, widget.cards.length - _topIndex);
    final l10n = AppLocalizations.of(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        for (var i = stackSize - 1; i >= 1; i--) _buildBackCard(i),
        _buildTopCard(l10n),
      ],
    );
  }

  Widget _buildBackCard(int offset) {
    final scale = 1.0 - offset * 0.05;
    final yOffset = offset * 12.0;
    final data = widget.cards[_topIndex + offset];

    return Transform.translate(
      offset: Offset(0, yOffset),
      child: Transform.scale(
        scale: scale,
        child: IgnorePointer(
          child: _CardPreview(
            term: data.term,
            indexLabel: '${_topIndex + offset + 1}',
          ),
        ),
      ),
    );
  }

  Widget _buildTopCard(AppLocalizations l10n) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: () {
        if (!_isAnimating && _dragOffset != Offset.zero) {
          _animateBack();
        }
      },
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          final offset = _isAnimating ? _animOffset.value : _dragOffset;
          final ratio = _screenWidth > 0 ? offset.dx / _screenWidth : 0.0;
          final rotation = ratio * 0.25;
          final overlayOpacity = (ratio.abs() * 0.5)
              .clamp(0.0, 0.36)
              .toDouble();
          final labelOpacity = (ratio.abs() * 2).clamp(0.0, 1.0).toDouble();
          final isRight = ratio > 0.05;
          final isLeft = ratio < -0.05;
          final useLiteCard = _isDragging || _isAnimating;
          final data = widget.cards[_topIndex];

          return RepaintBoundary(
            child: Transform.translate(
              offset: offset,
              child: Transform.rotate(
                angle: rotation,
                child: Stack(
                  children: [
                    useLiteCard
                        ? _CardPreview(
                            term: data.term,
                            indexLabel: '${_topIndex + 1}',
                            emphasize: true,
                          )
                        : _cardContent(_topIndex),
                    // Right swipe overlay (remembered)
                    if (isRight)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.green.withValues(
                              alpha: overlayOpacity,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            l10n.know.toUpperCase(),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(
                                alpha: labelOpacity,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Left swipe overlay (not remembered)
                    if (isLeft)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.red.withValues(alpha: overlayOpacity),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            l10n.dontKnow.toUpperCase(),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(
                                alpha: labelOpacity,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _cardContent(int index) {
    if (index >= widget.cards.length) return const SizedBox();
    final data = widget.cards[index];
    return SizedBox(
      width: double.infinity,
      child: FlipCardWidget(
        key: ValueKey('swipe_card_$index'),
        frontText: data.term,
        backText: data.definition,
        imageUrl: data.imageUrl,
      ),
    );
  }
}

class _CardPreview extends StatelessWidget {
  final String term;
  final String indexLabel;
  final bool emphasize;

  const _CardPreview({
    required this.term,
    required this.indexLabel,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight * 0.55;
    return Container(
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: emphasize
            ? Border.all(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.14),
                width: 1.0,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            indexLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Text(
                term,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SwipeCardData {
  final String term;
  final String definition;
  final String imageUrl;

  const SwipeCardData({
    required this.term,
    required this.definition,
    this.imageUrl = '',
  });
}

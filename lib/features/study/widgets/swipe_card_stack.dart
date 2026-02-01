import 'dart:math';
import 'package:flutter/material.dart';
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

  double get _screenWidth =>
      MediaQuery.of(context).size.width;

  double get _dragRatio =>
      _screenWidth > 0 ? _dragOffset.dx / _screenWidth : 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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
    final targetX = remembered ? _screenWidth * 1.5 : -_screenWidth * 1.5;
    _animOffset =
        Tween<Offset>(begin: _dragOffset, end: Offset(targetX, _dragOffset.dy))
            .animate(CurvedAnimation(
                parent: _animController, curve: Curves.easeOut));
    _animController.forward(from: 0).then((_) {
      widget.onSwiped(_topIndex, remembered);
      setState(() {
        _topIndex++;
        _dragOffset = Offset.zero;
        _isAnimating = false;
      });
    });
    _animController.addListener(_animListener);
  }

  void _animateBack() {
    _isAnimating = true;
    _animOffset =
        Tween<Offset>(begin: _dragOffset, end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _animController, curve: Curves.easeOut));
    _animController.forward(from: 0).then((_) {
      setState(() {
        _dragOffset = Offset.zero;
        _isAnimating = false;
      });
    });
    _animController.addListener(_animListener);
  }

  void _animListener() {
    setState(() {
      _dragOffset = _animOffset.value;
    });
    if (_animController.isCompleted) {
      _animController.removeListener(_animListener);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isDone) return const SizedBox();

    final stackSize = min(3, widget.cards.length - _topIndex);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background cards (rendered bottom to top)
        for (var i = stackSize - 1; i >= 1; i--)
          _buildBackCard(i),
        // Top (draggable) card
        _buildTopCard(),
      ],
    );
  }

  Widget _buildBackCard(int offset) {
    final scale = 1.0 - offset * 0.05;
    final yOffset = offset * 12.0;
    return Transform.translate(
      offset: Offset(0, yOffset),
      child: Transform.scale(
        scale: scale,
        child: IgnorePointer(
          child: Opacity(
            opacity: 0.7,
            child: _cardContent(_topIndex + offset),
          ),
        ),
      ),
    );
  }

  Widget _buildTopCard() {
    final rotation = _dragRatio * 0.3; // max ~17 degrees

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: rotation,
          child: Stack(
            children: [
              _cardContent(_topIndex),
              // Right swipe overlay (remembered)
              if (_dragRatio > 0.05)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.green.withValues(alpha: (_dragRatio.abs() * 0.5).clamp(0, 0.4)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'KNOW',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: (_dragRatio.abs() * 2).clamp(0, 1)),
                      ),
                    ),
                  ),
                ),
              // Left swipe overlay (not remembered)
              if (_dragRatio < -0.05)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.red.withValues(alpha: (_dragRatio.abs() * 0.5).clamp(0, 0.4)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "DON'T KNOW",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: (_dragRatio.abs() * 2).clamp(0, 1)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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
      ),
    );
  }
}

class SwipeCardData {
  final String term;
  final String definition;

  const SwipeCardData({required this.term, required this.definition});
}

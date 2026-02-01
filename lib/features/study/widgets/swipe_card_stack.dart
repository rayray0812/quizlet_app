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

  double get _screenWidth => MediaQuery.of(context).size.width;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      // 縮短動畫時間讓滑動感覺更流暢
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
    // 先記錄當前索引，避免動畫完成後索引已變化
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
      // 使用 WidgetsBinding 確保 UI 更新流暢
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _topIndex++;
            _dragOffset = Offset.zero;
            _isAnimating = false;
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
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isDone) return const SizedBox();

    final stackSize = min(3, widget.cards.length - _topIndex);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background cards (rendered bottom to top)
        for (var i = stackSize - 1; i >= 1; i--) _buildBackCard(i),
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
          // 移除 Opacity 讓卡片完全不透明
          child: _cardContent(_topIndex + offset),
        ),
      ),
    );
  }

  Widget _buildTopCard() {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          final offset = _isAnimating ? _animOffset.value : _dragOffset;
          final ratio = _screenWidth > 0 ? offset.dx / _screenWidth : 0.0;
          final rotation = ratio * 0.3;

          return Transform.translate(
            offset: offset,
            child: Transform.rotate(
              angle: rotation,
              child: Stack(
                children: [
                  child!,
                  // Right swipe overlay (remembered)
                  if (ratio > 0.05)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.green.withValues(
                            alpha: (ratio.abs() * 0.5).clamp(0, 0.4),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          AppLocalizations.of(context).know.toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(
                              alpha: (ratio.abs() * 2).clamp(0, 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Left swipe overlay (not remembered)
                  if (ratio < -0.05)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.red.withValues(
                            alpha: (ratio.abs() * 0.5).clamp(0, 0.4),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          AppLocalizations.of(context).dontKnow.toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(
                              alpha: (ratio.abs() * 2).clamp(0, 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        child: _cardContent(_topIndex),
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

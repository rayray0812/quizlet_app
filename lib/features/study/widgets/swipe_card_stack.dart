import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/features/study/widgets/flip_card.dart';

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
    with TickerProviderStateMixin {
  int _topIndex = 0;
  Offset _dragOffset = Offset.zero;
  late AnimationController _animController;
  late Animation<Offset> _animOffset;
  late AnimationController _entryController;
  bool _isAnimating = false;
  bool _isDragging = false;
  bool _isTopCardFlipping = false;

  double get _screenWidth => MediaQuery.of(context).size.width;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 230),
    )..value = 1;
  }

  @override
  void dispose() {
    _animController.dispose();
    _entryController.dispose();
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
      // Apply light damping to reduce jitter and make drag feel smoother.
      _dragOffset = Offset(
        _dragOffset.dx + details.delta.dx * 0.92,
        _dragOffset.dy + details.delta.dy * 0.72,
      );
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
    _animController.duration = const Duration(milliseconds: 290);
    final currentIndex = _topIndex;
    _animOffset = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(
        remembered ? _screenWidth * 1.5 : -_screenWidth * 1.5,
        _dragOffset.dy,
      ),
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0).then((_) {
      widget.onSwiped(currentIndex, remembered);
      if (!mounted) return;
      _entryController.stop();
      _entryController.value = 0;
      setState(() {
        _topIndex++;
        _dragOffset = Offset.zero;
        _isAnimating = false;
        _isDragging = false;
        _isTopCardFlipping = false;
      });
      _entryController.forward();
    });
  }

  void _animateBack() {
    _isAnimating = true;
    _animController.duration = const Duration(milliseconds: 250);
    _animOffset = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0).then((_) {
      if (!mounted) return;
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
    final showBackCards = true;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (showBackCards)
          for (var i = stackSize - 1; i >= 1; i--) _buildBackCard(i),
        _buildTopCard(l10n),
      ],
    );
  }

  Widget _buildBackCard(int offset) {
    final data = widget.cards[_topIndex + offset];
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        // Only move back-card progression while the finger is actively dragging.
        final t = _isDragging
            ? (_dragOffset.dx.abs() / (_screenWidth * 0.45))
                .clamp(0.0, 1.0)
                .toDouble()
            : 0.0;

        final baseScale = 1.0 - offset * 0.04;
        final liftedScale = 1.0 - (offset - 1) * 0.04;
        final smoothT = (t * 0.35).clamp(0.0, 1.0);
        final scale = lerpDouble(baseScale, liftedScale, smoothT) ?? baseScale;

        // Keep vertical level stable to avoid the "drop" feeling.
        final yOffset = offset * 10.0;

        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Transform.scale(
            scale: scale,
            child: IgnorePointer(
              child: _CardPreview(
                term: data.term,
                hideText: _isTopCardFlipping,
              ),
            ),
          ),
        );
      },
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
        animation: Listenable.merge([_animController, _entryController]),
        builder: (context, _) {
          final offset = _isAnimating ? _animOffset.value : _dragOffset;
          final ratio = _screenWidth > 0 ? offset.dx / _screenWidth : 0.0;
          final rotation = (ratio * 0.13).clamp(-0.13, 0.13);
          final entryT = (!_isAnimating && !_isDragging)
              ? Curves.easeOutQuart.transform(_entryController.value)
              : 1.0;
          final entryScale = lerpDouble(0.985, 1.0, entryT) ?? 1.0;
          final entryYOffset = lerpDouble(8.0, 0.0, entryT) ?? 0.0;
          final entryOpacity = lerpDouble(0.92, 1.0, entryT) ?? 1.0;
          final overlayOpacity = (ratio.abs() * 0.5).clamp(0.0, 0.36).toDouble();
          final labelOpacity = (ratio.abs() * 2).clamp(0.0, 1.0).toDouble();
          final isRight = ratio > 0.05;
          final isLeft = ratio < -0.05;

          // During out-animation use a lightweight preview; while dragging keep flip state.
          final useLiteCard = _isAnimating;
          final data = widget.cards[_topIndex];

          return RepaintBoundary(
            child: Transform.translate(
              offset: Offset(offset.dx, offset.dy + entryYOffset),
              child: Opacity(
                opacity: entryOpacity,
                child: Transform.scale(
                  scale: entryScale,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Stack(
                      children: [
                        useLiteCard
                            ? _CardPreview(term: data.term, emphasize: true)
                            : _cardContent(_topIndex),
                        if (isRight)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: AppTheme.green.withValues(alpha: overlayOpacity),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                l10n.know.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                  color: Colors.white.withValues(alpha: labelOpacity),
                                ),
                              ),
                            ),
                          ),
                        if (isLeft)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: AppTheme.red.withValues(alpha: overlayOpacity),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                l10n.dontKnow.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                  color: Colors.white.withValues(alpha: labelOpacity),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
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
        onFlipStateChanged: (isFlipping) {
          if (!mounted || _isTopCardFlipping == isFlipping) return;
          setState(() => _isTopCardFlipping = isFlipping);
        },
      ),
    );
  }
}

class _CardPreview extends StatelessWidget {
  final String term;
  final bool emphasize;
  final bool hideText;

  const _CardPreview({
    required this.term,
    this.emphasize = false,
    this.hideText = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight * 0.55;
    return Container(
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF9F3E6), Color(0xFFEDECDC), Color(0xFFB9CCB2)],
          stops: [0.0, 0.74, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: emphasize
            ? Border.all(
                color: const Color(0xFFFFFAEF).withValues(alpha: 0.55),
                width: 0.6,
              )
            : Border.all(
                color: const Color(0xFFFFFAEF).withValues(alpha: 0.42),
                width: 0.55,
              ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22372A).withValues(alpha: 0.14),
            blurRadius: 13,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _PreviewPaperTexturePainter(
                  tone: const Color(0xFFFFF9EE),
                  shadowTone: const Color(0xFF4F6A58),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.transparent,
                      const Color(0xFF375647).withValues(alpha: 0.03),
                    ],
                    stops: const [0.0, 0.58, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      opacity: hideText ? 0 : 1,
                      child: Text(
                        term,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSerifTc(
                          textStyle: Theme.of(context).textTheme.headlineSmall,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A221A),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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

class _PreviewPaperTexturePainter extends CustomPainter {
  final Color tone;
  final Color shadowTone;

  const _PreviewPaperTexturePainter({
    required this.tone,
    required this.shadowTone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = tone.withValues(alpha: 0.095)
      ..strokeWidth = 0.75;
    final fiberPaint = Paint()
      ..color = shadowTone.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 26; i++) {
      final y = (size.height / 26) * i + ((i % 2) * 1.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 1.2), linePaint);
    }

    for (var i = 0; i < 120; i++) {
      final x = (i * 29 % 100) / 100 * size.width;
      final y = (i * 19 % 100) / 100 * size.height;
      final r = 0.4 + (i % 3) * 0.18;
      canvas.drawCircle(Offset(x, y), r, fiberPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewPaperTexturePainter oldDelegate) {
    return oldDelegate.tone != tone || oldDelegate.shadowTone != shadowTone;
  }
}

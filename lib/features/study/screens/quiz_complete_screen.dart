import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/features/study/utils/encouragement_lines.dart';

class QuizCompleteScreen extends StatefulWidget {
  final String setId;
  final int elapsedSeconds;
  final int score;
  final int total;
  final int accuracy;
  final int paceScore;
  final int reinforcementScore;
  final int reinforcementTotal;

  const QuizCompleteScreen({
    super.key,
    required this.setId,
    required this.elapsedSeconds,
    required this.score,
    required this.total,
    required this.accuracy,
    required this.paceScore,
    required this.reinforcementScore,
    required this.reinforcementTotal,
  });

  @override
  State<QuizCompleteScreen> createState() => _QuizCompleteScreenState();
}

class _QuizCompleteScreenState extends State<QuizCompleteScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF8F9876);
  static const Color _bgLight = Color(0xFFFDFBF7);
  static const Color _charcoal = Color(0xFF2D2D2A);
  static const double _panelWidth = 340;

  late final AnimationController _controller;
  bool _isExiting = false;
  late final String _encouragement;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _encouragement = EncouragementLines.pick(widget.accuracy);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  int _computeFinalScore() {
    final pace = widget.paceScore.clamp(0, 100);
    return ((widget.accuracy * 0.8) + (pace * 0.2)).round().clamp(
      0,
      100,
    );
  }

  String _computeGrade(int score) {
    if (score >= 95) return 'S';
    if (score >= 85) return 'A';
    if (score >= 70) return 'B';
    if (score >= 60) return 'C';
    return 'D';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accuracy = widget.accuracy.clamp(0, 100);
    final score = _computeFinalScore();
    final grade = _computeGrade(score);

    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = Curves.easeOutCubic.transform(_controller.value);
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _encouragement,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.notoSerifTc(
                              textStyle: const TextStyle(
                                fontSize: 32,
                                height: 1.0,
                                fontWeight: FontWeight.w800,
                                color: _charcoal,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.quizComplete,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _primary.withValues(alpha: 0.82),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _HeroMedal(progress: t),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: _panelWidth,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                18,
                                16,
                                16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFEDE9DF),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 22,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: _StatColumn(
                                            label: '作答時間',
                                            value: _formatTime(
                                              widget.elapsedSeconds,
                                            ),
                                            valueColor: _charcoal,
                                          ),
                                        ),
                                        const _StatLine(),
                                        Expanded(
                                          child: _StatColumn(
                                            label: '正確率',
                                            value: '$accuracy%',
                                            valueColor: _primary,
                                          ),
                                        ),
                                        const _StatLine(),
                                        Expanded(
                                          child: _StatColumn(
                                            label: '答對題數',
                                            value: '${widget.score}/${widget.total}',
                                            valueColor: _charcoal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (widget.reinforcementTotal > 0) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      '${l10n.reinforcementRound}: ${widget.reinforcementScore}/${widget.reinforcementTotal}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _primary.withValues(alpha: 0.8),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '評分',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black.withValues(
                                            alpha: 0.55,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '$grade  ($score)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: _primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: SizedBox(
                                      height: 8,
                                      child: Stack(
                                        children: [
                                          Container(
                                            color: const Color(0xFFEFF2E8),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: score / 100,
                                            child: Container(color: _primary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: _panelWidth,
                            child: FilledButton(
                              onPressed: () => _exitAndNavigate(
                                () => context.pushReplacement(
                                  '/study/${widget.setId}/quiz',
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                l10n.playAgain,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: _panelWidth,
                            child: OutlinedButton(
                              onPressed: () => _exitAndNavigate(
                                () => context.pushReplacement(
                                  '/study/${widget.setId}',
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _primary.withValues(alpha: 0.35),
                                  width: 1.8,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                l10n.done,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: _primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exitAndNavigate(VoidCallback navigate) async {
    if (_isExiting) return;
    setState(() => _isExiting = true);
    await _controller.reverse(from: 1);
    if (!mounted) return;
    navigate();
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.1,
            color: Colors.black.withValues(alpha: 0.4),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSerifTc(
            textStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: valueColor,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: const Color(0xFFE9E5DB),
    );
  }
}

class _HeroMedal extends StatelessWidget {
  final double progress;

  const _HeroMedal({required this.progress});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF8F9876);
    final burst = (1 - progress).clamp(0.0, 1.0);
    final scale = 0.9 + progress * 0.1 + sin(progress * pi * 1.5) * 0.04;
    return SizedBox(
      width: 180,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 112 + (24 * burst),
            height: 112 + (24 * burst),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12 * (1 - burst)),
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            top: 8,
            right: 22,
            child: Icon(
              Icons.celebration_rounded,
              color: primary.withValues(alpha: 0.85),
              size: 24,
            ),
          ),
          Positioned(
            bottom: 18,
            left: 24,
            child: Icon(
              Icons.star_rounded,
              color: primary.withValues(alpha: 0.82),
              size: 20,
            ),
          ),
          Transform.scale(
            scale: scale,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: primary.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: primary,
                size: 52,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:recall_app/core/theme/app_theme.dart';

enum QuizOptionState { normal, correct, incorrect }

class QuizOptionTile extends StatefulWidget {
  final String text;
  final QuizOptionState state;
  final VoidCallback? onTap;

  const QuizOptionTile({
    super.key,
    required this.text,
    required this.state,
    this.onTap,
  });

  @override
  State<QuizOptionTile> createState() => _QuizOptionTileState();
}

class _QuizOptionTileState extends State<QuizOptionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    Widget? trailing;

    switch (widget.state) {
      case QuizOptionState.correct:
        bgColor = AppTheme.green.withValues(alpha: 0.08);
        borderColor = AppTheme.green;
        textColor = AppTheme.green;
        trailing = const Icon(Icons.check_circle_rounded, color: AppTheme.green);
      case QuizOptionState.incorrect:
        bgColor = AppTheme.red.withValues(alpha: 0.08);
        borderColor = AppTheme.red;
        textColor = AppTheme.red;
        trailing = const Icon(Icons.cancel_rounded, color: AppTheme.red);
      case QuizOptionState.normal:
        bgColor = Theme.of(context).cardColor;
        borderColor = Theme.of(context).colorScheme.outlineVariant;
        textColor = Theme.of(context).colorScheme.onSurface;
        trailing = null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
        onTap: widget.onTap != null
            ? () {
                setState(() => _pressed = false);
                widget.onTap!();
              }
            : null,
        onTapCancel: widget.onTap != null ? () => setState(() => _pressed = false) : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: widget.state == QuizOptionState.normal ? 1.5 : 2,
              ),
              boxShadow: widget.state == QuizOptionState.normal
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.text,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


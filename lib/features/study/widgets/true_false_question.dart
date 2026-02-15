import 'package:flutter/material.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';

class TrueFalseQuestion extends StatefulWidget {
  final String term;
  final String shownDefinition;
  final bool isCorrectPair;
  final void Function(bool isCorrect) onAnswered;

  const TrueFalseQuestion({
    super.key,
    required this.term,
    required this.shownDefinition,
    required this.isCorrectPair,
    required this.onAnswered,
  });

  @override
  State<TrueFalseQuestion> createState() => _TrueFalseQuestionState();
}

class _TrueFalseQuestionState extends State<TrueFalseQuestion> {
  bool? _selectedTrue;

  void _answer(bool selectedTrue) {
    if (_selectedTrue != null) return;
    setState(() => _selectedTrue = selectedTrue);
    final correct = selectedTrue == widget.isCorrectPair;
    widget.onAnswered(correct);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final answered = _selectedTrue != null;
    final wasCorrect =
        answered ? (_selectedTrue == widget.isCorrectPair) : false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.isThisCorrect,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 16),
        // Term
        Text(
          widget.term,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        // Divider
        const Divider(),
        const SizedBox(height: 8),
        // Shown definition
        Text(
          widget.shownDefinition,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 32),
        // True / False buttons
        Row(
          children: [
            Expanded(
              child: _TFButton(
                label: l10n.trueLabel,
                icon: Icons.check_rounded,
                color: AppTheme.green,
                isSelected: _selectedTrue == true,
                isCorrect: answered && widget.isCorrectPair,
                showResult: answered,
                onTap: answered ? null : () => _answer(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TFButton(
                label: l10n.falseLabel,
                icon: Icons.close_rounded,
                color: AppTheme.red,
                isSelected: _selectedTrue == false,
                isCorrect: answered && !widget.isCorrectPair,
                showResult: answered,
                onTap: answered ? null : () => _answer(false),
              ),
            ),
          ],
        ),
        if (answered && !wasCorrect) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.isCorrectPair
                  ? l10n.trueLabel
                  : l10n.falseLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TFButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback? onTap;

  const _TFButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.isCorrect,
    required this.showResult,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;

    if (showResult) {
      if (isCorrect) {
        bgColor = AppTheme.green.withValues(alpha: 0.1);
        borderColor = AppTheme.green;
      } else if (isSelected) {
        bgColor = AppTheme.red.withValues(alpha: 0.1);
        borderColor = AppTheme.red;
      } else {
        bgColor = Theme.of(context).cardColor;
        borderColor = Colors.grey.shade300;
      }
    } else {
      bgColor = Theme.of(context).cardColor;
      borderColor = Colors.grey.shade300;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: (showResult && (isCorrect || isSelected)) ? 2 : 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

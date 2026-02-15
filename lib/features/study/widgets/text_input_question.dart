import 'package:flutter/material.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/features/study/utils/fuzzy_match.dart';

class TextInputQuestion extends StatefulWidget {
  final String definition;
  final String correctAnswer;
  final void Function(bool isCorrect) onAnswered;

  const TextInputQuestion({
    super.key,
    required this.definition,
    required this.correctAnswer,
    required this.onAnswered,
  });

  @override
  State<TextInputQuestion> createState() => _TextInputQuestionState();
}

class _TextInputQuestionState extends State<TextInputQuestion> {
  final _controller = TextEditingController();
  bool? _isCorrect;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isCorrect != null) return;
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    final correct = isFuzzyMatch(input, widget.correctAnswer);
    setState(() => _isCorrect = correct);
    widget.onAnswered(correct);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final answered = _isCorrect != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.definition,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _controller,
          enabled: !answered,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: l10n.typeYourAnswer,
            border: const OutlineInputBorder(),
            suffixIcon: answered
                ? Icon(
                    _isCorrect! ? Icons.check_circle : Icons.cancel,
                    color: _isCorrect! ? AppTheme.green : AppTheme.red,
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        if (!answered)
          FilledButton(
            onPressed: _submit,
            child: Text(l10n.submit),
          ),
        if (answered) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (_isCorrect! ? AppTheme.green : AppTheme.red)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isCorrect! ? AppTheme.green : AppTheme.red,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isCorrect! ? l10n.correctAnswer : l10n.almostCorrect,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _isCorrect! ? AppTheme.green : AppTheme.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!_isCorrect!) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.correctAnswer,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

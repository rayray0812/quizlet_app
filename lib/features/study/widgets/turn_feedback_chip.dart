import 'package:flutter/material.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/features/study/services/conversation_scorer.dart';

/// Displays scoring feedback for a user's conversation turn.
///
/// Shows three color-coded dots (Grammar/Vocab/Relevance) that can be
/// tapped to expand and show correction details.
class TurnFeedbackChip extends StatefulWidget {
  final TurnFeedback? feedback;
  final bool isEvaluating;

  const TurnFeedbackChip({
    super.key,
    required this.feedback,
    required this.isEvaluating,
  });

  @override
  State<TurnFeedbackChip> createState() => _TurnFeedbackChipState();
}

class _TurnFeedbackChipState extends State<TurnFeedbackChip> {
  bool _expanded = false;

  Color _scoreColor(int score) {
    if (score >= 4) return Colors.green;
    if (score >= 3) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (widget.isEvaluating) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              l10n.evaluating,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    final feedback = widget.feedback;
    if (feedback == null) return const SizedBox.shrink();
    final normalizedCorrection = _normalizeFeedbackText(
      feedback.correction,
      removePrefixes: const ['correction:', 'corrected sentence:'],
    );
    final normalizedGrammarNote = _normalizeFeedbackText(
      feedback.grammarNote,
      removePrefixes: const ['grammar note:', 'note:'],
    );

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ScoreDot(
                    label: 'G', color: _scoreColor(feedback.grammarScore)),
                const SizedBox(width: 4),
                _ScoreDot(
                    label: 'V', color: _scoreColor(feedback.vocabScore)),
                const SizedBox(width: 4),
                _ScoreDot(
                    label: 'R',
                    color: _scoreColor(feedback.relevanceScore)),
                const SizedBox(width: 6),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 14,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 6),
              _ScoreRow(
                  label: l10n.grammarLabel,
                  score: feedback.grammarScore,
                  color: _scoreColor(feedback.grammarScore)),
              _ScoreRow(
                  label: l10n.vocabLabel,
                  score: feedback.vocabScore,
                  color: _scoreColor(feedback.vocabScore)),
              _ScoreRow(
                  label: l10n.relevanceLabel,
                  score: feedback.relevanceScore,
                  color: _scoreColor(feedback.relevanceScore)),
              if (normalizedCorrection.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '${l10n.correctionLabel}: $normalizedCorrection',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade800,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (normalizedGrammarNote.isNotEmpty)
                Text(
                  normalizedGrammarNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (normalizedCorrection.isEmpty &&
                  normalizedGrammarNote.isEmpty)
                Text(
                  l10n.noErrorsFound,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _normalizeFeedbackText(
    String raw, {
    required List<String> removePrefixes,
  }) {
    var text = raw.trim();
    if (text.isEmpty) return '';
    text = text.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    for (final prefix in removePrefixes) {
      final low = text.toLowerCase();
      if (low.startsWith(prefix)) {
        text = text.substring(prefix.length).trim();
        break;
      }
    }
    if (text.startsWith('"') && text.endsWith('"') && text.length > 1) {
      text = text.substring(1, text.length - 1).trim();
    }
    return text;
  }
}

class _ScoreDot extends StatelessWidget {
  final String label;
  final Color color;

  const _ScoreDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int score;
  final Color color;

  const _ScoreRow({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          ...List.generate(5, (i) {
            return Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(
                i < score ? Icons.star_rounded : Icons.star_border_rounded,
                size: 14,
                color: i < score ? color : Colors.grey.shade300,
              ),
            );
          }),
        ],
      ),
    );
  }
}

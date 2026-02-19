import 'package:flutter/material.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/widgets/app_back_button.dart';
import 'package:recall_app/features/study/models/conversation_transcript.dart';

/// Read-only view of a completed conversation transcript.
class TranscriptDetailScreen extends StatelessWidget {
  final ConversationTranscript transcript;

  const TranscriptDetailScreen({super.key, required this.transcript});

  Color _scoreColor(double score) {
    if (score >= 4.0) return Colors.green;
    if (score >= 3.0) return Colors.amber.shade700;
    if (score >= 2.0) return Colors.orange;
    return Colors.red;
  }

  Color _intScoreColor(int score) => _scoreColor(score.toDouble());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final score = transcript.overallScore;

    // Compute dimension averages
    double grammarAvg = 0, vocabAvg = 0, relevanceAvg = 0;
    int scored = 0;
    for (final turn in transcript.turns) {
      if (turn.grammarScore > 0 ||
          turn.vocabScore > 0 ||
          turn.relevanceScore > 0) {
        grammarAvg += turn.grammarScore;
        vocabAvg += turn.vocabScore;
        relevanceAvg += turn.relevanceScore;
        scored++;
      }
    }
    if (scored > 0) {
      grammarAvg /= scored;
      vocabAvg /= scored;
      relevanceAvg /= scored;
    }

    final date = transcript.completedAt.toLocal();
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(transcript.scenarioTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _scoreColor(score).withValues(alpha: 0.15),
                  _scoreColor(score).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  score.toStringAsFixed(1),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: _scoreColor(score),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text('${l10n.overallScore} / 5.0',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  '${transcript.difficulty.toUpperCase()} \u2022 ${l10n.nTurnsCompleted(transcript.totalTurns)} \u2022 $dateStr',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dimension averages
          if (scored > 0)
            Row(
              children: [
                _DimCard(l10n.grammarAvg, grammarAvg, _scoreColor(grammarAvg)),
                const SizedBox(width: 8),
                _DimCard(l10n.vocabAvg, vocabAvg, _scoreColor(vocabAvg)),
                const SizedBox(width: 8),
                _DimCard(
                    l10n.relevanceAvg, relevanceAvg, _scoreColor(relevanceAvg)),
              ],
            ),
          const SizedBox(height: 16),

          // Turn timeline
          Text(l10n.turnTimeline,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...transcript.turns.asMap().entries.map((entry) {
            final i = entry.key;
            final turn = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(turn.aiQuestion,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(turn.userResponse),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Chip('G', turn.grammarScore, _intScoreColor),
                      const SizedBox(width: 4),
                      _Chip('V', turn.vocabScore, _intScoreColor),
                      const SizedBox(width: 4),
                      _Chip('R', turn.relevanceScore, _intScoreColor),
                    ],
                  ),
                  if (turn.correction.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '\u2192 ${turn.correction}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _DimCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _DimCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value.toStringAsFixed(1),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final int score;
  final Color Function(int) colorFn;

  const _Chip(this.label, this.score, this.colorFn);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorFn(score).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$label:$score',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorFn(score))),
    );
  }
}

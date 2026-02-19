import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/widgets/app_back_button.dart';
import 'package:recall_app/features/study/models/conversation_transcript.dart';

class ConversationSummaryScreen extends StatelessWidget {
  final ConversationTranscript transcript;
  final String setId;

  const ConversationSummaryScreen({
    super.key,
    required this.transcript,
    required this.setId,
  });

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

    // Vocab coverage
    final allTermsUsed = <String>{};
    for (final turn in transcript.turns) {
      allTermsUsed.addAll(turn.termsUsed);
    }

    // Turns with corrections
    final correctionTurns =
        transcript.turns.where((t) => t.correction.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.conversationSummary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _scoreColor(score).withValues(alpha: 0.15),
                  _scoreColor(score).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _scoreColor(score).withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  transcript.scenarioTitle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transcript.difficulty.toUpperCase()} \u2022 ${l10n.nTurnsCompleted(transcript.totalTurns)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Text(
                  score.toStringAsFixed(1),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: _scoreColor(score),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${l10n.overallScore} / 5.0',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dimension averages
          if (scored > 0)
            Row(
              children: [
                _DimensionCard(
                  label: l10n.grammarAvg,
                  value: grammarAvg,
                  color: _scoreColor(grammarAvg),
                ),
                const SizedBox(width: 8),
                _DimensionCard(
                  label: l10n.vocabAvg,
                  value: vocabAvg,
                  color: _scoreColor(vocabAvg),
                ),
                const SizedBox(width: 8),
                _DimensionCard(
                  label: l10n.relevanceAvg,
                  value: relevanceAvg,
                  color: _scoreColor(relevanceAvg),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Vocab coverage
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.vocabCoverage,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  '${allTermsUsed.length} terms used',
                  style: theme.textTheme.bodySmall,
                ),
                if (allTermsUsed.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: allTermsUsed
                        .map((t) => Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text(t,
                                  style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
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
            return _TurnCard(
              turnIndex: i,
              turn: turn,
              scoreColor: _intScoreColor,
            );
          }),
          const SizedBox(height: 16),

          // Error list
          if (correctionTurns.isNotEmpty) ...[
            Text(l10n.errorList,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                )),
            const SizedBox(height: 8),
            ...correctionTurns.map((turn) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Colors.orange.shade50.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        turn.userResponse,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\u2192 ${turn.correction}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Go back to study mode picker for same set
                    context.go('/study/$setId');
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(l10n.practiceAgain),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home_rounded),
                  label: Text(l10n.goHome),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _DimensionCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _DimensionCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TurnCard extends StatelessWidget {
  final int turnIndex;
  final TranscriptTurn turn;
  final Color Function(int) scoreColor;

  const _TurnCard({
    required this.turnIndex,
    required this.turn,
    required this.scoreColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  '${turnIndex + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  turn.aiQuestion,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
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
            child: Text(turn.userResponse,
                style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _MiniScore('G', turn.grammarScore, scoreColor),
              const SizedBox(width: 6),
              _MiniScore('V', turn.vocabScore, scoreColor),
              const SizedBox(width: 6),
              _MiniScore('R', turn.relevanceScore, scoreColor),
              if (turn.termsUsed.isNotEmpty) ...[
                const Spacer(),
                Text(
                  turn.termsUsed.join(', '),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
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
  }
}

class _MiniScore extends StatelessWidget {
  final String label;
  final int score;
  final Color Function(int) colorFn;

  const _MiniScore(this.label, this.score, this.colorFn);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorFn(score).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label:$score',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colorFn(score),
        ),
      ),
    );
  }
}

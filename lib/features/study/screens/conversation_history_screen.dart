import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/widgets/app_back_button.dart';
import 'package:recall_app/features/study/models/conversation_transcript.dart';
import 'package:recall_app/providers/study_set_provider.dart';

class ConversationHistoryScreen extends ConsumerWidget {
  const ConversationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final localStorage = ref.watch(localStorageServiceProvider);
    final transcripts = localStorage.getAllConversationTranscripts();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.conversationHistory),
      ),
      body: transcripts.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 48,
                      color: theme.colorScheme.outline
                          .withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(l10n.noConversationHistory,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transcripts.length,
              itemBuilder: (context, index) {
                final t = transcripts[index];
                return _TranscriptCard(
                  transcript: t,
                  onTap: () {
                    context.push(
                      '/conversation/history/${t.id}',
                      extra: t,
                    );
                  },
                );
              },
            ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  final ConversationTranscript transcript;
  final VoidCallback onTap;

  const _TranscriptCard({
    required this.transcript,
    required this.onTap,
  });

  Color _scoreColor(double score) {
    if (score >= 4.0) return Colors.green;
    if (score >= 3.0) return Colors.amber.shade700;
    if (score >= 2.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = transcript.completedAt.toLocal();
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _scoreColor(transcript.overallScore)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    transcript.overallScore.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _scoreColor(transcript.overallScore),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transcript.scenarioTitle,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${transcript.setTitle} \u2022 ${transcript.difficulty}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      '$dateStr $timeStr \u2022 ${transcript.totalTurns} turns',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

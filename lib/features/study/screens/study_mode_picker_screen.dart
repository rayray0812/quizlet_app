import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizlet_app/providers/study_set_provider.dart';
import 'package:quizlet_app/services/import_export_service.dart';
import 'package:quizlet_app/features/study/widgets/count_picker_dialog.dart';

class StudyModePickerScreen extends ConsumerWidget {
  final String setId;

  const StudyModePickerScreen({super.key, required this.setId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studySet = ref.watch(studySetsProvider.notifier).getById(setId);

    if (studySet == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Study set not found')),
      );
    }

    final hasEnoughCards = studySet.cards.length >= 4;

    return Scaffold(
      appBar: AppBar(
        title: Text(studySet.title),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              final service = ImportExportService();
              if (value == 'json') {
                await service.exportAsJson(studySet);
              } else if (value == 'csv') {
                await service.exportAsCsv(studySet);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'json',
                child: ListTile(
                  leading: Icon(Icons.code),
                  title: Text('Export as JSON'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'csv',
                child: ListTile(
                  leading: Icon(Icons.table_chart),
                  title: Text('Export as CSV'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${studySet.cards.length} cards',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _StudyModeCard(
              icon: Icons.flip,
              title: 'Flashcards',
              description: 'Swipe through cards and flip to reveal answers',
              onTap: studySet.cards.isEmpty
                  ? null
                  : () => context.push('/study/$setId/flashcards'),
            ),
            const SizedBox(height: 12),
            _StudyModeCard(
              icon: Icons.quiz,
              title: 'Quiz',
              description: 'Multiple choice questions to test your knowledge',
              onTap: hasEnoughCards
                  ? () async {
                      final count = await showCountPickerDialog(
                        context: context,
                        maxCount: studySet.cards.length,
                        minCount: 4,
                        label: 'questions',
                      );
                      if (count != null && context.mounted) {
                        context.push('/study/$setId/quiz',
                            extra: {'questionCount': count});
                      }
                    }
                  : null,
              disabledReason:
                  hasEnoughCards ? null : 'Need at least 4 cards for quiz',
            ),
            const SizedBox(height: 12),
            _StudyModeCard(
              icon: Icons.grid_view,
              title: 'Matching Game',
              description: 'Match terms with their definitions',
              onTap: studySet.cards.length >= 2
                  ? () async {
                      final count = await showCountPickerDialog(
                        context: context,
                        maxCount: studySet.cards.length,
                        minCount: 2,
                        defaultCount: 6,
                        label: 'pairs',
                      );
                      if (count != null && context.mounted) {
                        context.push('/study/$setId/match',
                            extra: {'pairCount': count});
                      }
                    }
                  : null,
              disabledReason: studySet.cards.length >= 2
                  ? null
                  : 'Need at least 2 cards to match',
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final String? disabledReason;

  const _StudyModeCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.disabledReason,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        disabledReason ?? description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDisabled
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                            ),
                      ),
                    ],
                  ),
                ),
                if (!isDisabled)
                  const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizlet_app/models/study_set.dart';
import 'package:quizlet_app/providers/fsrs_provider.dart';
import 'package:quizlet_app/core/l10n/app_localizations.dart';

class StudySetCard extends ConsumerWidget {
  final StudySet studySet;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const StudySetCard({
    super.key,
    required this.studySet,
    required this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueCount = ref.watch(dueCountForSetProvider(studySet.id));
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${studySet.cards.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studySet.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${studySet.cards.length} cards',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (dueCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.nDueCards(dueCount),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (studySet.isSynced)
                Icon(
                  Icons.cloud_done_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Edit cards',
                ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

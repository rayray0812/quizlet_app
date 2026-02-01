import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:quizlet_app/providers/study_set_provider.dart';
import 'package:quizlet_app/providers/fsrs_provider.dart';
import 'package:quizlet_app/services/import_export_service.dart';
import 'package:quizlet_app/services/unsplash_service.dart';
import 'package:quizlet_app/features/study/widgets/count_picker_dialog.dart';
import 'package:quizlet_app/core/l10n/app_localizations.dart';

class StudyModePickerScreen extends ConsumerWidget {
  final String setId;

  const StudyModePickerScreen({super.key, required this.setId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studySet = ref.watch(studySetsProvider.notifier).getById(setId);

    final l10n = AppLocalizations.of(context);

    if (studySet == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.studySetNotFound)),
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
              } else if (value == 'auto_image') {
                final unsplash = UnsplashService();
                final updatedCards = <dynamic>[];
                for (final card in studySet.cards) {
                  if (card.imageUrl.isEmpty && card.term.isNotEmpty) {
                    final url = await unsplash.searchPhoto(card.term);
                    updatedCards.add(card.copyWith(imageUrl: url));
                  } else {
                    updatedCards.add(card);
                  }
                }
                ref.read(studySetsProvider.notifier).update(
                    studySet.copyWith(cards: updatedCards.cast()));
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'json',
                child: ListTile(
                  leading: const Icon(Icons.code),
                  title: Text(l10n.exportAsJson),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'csv',
                child: ListTile(
                  leading: const Icon(Icons.table_chart),
                  title: Text(l10n.exportAsCsv),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'auto_image',
                child: ListTile(
                  leading: const Icon(Icons.image_search),
                  title: Text(l10n.autoFetchImage),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 48),
        children: [
          // Card count
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l10n.nCards(studySet.cards.length),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

          // Horizontal card preview
          if (studySet.cards.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: studySet.cards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final card = studySet.cards[i];
                  return SizedBox(
                    width: 150,
                    child: Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (card.imageUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: CachedNetworkImage(
                                    imageUrl: card.imageUrl,
                                    width: double.infinity,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                card.term,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: card.imageUrl.isNotEmpty ? 2 : 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 28),

          // Study mode cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Consumer(builder: (context, ref, _) {
                  final dueCount = ref.watch(dueCountForSetProvider(setId));
                  return _StudyModeCard(
                    icon: Icons.psychology,
                    title: l10n.srsReview,
                    description: dueCount > 0
                        ? '${l10n.srsReviewDesc} — ${l10n.nDueCards(dueCount)}'
                        : l10n.srsReviewDesc,
                    onTap: studySet.cards.isEmpty
                        ? null
                        : () => context.push('/study/$setId/srs'),
                    badge: dueCount > 0 ? '$dueCount' : null,
                  );
                }),
                const SizedBox(height: 10),
                _StudyModeCard(
                  icon: Icons.flip,
                  title: l10n.quickBrowse,
                  description: l10n.quickBrowseDesc,
                  onTap: studySet.cards.isEmpty
                      ? null
                      : () => context.push('/study/$setId/flashcards'),
                ),
                const SizedBox(height: 10),
                _StudyModeCard(
                  icon: Icons.quiz,
                  title: l10n.quiz,
                  description: l10n.quizDesc,
                  onTap: hasEnoughCards
                      ? () async {
                          final count = await showCountPickerDialog(
                            context: context,
                            maxCount: studySet.cards.length,
                            minCount: 4,
                          );
                          if (count != null && context.mounted) {
                            context.push('/study/$setId/quiz',
                                extra: {'questionCount': count});
                          }
                        }
                      : null,
                  disabledReason:
                      hasEnoughCards ? null : l10n.needAtLeast4Cards,
                ),
                const SizedBox(height: 10),
                _StudyModeCard(
                  icon: Icons.grid_view,
                  title: l10n.matchingGame,
                  description: l10n.matchingGameDesc,
                  onTap: studySet.cards.length >= 2
                      ? () => context.push('/study/$setId/match')
                      : null,
                  disabledReason: studySet.cards.length >= 2
                      ? null
                      : l10n.needAtLeast2Cards,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => context.push('/edit/$setId'),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(l10n.editCards),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => context.push('/edit/$setId'),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.addCards),
                  ),
                ),
              ],
            ),
          ),

          // All terms list
          if (studySet.cards.isNotEmpty) ...[
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.allTerms,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            ...studySet.cards.asMap().entries.map((entry) {
              final card = entry.value;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        card.term,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        height: 20,
                        child: VerticalDivider(
                          width: 1,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        card.definition,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
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
  final String? badge;

  const _StudyModeCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.disabledReason,
    this.badge,
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
                Badge(
                  isLabelVisible: badge != null,
                  label: badge != null ? Text(badge!) : null,
                  child: Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
                ),
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

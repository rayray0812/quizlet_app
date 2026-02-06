import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:quizlet_app/providers/study_set_provider.dart';
import 'package:quizlet_app/providers/fsrs_provider.dart';
import 'package:quizlet_app/models/flashcard.dart';
import 'package:quizlet_app/services/import_export_service.dart';
import 'package:quizlet_app/services/unsplash_service.dart';
import 'package:quizlet_app/features/study/widgets/count_picker_dialog.dart';
import 'package:quizlet_app/core/l10n/app_localizations.dart';
import 'package:quizlet_app/core/theme/app_theme.dart';

class StudyModePickerScreen extends ConsumerWidget {
  final String setId;

  const StudyModePickerScreen({super.key, required this.setId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studySet = ref
        .watch(studySetsProvider)
        .where((s) => s.id == setId)
        .firstOrNull;
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
                final updatedCards = <Flashcard>[];
                for (final card in studySet.cards) {
                  if (card.imageUrl.isEmpty && card.term.isNotEmpty) {
                    final url = await unsplash.searchPhoto(card.term);
                    updatedCards.add(card.copyWith(imageUrl: url));
                  } else {
                    updatedCards.add(card);
                  }
                }
                ref
                    .read(studySetsProvider.notifier)
                    .update(studySet.copyWith(cards: updatedCards));
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
            padding: const EdgeInsets.symmetric(vertical: 14),
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
                    child: Container(
                      decoration: AppTheme.softCardDecoration(
                        fillColor: Theme.of(context).cardColor,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (card.imageUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
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
                                style: Theme.of(context).textTheme.bodyMedium
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
                Consumer(
                  builder: (context, ref, _) {
                    final dueCount = ref.watch(dueCountForSetProvider(setId));
                    return _StudyModeCard(
                      icon: Icons.psychology_rounded,
                      iconColor: AppTheme.purple,
                      title: l10n.srsReview,
                      description: dueCount > 0
                          ? '${l10n.srsReviewDesc} \u2014 ${l10n.nDueCards(dueCount)}'
                          : l10n.srsReviewDesc,
                      onTap: studySet.cards.isEmpty
                          ? null
                          : () => context.push('/study/$setId/srs'),
                      badge: dueCount > 0 ? '$dueCount' : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _StudyModeCard(
                  icon: Icons.flip_rounded,
                  iconColor: AppTheme.cyan,
                  title: l10n.quickBrowse,
                  description: l10n.quickBrowseDesc,
                  onTap: studySet.cards.isEmpty
                      ? null
                      : () => context.push('/study/$setId/flashcards'),
                ),
                const SizedBox(height: 12),
                _StudyModeCard(
                  icon: Icons.quiz_rounded,
                  iconColor: AppTheme.orange,
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
                            context.push(
                              '/study/$setId/quiz',
                              extra: {'questionCount': count},
                            );
                          }
                        }
                      : null,
                  disabledReason: hasEnoughCards
                      ? null
                      : l10n.needAtLeast4Cards,
                ),
                const SizedBox(height: 12),
                _StudyModeCard(
                  icon: Icons.grid_view_rounded,
                  iconColor: AppTheme.indigo,
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

          const SizedBox(height: 28),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/edit/$setId'),
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                label: Text(
                  studySet.cards.isEmpty ? l10n.addCards : l10n.editCards,
                ),
              ),
            ),
          ),

          // All terms list
          if (studySet.cards.isNotEmpty) ...[
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.allTerms,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            ...studySet.cards.asMap().entries.map((entry) {
              final card = entry.value;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: AppTheme.softCardDecoration(
                  fillColor: Theme.of(context).cardColor,
                  borderRadius: 12,
                  elevation: 0.5,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        card.term,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _StudyModeCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final String? disabledReason;
  final String? badge;

  const _StudyModeCard({
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor = Colors.deepPurple,
    this.onTap,
    this.disabledReason,
    this.badge,
  });

  @override
  State<_StudyModeCard> createState() => _StudyModeCardState();
}

class _StudyModeCardState extends State<_StudyModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: isDisabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            },
      onTapCancel: isDisabled ? null : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: AppTheme.softCardDecoration(
            fillColor: Theme.of(context).cardColor,
            borderRadius: 16,
          ),
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Badge(
                    isLabelVisible: widget.badge != null,
                    label: widget.badge != null ? Text(widget.badge!) : null,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: widget.iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 26,
                        color: isDisabled
                            ? Theme.of(context).colorScheme.outline
                            : widget.iconColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.disabledReason ?? widget.description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isDisabled
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (!isDisabled)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

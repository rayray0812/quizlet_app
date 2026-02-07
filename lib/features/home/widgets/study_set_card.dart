import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/providers/fsrs_provider.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';

class StudySetCard extends ConsumerStatefulWidget {
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
  ConsumerState<StudySetCard> createState() => _StudySetCardState();
}

class _StudySetCardState extends ConsumerState<StudySetCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dueCount = ref.watch(dueCountForSetProvider(widget.studySet.id));
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()..translate(0.0, _pressed ? 2.0 : 0.0),
            decoration: AppTheme.softCardDecoration(
              fillColor: Theme.of(context).cardColor,
              borderRadius: 16,
              borderColor: dueCount > 0
                  ? AppTheme.orange.withValues(alpha: 0.22)
                  : null,
              elevation: _pressed ? 0.7 : 1.5,
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // Card count
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.studySet.cards.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title & info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.studySet.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Text(
                              '${widget.studySet.cards.length} cards',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.outline,
                                  ),
                            ),
                            if (dueCount > 0) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.orange.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  l10n.nDueCards(dueCount),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.orange,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  if (widget.studySet.isSynced)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.cloud_done_outlined,
                        size: 18,
                        color: colorScheme.outline,
                      ),
                    ),
                  if (widget.onEdit != null)
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 19,
                          color: colorScheme.outline),
                      onPressed: widget.onEdit,
                      tooltip: 'Edit cards',
                      visualDensity: VisualDensity.compact,
                    ),
                  if (widget.onDelete != null)
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 19,
                          color: colorScheme.outline),
                      onPressed: widget.onDelete,
                      visualDensity: VisualDensity.compact,
                    ),
                  const SizedBox(width: 4),
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    offset: _pressed ? const Offset(0.16, 0) : Offset.zero,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.outline,
                      size: 20,
                    ),
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


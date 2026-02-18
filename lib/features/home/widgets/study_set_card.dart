import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recall_app/core/widgets/adaptive_glass_card.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/providers/fsrs_provider.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTap: () {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AdaptiveGlassCard(
            borderRadius: 16,
            fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.56),
            borderColor: dueCount > 0
                ? AppTheme.indigo.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.2),
            elevation: _pressed ? 0.8 : 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppTheme.indigo.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.studySet.cards.length}',
                        style: GoogleFonts.notoSerifTc(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.green,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.studySet.title,
                                style: GoogleFonts.notoSerifTc(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.studySet.isPinned)
                              Icon(
                                Icons.push_pin_rounded,
                                size: 16,
                                color: AppTheme.indigo.withValues(alpha: 0.7),
                              ),
                            if (widget.studySet.isSynced)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.cloud_done_rounded,
                                  size: 16,
                                  color: Color(0xFF8CA08D),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Text(
                              l10n.nCards(widget.studySet.cards.length),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (dueCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.orange.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  l10n.nDueCards(dueCount),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.green,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (widget.onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: Theme.of(context).colorScheme.outline,
                      onPressed: widget.onEdit,
                      visualDensity: VisualDensity.compact,
                    ),
                  if (widget.onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      color: Theme.of(context).colorScheme.outline,
                      onPressed: widget.onDelete,
                      visualDensity: VisualDensity.compact,
                    ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.outline,
                    size: 20,
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



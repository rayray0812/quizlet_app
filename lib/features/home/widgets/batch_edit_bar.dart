import 'package:flutter/material.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';

class BatchEditBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onDelete;
  final VoidCallback onAddTag;
  final VoidCallback onRemoveTag;

  const BatchEditBar({
    super.key,
    required this.selectedCount,
    required this.onDelete,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Text(
              l10n.nSelected(selectedCount),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: onAddTag,
              icon: const Icon(Icons.label_outline),
              tooltip: l10n.addTagToSelected,
            ),
            IconButton(
              onPressed: onRemoveTag,
              icon: const Icon(Icons.label_off_outlined),
              tooltip: l10n.removeTagFromSelected,
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              tooltip: l10n.deleteSelected,
            ),
          ],
        ),
      ),
    );
  }
}

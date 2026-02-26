import 'package:flutter/material.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/widgets/adaptive_glass_card.dart';

class QuickCardEditRow extends StatelessWidget {
  final int index;
  final TextEditingController termController;
  final TextEditingController definitionController;
  final TextEditingController? exampleSentenceController;
  final String imageUrl;
  final List<String> tags;
  final List<String> issueLabels;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;
  final VoidCallback onDelete;
  final bool expanded;
  final VoidCallback? onToggleExpanded;
  final VoidCallback? onAutoImage;
  final VoidCallback? onEditImage;
  final VoidCallback? onClearImage;
  final void Function(String tag)? onAddTag;
  final void Function(String tag)? onRemoveTag;

  const QuickCardEditRow({
    super.key,
    required this.index,
    required this.termController,
    required this.definitionController,
    this.exampleSentenceController,
    this.imageUrl = '',
    this.tags = const [],
    required this.onDelete,
    this.issueLabels = const [],
    this.isSelected = false,
    this.onSelectionChanged,
    this.expanded = false,
    this.onToggleExpanded,
    this.onAutoImage,
    this.onEditImage,
    this.onClearImage,
    this.onAddTag,
    this.onRemoveTag,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasIssues = issueLabels.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;

    return AdaptiveGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      fillColor: hasIssues
          ? scheme.errorContainer.withValues(alpha: 0.22)
          : Theme.of(context).cardColor,
      borderColor: hasIssues
          ? scheme.error.withValues(alpha: 0.16)
          : Colors.white.withValues(alpha: 0.35),
      borderRadius: 14,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onSelectionChanged != null)
                Checkbox(
                  value: isSelected,
                  onChanged: onSelectionChanged,
                  visualDensity: VisualDensity.compact,
                ),
              Text(
                '#${index + 1}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final label in issueLabels)
                      _IssueChip(label: label, colorScheme: scheme),
                  ],
                ),
              ),
              IconButton(
                onPressed: onToggleExpanded,
                icon: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: scheme.outline,
                ),
                tooltip: expanded ? '收起詳細欄位' : '展開詳細欄位',
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: scheme.error,
                  size: 20,
                ),
                tooltip: l10n.deleteCard,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  controller: termController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.termLabel,
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 6,
                child: TextField(
                  controller: definitionController,
                  textInputAction: TextInputAction.next,
                  minLines: 1,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.definitionInput,
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 8),
            if (exampleSentenceController != null)
              TextField(
                controller: exampleSentenceController,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.exampleSentenceLabel,
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.56),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            if (exampleSentenceController != null) const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (imageUrl.isNotEmpty)
                  _SoftMetaChip(label: '有圖片', icon: Icons.image_rounded),
                if (tags.isNotEmpty)
                  _SoftMetaChip(
                    label: '標籤 ${tags.length}',
                    icon: Icons.sell_outlined,
                  ),
                if (onAutoImage != null)
                  OutlinedButton.icon(
                    onPressed: onAutoImage,
                    icon: const Icon(Icons.image_search, size: 16),
                    label: Text(l10n.autoFetchImage),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (onEditImage != null)
                  OutlinedButton.icon(
                    onPressed: onEditImage,
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: const Text('圖片'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (imageUrl.isNotEmpty && onClearImage != null)
                  OutlinedButton.icon(
                    onPressed: onClearImage,
                    icon: const Icon(Icons.hide_image_outlined, size: 16),
                    label: const Text('移除圖'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: scheme.error,
                    ),
                  ),
              ],
            ),
            if (onAddTag != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final pos in const [
                    'n.',
                    'v.',
                    'adj.',
                    'adv.',
                    'prep.',
                    'conj.',
                    'phr.',
                  ])
                    ActionChip(
                      label: Text(pos),
                      avatar: tags.contains(pos)
                          ? const Icon(Icons.check_rounded, size: 14)
                          : null,
                      onPressed: () {
                        if (tags.contains(pos)) {
                          onRemoveTag?.call(pos);
                        } else {
                          onAddTag?.call(pos);
                        }
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SoftMetaChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SoftMetaChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: scheme.outline),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueChip extends StatelessWidget {
  final String label;
  final ColorScheme colorScheme;

  const _IssueChip({required this.label, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

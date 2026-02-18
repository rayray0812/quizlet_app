import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/icons/material_icon_mapper.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/providers/folder_provider.dart';

class FolderChips extends ConsumerWidget {
  const FolderChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersProvider);
    final selectedId = ref.watch(selectedFolderIdProvider);
    final l10n = AppLocalizations.of(context);

    if (folders.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FolderFilterChip(
              label: l10n.allTerms,
              selected: selectedId == null,
              onTap: () => ref.read(selectedFolderIdProvider.notifier).state = null,
              tint: AppTheme.indigo,
            ),
          ),
          ...folders.map((folder) {
            final color = Color(int.parse(folder.colorHex, radix: 16));
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FolderFilterChip(
                label: folder.name,
                selected: selectedId == folder.id,
                onTap: () {
                  ref.read(selectedFolderIdProvider.notifier).state =
                      selectedId == folder.id ? null : folder.id;
                },
                tint: color,
                avatar: Icon(
                  MaterialIconMapper.fromCodePoint(folder.iconCodePoint),
                  size: 16,
                  color: color,
                ),
              ),
            );
          }),
          ],
        ),
      ),
    );
  }
}

class _FolderFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color tint;
  final Widget? avatar;

  const _FolderFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.tint,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: EdgeInsets.fromLTRB(avatar == null ? 13 : 10, 7, 13, 7),
        decoration: BoxDecoration(
          color: selected
              ? tint.withValues(alpha: 0.16)
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.52),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? tint.withValues(alpha: 0.34)
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (avatar != null) ...[
              avatar!,
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

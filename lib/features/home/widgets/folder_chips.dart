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

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(l10n.allTerms),
              selected: selectedId == null,
              onSelected: (_) {
                ref.read(selectedFolderIdProvider.notifier).state = null;
              },
              selectedColor: AppTheme.indigo.withValues(alpha: 0.15),
              checkmarkColor: AppTheme.indigo,
            ),
          ),
          ...folders.map((folder) {
            final color = Color(int.parse(folder.colorHex, radix: 16));
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(
                  MaterialIconMapper.fromCodePoint(folder.iconCodePoint),
                  size: 16,
                  color: color,
                ),
                label: Text(folder.name),
                selected: selectedId == folder.id,
                onSelected: (_) {
                  ref.read(selectedFolderIdProvider.notifier).state =
                      selectedId == folder.id ? null : folder.id;
                },
                selectedColor: color.withValues(alpha: 0.15),
                checkmarkColor: color,
              ),
            );
          }),
        ],
      ),
    );
  }
}

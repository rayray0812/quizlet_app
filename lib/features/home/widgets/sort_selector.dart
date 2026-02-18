import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/providers/sort_provider.dart';

class SortSelector extends ConsumerWidget {
  const SortSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(sortOptionProvider);
    final l10n = AppLocalizations.of(context);

    final labels = {
      SortOption.newestFirst: l10n.sortNewest,
      SortOption.alphabetical: l10n.sortAlpha,
      SortOption.mostDue: l10n.sortMostDue,
      SortOption.lastStudied: l10n.sortLastStudied,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: PopupMenuButton<SortOption>(
          initialValue: current,
          onSelected: (option) {
            ref.read(sortOptionProvider.notifier).setOption(option);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.56),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sort_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 6),
                Text(
                  labels[current] ?? '',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ],
            ),
          ),
          itemBuilder: (context) => SortOption.values
              .map((option) => PopupMenuItem(
                    value: option,
                    child: Row(
                      children: [
                        if (option == current)
                          Icon(Icons.check_rounded, size: 16, color: AppTheme.indigo)
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 8),
                        Text(labels[option] ?? ''),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      child: Row(
        children: [
          Icon(Icons.sort_rounded,
              size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 6),
          PopupMenuButton<SortOption>(
            initialValue: current,
            onSelected: (option) {
              ref.read(sortOptionProvider.notifier).setOption(option);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    labels[current] ?? '',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  Icon(Icons.arrow_drop_down,
                      size: 18, color: Theme.of(context).colorScheme.outline),
                ],
              ),
            ),
            itemBuilder: (context) => SortOption.values
                .map((option) => PopupMenuItem(
                      value: option,
                      child: Row(
                        children: [
                          if (option == current)
                            const Icon(Icons.check, size: 16)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(labels[option] ?? ''),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizlet_app/providers/study_set_provider.dart';
import 'package:quizlet_app/providers/tag_provider.dart';
import 'package:quizlet_app/core/l10n/app_localizations.dart';

class CustomStudyScreen extends ConsumerStatefulWidget {
  const CustomStudyScreen({super.key});

  @override
  ConsumerState<CustomStudyScreen> createState() => _CustomStudyScreenState();
}

class _CustomStudyScreenState extends ConsumerState<CustomStudyScreen> {
  final Set<String> _selectedTags = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allTags = ref.watch(allTagsProvider);
    final studySets = ref.watch(studySetsProvider);

    // Count matching cards
    int matchingCount = 0;
    if (_selectedTags.isNotEmpty) {
      for (final set in studySets) {
        for (final card in set.cards) {
          if (card.tags.any((t) => _selectedTags.contains(t))) {
            matchingCount++;
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customStudy)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              l10n.selectTags,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allTags.map((tag) {
                final selected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          if (allTags.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  l10n.noResults,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ),
            ),
          const Spacer(),
          if (_selectedTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: matchingCount > 0
                      ? () => context.go('/review')
                      : null,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    '${l10n.startReview} (${l10n.nMatchingCards(matchingCount)})',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

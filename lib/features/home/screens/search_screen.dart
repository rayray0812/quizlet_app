import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizlet_app/models/flashcard.dart';
import 'package:quizlet_app/providers/study_set_provider.dart';
import 'package:quizlet_app/core/l10n/app_localizations.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final studySets = ref.watch(studySetsProvider);

    // Search results grouped by set
    final results = <String, List<Flashcard>>{};
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      for (final set in studySets) {
        final matched = set.cards.where((c) =>
            c.term.toLowerCase().contains(q) ||
            c.definition.toLowerCase().contains(q) ||
            c.tags.any((t) => t.toLowerCase().contains(q)));
        if (matched.isNotEmpty) {
          results[set.title] = matched.toList();
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.search,
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
      ),
      body: _query.isEmpty
          ? Center(
              child: Text(
                l10n.search,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            )
          : results.isEmpty
              ? Center(child: Text(l10n.noResults))
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: results.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Text(
                            entry.key,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        ...entry.value.map((card) => ListTile(
                              title: Text(card.term),
                              subtitle: Text(
                                card.definition,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: card.tags.isNotEmpty
                                  ? Wrap(
                                      spacing: 4,
                                      children: card.tags
                                          .take(2)
                                          .map((t) => Chip(
                                                label: Text(t,
                                                    style: const TextStyle(
                                                        fontSize: 10)),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                padding: EdgeInsets.zero,
                                              ))
                                          .toList(),
                                    )
                                  : null,
                            )),
                      ],
                    );
                  }).toList(),
                ),
    );
  }
}

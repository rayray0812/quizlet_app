import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/adaptive_glass_card.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/providers/study_set_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const SearchScreen({super.key, this.embedded = false});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _applyQuery(String value) {
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() => _query = value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final studySets = ref.watch(studySetsProvider);
    final results = _buildResults(studySets, _query);
    final totalMatches = results.fold<int>(
      0,
      (sum, item) => sum + item.cards.length,
    );

    final body = Stack(
      children: [
        const Positioned.fill(child: _SearchBackdropAccent()),
        ListView(
          padding: EdgeInsets.fromLTRB(16, widget.embedded ? 22 : 16, 16, 24),
          children: [
            if (!widget.embedded) ...[
              Text(
                l10n.search,
                style: GoogleFonts.notoSerifTc(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.quickBrowseDesc,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 14),
            ],
            AdaptiveGlassCard(
              borderRadius: 16,
              fillColor: Colors.white.withValues(alpha: 0.86),
              borderColor: Colors.white.withValues(alpha: 0.45),
              elevation: 1.6,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: !widget.embedded,
                textInputAction: TextInputAction.search,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: l10n.searchCards,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => _applyQuery(''),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            const SizedBox(height: 10),
            if (_query.isEmpty) ...[
              _buildSuggestionPanel(context, studySets),
              const SizedBox(height: 18),
              _buildDiscovery(context, studySets),
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.layers_rounded,
                    label: '${results.length} ${l10n.studySetsLabel}',
                  ),
                  _InfoChip(
                    icon: Icons.style_rounded,
                    label: l10n.nMatchingCards(totalMatches),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.close_rounded, size: 16),
                    label: Text(MaterialLocalizations.of(context).clearButtonTooltip),
                    onPressed: () => _applyQuery(''),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildResultsView(context, l10n, results),
            ],
          ],
        ),
      ],
    );

    if (!widget.embedded) {
      return Scaffold(body: SafeArea(child: body));
    }

    return body;
  }

  Widget _buildSuggestionPanel(BuildContext context, List<StudySet> sets) {
    final l10n = AppLocalizations.of(context);
    final suggestions = _smartSuggestions(sets);
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l10n.search),
        const SizedBox(height: 8),
        AdaptiveGlassCard(
          borderRadius: 16,
          fillColor: Colors.white.withValues(alpha: 0.8),
          borderColor: Colors.white.withValues(alpha: 0.4),
          elevation: 1.2,
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map(
                  (item) => ActionChip(
                    avatar: Icon(item.icon, size: 16, color: item.tint),
                    label: Text(item.label),
                    backgroundColor: Colors.white.withValues(alpha: 0.76),
                    side: BorderSide(color: item.tint.withValues(alpha: 0.22)),
                    labelStyle: TextStyle(
                      color: item.tint,
                      fontWeight: FontWeight.w700,
                    ),
                    onPressed: () => _applyQuery(item.query),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscovery(BuildContext context, List<StudySet> sets) {
    final tags = _topTags(sets);
    final l10n = AppLocalizations.of(context);
    final recentSets = [...sets]
      ..sort((a, b) {
        final aTime = a.lastStudiedAt ?? a.createdAt;
        final bTime = b.lastStudiedAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: l10n.quickBrowse,
          trailing: TextButton(
            onPressed: () => _focusNode.requestFocus(),
            child: Text(l10n.search),
          ),
        ),
        const SizedBox(height: 8),
        AdaptiveGlassCard(
          borderRadius: 16,
          fillColor: Colors.white.withValues(alpha: 0.8),
          borderColor: Colors.white.withValues(alpha: 0.4),
          elevation: 1.2,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map(
                  (tag) => ActionChip(
                    label: Text(tag),
                    onPressed: () => _applyQuery(tag),
                    backgroundColor: Colors.white.withValues(alpha: 0.76),
                    labelStyle: TextStyle(
                      color: AppTheme.indigo,
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(color: AppTheme.indigo.withValues(alpha: 0.22)),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 22),
        _SectionTitle(title: l10n.studySetsLabel),
        const SizedBox(height: 8),
        ...recentSets.take(8).map(
              (set) => _CollectionRow(
                set: set,
                onTap: () => context.push('/study/${set.id}'),
              ),
            ),
      ],
    );
  }

  Widget _buildResultsView(
    BuildContext context,
    AppLocalizations l10n,
    List<_SearchResultSection> results,
  ) {
    if (results.isEmpty) {
      return AdaptiveGlassCard(
        borderRadius: 14,
        fillColor: Colors.white.withValues(alpha: 0.8),
        borderColor: Colors.white.withValues(alpha: 0.42),
        elevation: 1.2,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(l10n.noResults)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _applyQuery(''),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(MaterialLocalizations.of(context).clearButtonTooltip),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push('/import'),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.createOrImportSet),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: results.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: AdaptiveGlassCard(
            borderRadius: 16,
            fillColor: Colors.white.withValues(alpha: 0.8),
            borderColor: Colors.white.withValues(alpha: 0.42),
            elevation: 1.3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.setTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSerifTc(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push('/edit/${entry.setId}'),
                        tooltip: 'Edit',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit_rounded, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.style_rounded,
                        label: l10n.nMatchingCards(entry.cards.length),
                      ),
                      if (entry.matchedTitle)
                        const _InfoChip(
                          icon: Icons.title_rounded,
                          label: 'Title',
                        ),
                      if (entry.matchedDescription)
                        const _InfoChip(
                          icon: Icons.notes_rounded,
                          label: 'Description',
                        ),
                    ],
                  ),
                  if (entry.setDescription.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      entry.setDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                  if (entry.cards.isEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Matched in set metadata.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ...entry.cards.take(3).map(
                        (card) => _MatchedCardRow(
                          card: card,
                          onTap: () => context.push('/study/${entry.setId}'),
                        ),
                      ),
                  if (entry.cards.length > 3) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => context.push('/study/${entry.setId}'),
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: Text('+${entry.cards.length - 3}'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/study/${entry.setId}'),
                          icon: const Icon(Icons.folder_open_rounded, size: 18),
                          label: Text(l10n.goTo),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.push('/study/${entry.setId}/srs'),
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: Text(l10n.reviewCards),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<_SmartSuggestion> _smartSuggestions(List<StudySet> sets) {
    final suggestions = <_SmartSuggestion>[];
    final seenQueries = <String>{};
    final recent = [...sets]
      ..sort((a, b) {
        final aTime = a.lastStudiedAt ?? a.createdAt;
        final bTime = b.lastStudiedAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
    if (recent.isNotEmpty) {
      seenQueries.add(recent.first.title.toLowerCase());
      suggestions.add(
        _SmartSuggestion(
          query: recent.first.title,
          label: recent.first.title,
          icon: Icons.history_rounded,
          tint: AppTheme.indigo,
        ),
      );
    }

    for (final tag in _topTags(sets).take(5)) {
      if (!seenQueries.add(tag.toLowerCase())) continue;
      suggestions.add(
        _SmartSuggestion(
          query: tag,
          label: tag,
          icon: Icons.tag_rounded,
          tint: AppTheme.cyan,
        ),
      );
    }
    return suggestions.take(6).toList();
  }

  List<String> _topTags(List<StudySet> sets) {
    final tagCount = <String, int>{};
    for (final set in sets) {
      for (final card in set.cards) {
        for (final tag in card.tags) {
          final clean = tag.trim();
          if (clean.isEmpty) continue;
          tagCount.update(clean, (value) => value + 1, ifAbsent: () => 1);
        }
      }
    }

    final sorted = tagCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final tags = sorted.take(6).map((e) => e.key).toList();
    if (tags.isEmpty) {
      tags.addAll(['English', 'TOEIC', 'Biology', 'History']);
    }
    return tags;
  }

  List<_SearchResultSection> _buildResults(
    List<StudySet> studySets,
    String query,
  ) {
    final results = <_SearchResultSection>[];
    if (query.isEmpty) return results;

    final q = query.toLowerCase();
    for (final set in studySets) {
      final matchedTitle = set.title.toLowerCase().contains(q);
      final matchedDescription = set.description.toLowerCase().contains(q);
      final matchedCards = set.cards.where((c) {
        return c.term.toLowerCase().contains(q) ||
            c.definition.toLowerCase().contains(q) ||
            c.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
      if (!matchedTitle && !matchedDescription && matchedCards.isEmpty) {
        continue;
      }

      final score = (matchedTitle ? 8 : 0) +
          (matchedDescription ? 3 : 0) +
          (matchedCards.length * 2);
      results.add(
        _SearchResultSection(
          setId: set.id,
          setTitle: set.title,
          setDescription: set.description,
          cards: matchedCards,
          matchedTitle: matchedTitle,
          matchedDescription: matchedDescription,
          score: score,
        ),
      );
    }

    results.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.setTitle.compareTo(b.setTitle);
    });
    return results;
  }
}

class _SearchBackdropAccent extends StatelessWidget {
  const _SearchBackdropAccent();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -50,
            child: _SearchOrb(
              size: 220,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            top: 120,
            left: -62,
            child: _SearchOrb(
              size: 190,
              color: AppTheme.cyan.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _SearchOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.02),
            Colors.transparent,
          ],
          stops: const [0, 0.6, 1],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.indigo,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.notoSerifTc(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.indigo),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.indigo,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchedCardRow extends StatelessWidget {
  final Flashcard card;
  final VoidCallback onTap;

  const _MatchedCardRow({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
        title: Text(
          card.term,
          style: GoogleFonts.notoSerifTc(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            card.definition,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  final StudySet set;
  final VoidCallback onTap;

  const _CollectionRow({required this.set, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: AdaptiveGlassCard(
        borderRadius: 14,
        fillColor: Colors.white.withValues(alpha: 0.78),
        borderColor: Colors.white.withValues(alpha: 0.4),
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.folder_rounded, color: AppTheme.indigo),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        set.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSerifTc(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context).cards(set.cards.length),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResultSection {
  final String setId;
  final String setTitle;
  final String setDescription;
  final List<Flashcard> cards;
  final bool matchedTitle;
  final bool matchedDescription;
  final int score;

  const _SearchResultSection({
    required this.setId,
    required this.setTitle,
    required this.setDescription,
    required this.cards,
    required this.matchedTitle,
    required this.matchedDescription,
    required this.score,
  });
}

class _SmartSuggestion {
  final String query;
  final String label;
  final IconData icon;
  final Color tint;

  const _SmartSuggestion({
    required this.query,
    required this.label,
    required this.icon,
    required this.tint,
  });
}

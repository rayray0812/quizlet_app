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
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyQuery(String value) {
    _controller.text = value;
    setState(() => _query = value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final studySets = ref.watch(studySetsProvider);
    final results = _buildResults(studySets, _query);
    final totalMatches = results.fold<int>(0, (sum, item) => sum + item.cards.length);

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
                '快速搜尋詞彙、定義與標籤',
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
                autofocus: !widget.embedded,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                decoration: InputDecoration(
                  hintText: '搜尋單字、定義或標籤',
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
            if (_query.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.76),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                    ),
                    child: Text(
                      '共 $totalMatches 筆結果',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppTheme.indigo,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            if (_query.isEmpty)
              _buildDiscovery(context, studySets)
            else
              _buildResultsView(context, l10n, results),
          ],
        ),
      ],
    );

    if (!widget.embedded) {
      return Scaffold(body: SafeArea(child: body));
    }

    return body;
  }

  Widget _buildDiscovery(
    BuildContext context,
    List<StudySet> sets,
  ) {
    final tags = _topTags(sets);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: '快速探索',
          trailing: TextButton(
            onPressed: () => _applyQuery(''),
            child: const Text('清除'),
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
        const _SectionTitle(title: '學習集'),
        const SizedBox(height: 8),
        ...sets.take(8).map(
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
    List<({String setId, String setTitle, List<Flashcard> cards})> results,
  ) {
    if (results.isEmpty) {
      return AdaptiveGlassCard(
        borderRadius: 14,
        fillColor: Colors.white.withValues(alpha: 0.8),
        borderColor: Colors.white.withValues(alpha: 0.42),
        elevation: 1.2,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.search_off_rounded, color: Theme.of(context).colorScheme.outline),
            const SizedBox(width: 10),
            Text(l10n.noResults),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: _SectionTitle(title: entry.setTitle),
                ),
                ...entry.cards.take(8).map(
                      (card) => ListTile(
                        onTap: () => context.push('/study/${entry.setId}'),
                        contentPadding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
                        title: Text(
                          card.term,
                          style: GoogleFonts.notoSerifTc(
                            fontSize: 18,
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
                    ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      }).toList(),
    );
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
      tags.addAll(['英文', '多益', '生物', '歷史']);
    }
    return tags;
  }

  List<({String setId, String setTitle, List<Flashcard> cards})> _buildResults(
    List<StudySet> studySets,
    String query,
  ) {
    final results = <({String setId, String setTitle, List<Flashcard> cards})>[];
    if (query.isEmpty) return results;

    final q = query.toLowerCase();
    for (final set in studySets) {
      final matched = set.cards.where((c) {
        return c.term.toLowerCase().contains(q) ||
            c.definition.toLowerCase().contains(q) ||
            c.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
      if (matched.isNotEmpty) {
        results.add((setId: set.id, setTitle: set.title, cards: matched));
      }
    }
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
                        '${set.cards.length} 張卡片',
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

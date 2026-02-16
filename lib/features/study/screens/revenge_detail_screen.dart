import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/app_back_button.dart';
import 'package:recall_app/providers/revenge_provider.dart';
import 'package:recall_app/providers/study_set_provider.dart';

class RevengeDetailScreen extends ConsumerStatefulWidget {
  const RevengeDetailScreen({super.key});

  @override
  ConsumerState<RevengeDetailScreen> createState() =>
      _RevengeDetailScreenState();
}

class _RevengeDetailScreenState extends ConsumerState<RevengeDetailScreen> {
  final Set<String> _selectedSetIds = {};
  bool _selectAll = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lookbackDays = ref.watch(revengeLookbackDaysProvider);
    final cardsBySet = ref.watch(revengeCardsBySetProvider);
    final stats = ref.watch(revengeStatsProvider);
    final allSets = ref.watch(studySetsProvider);

    // Build set name map
    final setNameMap = <String, String>{};
    for (final s in allSets) {
      setNameMap[s.id] = s.title;
    }

    // Initialize selection to all sets on first build
    if (_selectAll) {
      _selectedSetIds
        ..clear()
        ..addAll(cardsBySet.keys);
    }

    // Compute filtered card IDs based on selected sets
    final filteredCardIds = <String>[];
    for (final setId in _selectedSetIds) {
      filteredCardIds.addAll(cardsBySet[setId] ?? []);
    }

    final canQuiz = filteredCardIds.length >= 4;

    // Look up top wrong cards for display
    final topWrongDisplay = stats.topWrong.take(5).toList();

    // Build card term lookup
    final cardTermMap = <String, String>{};
    for (final s in allSets) {
      for (final c in s.cards) {
        cardTermMap[c.id] = c.term;
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.revengeDetail),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Lookback days selector
          _SectionTitle(title: l10n.revengeLookbackDays),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: [
              for (final d in [3, 7, 14, 30])
                ButtonSegment(value: d, label: Text(l10n.revengeDaysOption(d))),
            ],
            selected: {lookbackDays},
            onSelectionChanged: (selected) {
              ref
                  .read(revengeLookbackDaysProvider.notifier)
                  .setDays(selected.first);
              setState(() => _selectAll = true);
            },
          ),
          const SizedBox(height: 20),

          // Study set filter
          _SectionTitle(title: l10n.revengeSelectSets),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              FilterChip(
                label: Text(l10n.revengeFilterAll),
                selected: _selectAll,
                onSelected: (v) {
                  setState(() {
                    _selectAll = true;
                    _selectedSetIds
                      ..clear()
                      ..addAll(cardsBySet.keys);
                  });
                },
              ),
              for (final setId in cardsBySet.keys)
                FilterChip(
                  label: Text(
                    '${setNameMap[setId] ?? setId} (${cardsBySet[setId]?.length ?? 0})',
                  ),
                  selected: _selectedSetIds.contains(setId),
                  onSelected: (v) {
                    setState(() {
                      _selectAll = false;
                      if (v) {
                        _selectedSetIds.add(setId);
                      } else {
                        _selectedSetIds.remove(setId);
                      }
                      // If all are selected, flip to "All"
                      if (_selectedSetIds.length == cardsBySet.length) {
                        _selectAll = true;
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats section
          _SectionTitle(title: l10n.revengeStats),
          const SizedBox(height: 8),
          _StatsRow(
            totalWrong: stats.totalWrong,
            clearedCount: stats.clearedCount,
            clearRate: stats.clearRate,
            l10n: l10n,
          ),
          const SizedBox(height: 16),

          // Top wrong cards
          if (topWrongDisplay.isNotEmpty) ...[
            _SectionTitle(title: l10n.revengeMostWrong),
            const SizedBox(height: 8),
            for (final item in topWrongDisplay)
              _TopWrongRow(
                term: cardTermMap[item.cardId] ?? item.cardId,
                wrongCount: item.wrongCount,
                l10n: l10n,
              ),
            const SizedBox(height: 20),
          ],

          // Action buttons
          Text(
            l10n.revengeCount(filteredCardIds.length),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: filteredCardIds.isEmpty
                      ? null
                      : () {
                          context.push(
                            '/review',
                            extra: {'revengeCardIds': filteredCardIds},
                          );
                        },
                  icon: const Icon(Icons.flip_rounded),
                  label: Text(l10n.revengeStartFlip),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: canQuiz
                      ? () {
                          context.push(
                            '/revenge/quiz',
                            extra: {'cardIds': filteredCardIds},
                          );
                        }
                      : null,
                  icon: const Icon(Icons.quiz_rounded),
                  label: Text(l10n.revengeStartQuiz),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          if (!canQuiz && filteredCardIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.revengeNeedMoreCards,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int totalWrong;
  final int clearedCount;
  final double clearRate;
  final AppLocalizations l10n;

  const _StatsRow({
    required this.totalWrong,
    required this.clearedCount,
    required this.clearRate,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (clearRate * 100).round();
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: l10n.revengeMode,
            value: '$totalWrong',
            color: AppTheme.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: l10n.revengeClearRate,
            value: '$percent%',
            color: AppTheme.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: l10n.done,
            value: '$clearedCount',
            color: AppTheme.indigo,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TopWrongRow extends StatelessWidget {
  final String term;
  final int wrongCount;
  final AppLocalizations l10n;

  const _TopWrongRow({
    required this.term,
    required this.wrongCount,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.close_rounded, size: 16, color: AppTheme.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              term,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            l10n.revengeWrongTimes(wrongCount),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

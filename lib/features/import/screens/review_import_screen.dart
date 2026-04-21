import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/features/import/widgets/import_preview_card.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/app_back_button.dart';
import 'package:recall_app/core/widgets/app_feedback_toast.dart';

class ReviewImportScreen extends ConsumerStatefulWidget {
  final StudySet studySet;

  const ReviewImportScreen({super.key, required this.studySet});

  @override
  ConsumerState<ReviewImportScreen> createState() => _ReviewImportScreenState();
}

class _ReviewImportScreenState extends ConsumerState<ReviewImportScreen> {
  late TextEditingController _titleController;
  late List<Flashcard> _cards;
  bool _showSuspiciousOnly = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.studySet.title);
    _cards = List.from(widget.studySet.cards);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _removeCard(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除卡片'),
        content: const Text('確定要刪除這張卡片嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) return;
    setState(() => _cards.removeAt(index));
  }

  String _normalize(String value) => value.trim().toLowerCase();

  String? _suspiciousLabelFor(Flashcard card) {
    final term = card.term.trim();
    final def = card.definition.trim();
    if (term.isEmpty || def.isEmpty) return '空白';
    final t = _normalize(term);
    final d = _normalize(def);
    if (t == d) return '同字';
    if (RegExp(r'^[\d\W_]+$').hasMatch(t) ||
        RegExp(r'^[\d\W_]+$').hasMatch(d)) {
      return '符號';
    }
    if (term.length <= 1 && def.length <= 1) return '過短';
    final combined = '$t $d';
    const noisyWords = <String>[
      'page',
      'unit',
      'lesson',
      'chapter',
      'vocabulary',
      'exercise',
      'name',
      'class',
      'date',
    ];
    if (noisyWords.any((w) => combined == w || combined.startsWith('$w '))) {
      return '疑似標題';
    }
    return null;
  }

  int get _suspiciousCount =>
      _cards.where((c) => _suspiciousLabelFor(c) != null).length;

  Future<void> _removeAllSuspicious() async {
    final suspiciousIndices = <int>[
      for (var i = 0; i < _cards.length; i++)
        if (_suspiciousLabelFor(_cards[i]) != null) i,
    ];
    if (suspiciousIndices.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除可疑卡片'),
        content: Text('確定要刪除 ${suspiciousIndices.length} 張可疑卡片嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() {
      _cards = [
        for (var i = 0; i < _cards.length; i++)
          if (_suspiciousLabelFor(_cards[i]) == null) _cards[i],
      ];
      if (_suspiciousCount == 0) _showSuspiciousOnly = false;
    });
  }

  Future<void> _runSmartCleanup() async {
    if (_cards.isEmpty) return;
    final suspiciousBefore = _suspiciousCount;
    final mergeGroupsBefore = _sameTermDifferentMeaningGroups();
    var removeSuspicious = suspiciousBefore > 0;
    var mergeSameTerm = mergeGroupsBefore.isNotEmpty;

    if (!removeSuspicious && !mergeSameTerm) {
      if (!mounted) return;
      AppFeedbackToast.show(context, message: '目前沒有可清理項目');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text('一鍵清理'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('選擇要套用的清理項目：'),
              const SizedBox(height: 10),
              CheckboxListTile(
                value: removeSuspicious,
                onChanged: suspiciousBefore > 0
                    ? (v) => setLocalState(() => removeSuspicious = v == true)
                    : null,
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('刪除可疑卡片（$suspiciousBefore 張）'),
              ),
              CheckboxListTile(
                value: mergeSameTerm,
                onChanged: mergeGroupsBefore.isNotEmpty
                    ? (v) => setLocalState(() => mergeSameTerm = v == true)
                    : null,
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('合併同詞不同義（${mergeGroupsBefore.length} 組）'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('套用'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || confirmed != true) return;

    final beforeCount = _cards.length;
    var next = List<Flashcard>.from(_cards);
    var removedSuspiciousCount = 0;
    var mergedGroupCount = 0;

    if (removeSuspicious) {
      final filtered = <Flashcard>[];
      for (final card in next) {
        if (_suspiciousLabelFor(card) != null) {
          removedSuspiciousCount++;
        } else {
          filtered.add(card);
        }
      }
      next = filtered;
    }

    if (mergeSameTerm) {
      final groups = <String, List<Flashcard>>{};
      for (final card in next) {
        final key = _normalize(card.term);
        groups
            .putIfAbsent(key.isEmpty ? '__${card.id}' : key, () => [])
            .add(card);
      }
      for (final group in groups.values) {
        if (group.length < 2) continue;
        final defs = group
            .map((c) => _normalize(c.definition))
            .where((d) => d.isNotEmpty)
            .toSet();
        if (defs.length >= 2) mergedGroupCount++;
      }
      if (mergedGroupCount > 0) {
        next = _mergeImportedCardsByTerm(next);
      }
    }

    setState(() {
      _cards = next;
      if (_suspiciousCount == 0) _showSuspiciousOnly = false;
    });

    if (!mounted) return;
    final afterCount = next.length;
    final chips = <String>[
      if (removedSuspiciousCount > 0) '刪除可疑 $removedSuspiciousCount',
      if (mergedGroupCount > 0) '合併同詞 $mergedGroupCount 組',
      if (beforeCount != afterCount) '共減少 ${beforeCount - afterCount} 張',
    ];
    AppFeedbackToast.show(
      context,
      message: chips.isEmpty ? '已完成清理' : chips.join('｜'),
      tone: AppToastTone.success,
    );
  }

  List<String> _mergeUniqueTextParts(Iterable<String> values) {
    final seen = <String>{};
    final merged = <String>[];
    for (final raw in values) {
      final parts = raw
          .split(RegExp(r'[\n\r]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);
      for (final part in parts) {
        final key = part.toLowerCase();
        if (seen.add(key)) merged.add(part);
      }
    }
    return merged;
  }

  List<({String term, List<int> indices})> _sameTermDifferentMeaningGroups() {
    final grouped = <String, List<int>>{};
    for (var i = 0; i < _cards.length; i++) {
      final key = _normalize(_cards[i].term);
      if (key.isEmpty) continue;
      grouped.putIfAbsent(key, () => <int>[]).add(i);
    }
    final result = <({String term, List<int> indices})>[];
    for (final entry in grouped.entries) {
      if (entry.value.length < 2) continue;
      final defs = entry.value
          .map((i) => _normalize(_cards[i].definition))
          .where((d) => d.isNotEmpty)
          .toSet();
      if (defs.length < 2) continue;
      result.add((term: _cards[entry.value.first].term, indices: entry.value));
    }
    result.sort((a, b) => a.indices.first.compareTo(b.indices.first));
    return result;
  }

  Future<bool> _confirmMergeImportedGroups(
    List<({String term, List<int> indices})> groups,
  ) async {
    if (groups.isEmpty) return false;
    final lines = groups
        .take(8)
        .map(
          (g) => '• ${g.term}（第 ${(g.indices.map((i) => i + 1)).join('、')} 張）',
        )
        .toList();
    final remaining = groups.length - lines.length;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('偵測到同字不同義'),
        content: SingleChildScrollView(
          child: Text(
            [
              '匯入卡片中有同一個單字對應多個中文意思，要先合併再儲存嗎？',
              '',
              ...lines,
              if (remaining > 0) '• 另外還有 $remaining 組',
            ].join('\n'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('不合併'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('合併後儲存'),
          ),
        ],
      ),
    );
    return result == true;
  }

  List<Flashcard> _mergeImportedCardsByTerm(List<Flashcard> cards) {
    final grouped = <String, List<Flashcard>>{};
    for (final card in cards) {
      final key = _normalize(card.term);
      grouped
          .putIfAbsent(key.isEmpty ? '__${card.id}' : key, () => [])
          .add(card);
    }
    final ordered = grouped.values.toList()
      ..sort(
        (a, b) => cards.indexOf(a.first).compareTo(cards.indexOf(b.first)),
      );

    return [
      for (final group in ordered)
        if (group.length == 1)
          group.first
        else
          () {
            final base = group.first;
            final mergedDef = _mergeUniqueTextParts(
              group.map((c) => c.definition),
            ).join('\n');
            final mergedExample = _mergeUniqueTextParts(
              group.map((c) => c.exampleSentence),
            ).join('\n');
            final tags = <String>[];
            final seenTags = <String>{};
            for (final card in group) {
              for (final tag in card.tags) {
                final key = _normalize(tag);
                if (key.isEmpty) continue;
                if (seenTags.add(key)) tags.add(tag);
              }
            }
            final imageUrl = group
                .map((c) => c.imageUrl.trim())
                .firstWhere((v) => v.isNotEmpty, orElse: () => '');
            return base.copyWith(
              definition: mergedDef,
              exampleSentence: mergedExample,
              imageUrl: imageUrl,
              tags: tags,
            );
          }(),
    ];
  }

  Future<void> _save() async {
    if (_cards.isEmpty) {
      AppFeedbackToast.show(
        context,
        message: 'Add at least one card',
        tone: AppToastTone.warning,
      );
      return;
    }

    var cardsToSave = List<Flashcard>.from(_cards);
    final groups = _sameTermDifferentMeaningGroups();
    if (groups.isNotEmpty) {
      final shouldMerge = await _confirmMergeImportedGroups(groups);
      if (!mounted) return;
      if (shouldMerge) {
        cardsToSave = _mergeImportedCardsByTerm(cardsToSave);
      }
    }

    final updatedSet = widget.studySet.copyWith(
      title: _titleController.text.trim().isEmpty
          ? 'Imported Set'
          : _titleController.text.trim(),
      cards: cardsToSave,
    );

    ref.read(studySetsProvider.notifier).add(updatedSet);
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final mergeGroupCount = _sameTermDifferentMeaningGroups().length;
    final hasSmartCleanup = _suspiciousCount > 0 || mergeGroupCount > 0;
    final visibleEntries = <({int originalIndex, Flashcard card})>[
      for (var i = 0; i < _cards.length; i++)
        if (!_showSuspiciousOnly || _suspiciousLabelFor(_cards[i]) != null)
          (originalIndex: i, card: _cards[i]),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Review Import'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Set Title'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.indigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_cards.length} cards',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.indigo,
                      ),
                    ),
                  ),
                  if (hasSmartCleanup) ...[
                    const SizedBox(width: 8),
                    if (_suspiciousCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.errorContainer.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '可疑 $_suspiciousCount',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    if (_suspiciousCount > 0) const SizedBox(width: 8),
                    if (mergeGroupCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.orange.withValues(alpha: 0.22),
                          ),
                        ),
                        child: const Text(
                          '可合併',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.orange,
                          ),
                        ),
                      ),
                    if (mergeGroupCount > 0) const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _runSmartCleanup,
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                      label: const Text('一鍵清理'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    if (_suspiciousCount > 0) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => setState(
                          () => _showSuspiciousOnly = !_showSuspiciousOnly,
                        ),
                        icon: Icon(
                          _showSuspiciousOnly
                              ? Icons.visibility_off_outlined
                              : Icons.filter_alt_outlined,
                          size: 16,
                        ),
                        label: Text(_showSuspiciousOnly ? '顯示全部' : '只看可疑'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: _removeAllSuspicious,
                        tooltip: '刪除全部可疑',
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.delete_sweep_rounded,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: visibleEntries.isEmpty
                ? Center(child: Text(_showSuspiciousOnly ? '目前沒有可疑卡片' : '尚無卡片'))
                : ListView.builder(
                    itemCount: visibleEntries.length,
                    itemBuilder: (context, index) {
                      final entry = visibleEntries[index];
                      return ImportPreviewCard(
                        flashcard: entry.card,
                        index: entry.originalIndex,
                        warningLabel: _suspiciousLabelFor(entry.card),
                        onDelete: () {
                          _removeCard(entry.originalIndex);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

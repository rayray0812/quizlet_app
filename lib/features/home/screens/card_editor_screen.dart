import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/features/home/widgets/card_edit_row.dart';
import 'package:recall_app/features/home/widgets/batch_edit_bar.dart';
import 'package:recall_app/features/home/widgets/quick_card_edit_row.dart';
import 'package:recall_app/features/home/widgets/save_warning_dialog.dart';
import 'package:recall_app/features/home/utils/editor_history.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/widgets/app_back_button.dart';
import 'package:recall_app/core/widgets/app_feedback_toast.dart';
import 'package:recall_app/services/unsplash_service.dart';
import 'package:recall_app/services/gemini_service.dart';
import 'package:recall_app/providers/gemini_key_provider.dart';

class CardEditorScreen extends ConsumerStatefulWidget {
  final String setId;

  const CardEditorScreen({super.key, required this.setId});

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

enum _EditorViewMode { detailed, quick }

class _CardEditorScreenState extends ConsumerState<CardEditorScreen> {
  final List<TextEditingController> _termControllers = [];
  final List<TextEditingController> _defControllers = [];
  final List<TextEditingController> _exampleControllers = [];
  final List<String> _cardIds = [];
  final List<String> _imageUrls = [];
  final List<List<String>> _tags = [];

  final EditorHistory _history = EditorHistory();
  Timer? _debounceTimer;

  // Batch select mode
  bool _selectMode = false;
  final Set<int> _selectedIndices = {};

  // Key to force-rebuild CardEditRow after undo/redo
  int _rebuildKey = 0;

  // Search filter
  String _searchQuery = '';
  final _searchController = TextEditingController();
  int _pageSize = 30;
  int _pageIndex = 0;
  _EditorViewMode _viewMode = _EditorViewMode.detailed;
  bool _quickIssuesOnly = false;
  final Set<int> _quickExpandedRows = {};

  @override
  void initState() {
    super.initState();
    final studySet = ref.read(studySetsProvider.notifier).getById(widget.setId);
    if (studySet != null) {
      for (final card in studySet.cards) {
        _addCardControllers(
          term: card.term,
          definition: card.definition,
          example: card.exampleSentence,
          id: card.id,
          imageUrl: card.imageUrl,
          tags: card.tags,
        );
      }
    }
    if (_termControllers.isEmpty) {
      _addEmptyCard();
    } else {
      // Add auto-add listener to the last card's term field
      _termControllers.last.addListener(_autoAddNextCard);
    }

    _addListenersToAll();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    for (final c in _termControllers) {
      c.dispose();
    }
    for (final c in _defControllers) {
      c.dispose();
    }
    for (final c in _exampleControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addCardControllers({
    String term = '',
    String definition = '',
    String example = '',
    String? id,
    String imageUrl = '',
    List<String> tags = const [],
  }) {
    _termControllers.add(TextEditingController(text: term));
    _defControllers.add(TextEditingController(text: definition));
    _exampleControllers.add(TextEditingController(text: example));
    _cardIds.add(id ?? const Uuid().v4());
    _imageUrls.add(imageUrl);
    _tags.add(List<String>.from(tags));
  }

  void _addListenersToAll() {
    for (var i = 0; i < _termControllers.length; i++) {
      _termControllers[i].addListener(_onTextChanged);
      _defControllers[i].addListener(_onTextChanged);
      _exampleControllers[i].addListener(_onTextChanged);
    }
  }

  void _removeListenersFromAll() {
    for (var i = 0; i < _termControllers.length; i++) {
      _termControllers[i].removeListener(_onTextChanged);
      _defControllers[i].removeListener(_onTextChanged);
      _exampleControllers[i].removeListener(_onTextChanged);
    }
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _history.pushState(_currentSnapshot());
    });
  }

  List<CardSnapshot> _currentSnapshot() {
    return List.generate(
      _termControllers.length,
      (i) => CardSnapshot(
        id: _cardIds[i],
        term: _termControllers[i].text,
        definition: _defControllers[i].text,
        example: _exampleControllers[i].text,
        imageUrl: _imageUrls[i],
        tags: List<String>.from(_tags[i]),
      ),
    );
  }

  void _restoreSnapshot(List<CardSnapshot> snapshot) {
    _removeListenersFromAll();

    // Dispose old controllers
    for (final c in _termControllers) {
      c.dispose();
    }
    for (final c in _defControllers) {
      c.dispose();
    }
    for (final c in _exampleControllers) {
      c.dispose();
    }

    _termControllers.clear();
    _defControllers.clear();
    _exampleControllers.clear();
    _cardIds.clear();
    _imageUrls.clear();
    _tags.clear();

    for (final s in snapshot) {
      _addCardControllers(
        term: s.term,
        definition: s.definition,
        example: s.example,
        id: s.id,
        imageUrl: s.imageUrl,
        tags: s.tags,
      );
    }

    _addListenersToAll();
    _rebuildKey++;
  }

  void _undo() {
    final restored = _history.undo(_currentSnapshot());
    if (restored != null) {
      setState(() => _restoreSnapshot(restored));
    }
  }

  void _redo() {
    final restored = _history.redo(_currentSnapshot());
    if (restored != null) {
      setState(() => _restoreSnapshot(restored));
    }
  }

  void _showUndoSnackBar(String message) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    AppFeedbackToast.show(
      context,
      message: message,
      tone: AppToastTone.warning,
      duration: const Duration(seconds: 4),
      action: SnackBarAction(label: l10n.undoAction, onPressed: _undo),
    );
  }

  void _addEmptyCard() {
    _history.pushState(_currentSnapshot());
    _appendEmptyCardNoHistory();
  }

  /// Appends a new empty card row without pushing to undo history.
  void _appendEmptyCardNoHistory() {
    setState(() {
      _addCardControllers();
      final i = _termControllers.length - 1;
      _termControllers[i].addListener(_onTextChanged);
      _defControllers[i].addListener(_onTextChanged);
      _exampleControllers[i].addListener(_onTextChanged);
      _termControllers[i].addListener(_autoAddNextCard);
    });
  }

  /// When the user starts typing in the last card's term field, auto-add a new
  /// empty card below so they can keep typing without pressing "+".
  void _autoAddNextCard() {
    if (_termControllers.isEmpty) return;
    final lastIndex = _termControllers.length - 1;
    final lastTerm = _termControllers[lastIndex].text.trim();
    if (lastTerm.isNotEmpty) {
      // Remove this listener so it doesn't fire again
      _termControllers[lastIndex].removeListener(_autoAddNextCard);
      _appendEmptyCardNoHistory();
    }
  }

  void _removeCard(int index) {
    _history.pushState(_currentSnapshot());
    setState(() {
      _termControllers[index].removeListener(_onTextChanged);
      _defControllers[index].removeListener(_onTextChanged);
      _exampleControllers[index].removeListener(_onTextChanged);
      _termControllers[index].dispose();
      _defControllers[index].dispose();
      _exampleControllers[index].dispose();
      _termControllers.removeAt(index);
      _defControllers.removeAt(index);
      _exampleControllers.removeAt(index);
      _cardIds.removeAt(index);
      _imageUrls.removeAt(index);
      _tags.removeAt(index);
      _selectedIndices.remove(index);
      // Adjust selected indices
      _selectedIndices.removeWhere((i) => i >= _termControllers.length);
    });
  }

  Future<bool> _confirmDeleteOneCard(int index) async {
    final l10n = AppLocalizations.of(context);
    final term = _termControllers[index].text.trim();
    final def = _defControllers[index].text.trim();
    final preview = term.isNotEmpty
        ? (def.isNotEmpty ? '$term \u2014 $def' : term)
        : (def.isNotEmpty ? def : '\u7B2C ${index + 1} \u5F35');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCard),
        content: Text(
          '\u78BA\u5B9A\u8981\u522A\u9664\u300C$preview\u300D\u55CE\uFF1F',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<bool> _confirmDeleteSelectedCards(int count) async {
    final l10n = AppLocalizations.of(context);
    final selected = _selectedIndices.toList()..sort();
    final previews = selected.take(6).map((index) {
      final term = _termControllers[index].text.trim();
      final def = _defControllers[index].text.trim();
      final label = term.isNotEmpty
          ? (def.isNotEmpty ? '$term — $def' : term)
          : (def.isNotEmpty ? def : '第 ${index + 1} 張');
      return '• $label';
    }).toList();
    final remainingCount = selected.length - previews.length;
    final previewText = [
      '確定要刪除 $count 張卡片嗎？',
      if (previews.isNotEmpty) '',
      ...previews,
      if (remainingCount > 0) '• 另外還有 $remainingCount 張',
    ].join('\n');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSelected),
        content: SingleChildScrollView(child: Text(previewText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _autoImage(int index) async {
    final term = _termControllers[index].text.trim();
    if (term.isEmpty) return;
    final url = await UnsplashService().searchPhoto(term);
    if (url.isNotEmpty && mounted) {
      setState(() => _imageUrls[index] = url);
    }
  }

  Future<void> _editImageUrl(int index) async {
    final controller = TextEditingController(text: _imageUrls[index]);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('編輯圖片'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '圖片網址 (URL)',
            hintText: 'https://...',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(AppLocalizations.of(ctx).save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || result == null) return;

    final next = result.trim();
    if (next == _imageUrls[index]) return;
    _history.pushState(_currentSnapshot());
    setState(() => _imageUrls[index] = next);
  }

  Future<void> _jumpToCardDialog() async {
    if (_termControllers.isEmpty) return;
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('跳到卡號'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '1 - ${_termControllers.length}',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            final value = int.tryParse(controller.text.trim());
            Navigator.pop(ctx, value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, value);
            },
            child: const Text('前往'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || result == null) return;

    final targetIndex = (result - 1).clamp(0, _termControllers.length - 1);
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _quickExpandedRows.add(targetIndex);
      final size = _effectivePageSize;
      _pageIndex = size <= 0 ? 0 : (targetIndex ~/ size);
    });
  }

  void _clearImage(int index) {
    if (_imageUrls[index].isEmpty) return;
    _history.pushState(_currentSnapshot());
    setState(() => _imageUrls[index] = '');
  }

  Future<void> _generateAiExamples() async {
    final l10n = AppLocalizations.of(context);
    final apiKey = ref.read(geminiKeyProvider);

    if (apiKey.isEmpty) {
      if (!mounted) return;
      AppFeedbackToast.show(
        context,
        message: l10n.geminiApiKeyNotSet,
        tone: AppToastTone.warning,
      );
      return;
    }

    // Filter selected cards that have a term
    final toProcess = <Map<String, String>>[];
    final indicesToUpdate = <int>[];

    for (final i in _selectedIndices) {
      final term = _termControllers[i].text.trim();
      final def = _defControllers[i].text.trim();
      final existingExample = _exampleControllers[i].text.trim();
      if (term.isNotEmpty && existingExample.isEmpty) {
        toProcess.add({'term': term, 'definition': def});
        indicesToUpdate.add(i);
      }
    }

    if (toProcess.isEmpty) {
      AppFeedbackToast.show(
        context,
        message: l10n.noCardsAvailable,
        tone: AppToastTone.warning,
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final results = await GeminiService.generateExampleSentencesBatch(
        apiKey: apiKey,
        terms: toProcess,
      );

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      if (results.isEmpty) {
        AppFeedbackToast.show(
          context,
          message: l10n.scanParseError,
          tone: AppToastTone.error,
        );
        return;
      }

      _history.pushState(_currentSnapshot());
      setState(() {
        for (final i in indicesToUpdate) {
          final term = _termControllers[i].text.trim();
          if (results.containsKey(term)) {
            _exampleControllers[i].text = results[term]!;
          }
        }
      });

      AppFeedbackToast.show(
        context,
        message: l10n.generatedExamplesCount(results.length),
        tone: AppToastTone.success,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading
      AppFeedbackToast.show(
        context,
        message: l10n.scanParseError,
        tone: AppToastTone.error,
      );
    }
  }

  // -- Batch operations --

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      if (!_selectMode) _selectedIndices.clear();
    });
  }

  void _selectAllOrNone() {
    setState(() {
      if (_selectedIndices.length == _termControllers.length) {
        _selectedIndices.clear();
      } else {
        _selectedIndices.addAll(
          List.generate(_termControllers.length, (i) => i),
        );
      }
    });
  }

  String _normalizeTerm(String value) => value.trim().toLowerCase();

  String _normalizeDefinition(String value) => value.trim().toLowerCase();

  List<String> _mergeUniqueTextParts(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in values) {
      final parts = raw
          .split(RegExp(r'[\n\r]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);
      for (final part in parts) {
        final key = part.toLowerCase();
        if (seen.add(key)) result.add(part);
      }
    }
    return result;
  }

  List<({String termKey, String displayTerm, List<int> indices})>
  _sameTermGroupsForIndices(Iterable<int> indices) {
    final grouped = <String, List<int>>{};
    final displayTerms = <String, String>{};
    for (final index in indices) {
      final term = _termControllers[index].text.trim();
      final key = _normalizeTerm(term);
      if (key.isEmpty) continue;
      grouped.putIfAbsent(key, () => <int>[]).add(index);
      displayTerms.putIfAbsent(key, () => term);
    }
    final result =
        <({String termKey, String displayTerm, List<int> indices})>[];
    for (final entry in grouped.entries) {
      if (entry.value.length < 2) continue;
      result.add((
        termKey: entry.key,
        displayTerm: displayTerms[entry.key] ?? entry.key,
        indices: (entry.value..sort()),
      ));
    }
    result.sort((a, b) => a.indices.first.compareTo(b.indices.first));
    return result;
  }

  List<({String termKey, String displayTerm, List<int> rowNumbers})>
  _sameTermDifferentDefinitionGroupsForSave(
    List<
      ({
        int rowNumber,
        String id,
        String term,
        String definition,
        String example,
        String imageUrl,
        List<String> tags,
      })
    >
    rows,
  ) {
    final grouped =
        <
          String,
          List<
            ({
              int rowNumber,
              String id,
              String term,
              String definition,
              String example,
              String imageUrl,
              List<String> tags,
            })
          >
        >{};
    for (final row in rows) {
      final key = _normalizeTerm(row.term);
      if (key.isEmpty) continue;
      grouped.putIfAbsent(key, () => []).add(row);
    }

    final result =
        <({String termKey, String displayTerm, List<int> rowNumbers})>[];
    for (final entry in grouped.entries) {
      if (entry.value.length < 2) continue;
      final defKeys = entry.value
          .map((r) => _normalizeDefinition(r.definition))
          .where((v) => v.isNotEmpty)
          .toSet();
      if (defKeys.length < 2) continue;
      result.add((
        termKey: entry.key,
        displayTerm: entry.value.first.term,
        rowNumbers: entry.value.map((r) => r.rowNumber).toList()..sort(),
      ));
    }
    result.sort((a, b) => a.rowNumbers.first.compareTo(b.rowNumbers.first));
    return result;
  }

  Future<bool> _confirmMergeSameTermGroups({
    required List<({String displayTerm, List<int> rowNumbers})> groups,
    required bool beforeSave,
  }) async {
    if (groups.isEmpty) return false;
    final title = beforeSave ? '偵測到同字不同義' : '合併同字卡';
    final intro = beforeSave
        ? '發現同一個單字有多個中文意思，是否自動合併後再儲存？'
        : '將合併同單字的卡片，並把意思整合在同一張卡。';
    final lines = groups
        .take(8)
        .map((g) => '• ${g.displayTerm}（第 ${g.rowNumbers.join('、')} 張）')
        .toList();
    final remaining = groups.length - lines.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            [
              intro,
              '',
              ...lines,
              if (remaining > 0) '• 另外還有 $remaining 組',
            ].join('\n'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(beforeSave ? '合併後儲存' : '合併'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  void _mergeSelectedSameTermCards() async {
    if (_selectedIndices.length < 2) return;
    final groups = _sameTermGroupsForIndices(_selectedIndices);
    if (groups.isEmpty) {
      if (!mounted) return;
      AppFeedbackToast.show(context, message: '已選卡片沒有可合併的同字項目');
      return;
    }
    final proceed = await _confirmMergeSameTermGroups(
      groups: groups
          .map(
            (g) => (
              displayTerm: g.displayTerm,
              rowNumbers: g.indices.map((i) => i + 1).toList(),
            ),
          )
          .toList(),
      beforeSave: false,
    );
    if (!proceed || !mounted) return;

    _history.pushState(_currentSnapshot());
    final groupsDescending = groups.toList()
      ..sort((a, b) => b.indices.first.compareTo(a.indices.first));
    setState(() {
      for (final group in groupsDescending) {
        final sorted = group.indices.toList()..sort();
        final base = sorted.first;
        final mergedDefs = _mergeUniqueTextParts(
          sorted.map((i) => _defControllers[i].text),
        );
        final mergedExamples = _mergeUniqueTextParts(
          sorted.map((i) => _exampleControllers[i].text),
        );
        final mergedTags = <String>[];
        final seenTags = <String>{};
        for (final i in sorted) {
          for (final tag in _tags[i]) {
            final key = tag.trim().toLowerCase();
            if (key.isEmpty) continue;
            if (seenTags.add(key)) mergedTags.add(tag);
          }
        }
        final mergedImage = sorted
            .map((i) => _imageUrls[i].trim())
            .firstWhere((url) => url.isNotEmpty, orElse: () => '');

        _defControllers[base].text = mergedDefs.join('\n');
        _exampleControllers[base].text = mergedExamples.join('\n');
        _tags[base]
          ..clear()
          ..addAll(mergedTags);
        _imageUrls[base] = mergedImage;

        for (final idx in sorted.reversed) {
          if (idx == base) continue;
          _termControllers[idx].removeListener(_onTextChanged);
          _defControllers[idx].removeListener(_onTextChanged);
          _exampleControllers[idx].removeListener(_onTextChanged);
          _termControllers[idx].dispose();
          _defControllers[idx].dispose();
          _exampleControllers[idx].dispose();
          _termControllers.removeAt(idx);
          _defControllers.removeAt(idx);
          _exampleControllers.removeAt(idx);
          _cardIds.removeAt(idx);
          _imageUrls.removeAt(idx);
          _tags.removeAt(idx);
          _selectedIndices.remove(idx);
        }
      }
      _selectedIndices.clear();
    });
    _showUndoSnackBar('已合併 ${groups.length} 組同字卡');
  }

  void _deleteSelected() async {
    if (_selectedIndices.isEmpty) return;
    final confirmed = await _confirmDeleteSelectedCards(
      _selectedIndices.length,
    );
    if (!confirmed) return;
    _history.pushState(_currentSnapshot());
    final sorted = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
    setState(() {
      for (final index in sorted) {
        _termControllers[index].removeListener(_onTextChanged);
        _defControllers[index].removeListener(_onTextChanged);
        _exampleControllers[index].removeListener(_onTextChanged);
        _termControllers[index].dispose();
        _defControllers[index].dispose();
        _exampleControllers[index].dispose();
        _termControllers.removeAt(index);
        _defControllers.removeAt(index);
        _exampleControllers.removeAt(index);
        _cardIds.removeAt(index);
        _imageUrls.removeAt(index);
        _tags.removeAt(index);
      }
      _selectedIndices.clear();
    });
    _showUndoSnackBar('已刪除 ${sorted.length} 張卡片');
  }

  void _deleteOneCardWithConfirm(int index) async {
    final term = _termControllers[index].text.trim();
    final confirmed = await _confirmDeleteOneCard(index);
    if (!mounted || !confirmed) return;
    _removeCard(index);
    _showUndoSnackBar(term.isEmpty ? '已刪除卡片' : '已刪除「$term」');
  }

  void _addTagToSelected() {
    if (_selectedIndices.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addTag),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.tagNameHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final tag = controller.text.trim();
              if (tag.isNotEmpty) {
                _history.pushState(_currentSnapshot());
                setState(() {
                  for (final i in _selectedIndices) {
                    if (!_tags[i].contains(tag)) {
                      _tags[i].add(tag);
                    }
                  }
                });
              }
              Navigator.pop(ctx);
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  void _removeTagFromSelected() {
    if (_selectedIndices.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    // Collect all tags from selected cards
    final allTags = <String>{};
    for (final i in _selectedIndices) {
      allTags.addAll(_tags[i]);
    }
    if (allTags.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.removeTagFromSelected),
        children: allTags
            .map(
              (tag) => SimpleDialogOption(
                onPressed: () {
                  _history.pushState(_currentSnapshot());
                  setState(() {
                    for (final i in _selectedIndices) {
                      _tags[i].remove(tag);
                    }
                  });
                  Navigator.pop(ctx);
                },
                child: Text(tag),
              ),
            )
            .toList(),
      ),
    );
  }

  // -- Save with validation --

  Future<void> _save() async {
    final studySet = ref.read(studySetsProvider.notifier).getById(widget.setId);
    if (studySet == null) return;

    final l10n = AppLocalizations.of(context);
    final blankWarnings = <String>[];
    final duplicateWarnings = <String>[];
    final draftRows =
        <
          ({
            int rowNumber,
            String id,
            String term,
            String definition,
            String example,
            String imageUrl,
            List<String> tags,
          })
        >[];

    // Check blanks
    for (var i = 0; i < _termControllers.length; i++) {
      final term = _termControllers[i].text.trim();
      final def = _defControllers[i].text.trim();
      if (term.isEmpty && def.isNotEmpty) {
        blankWarnings.add(l10n.cardNMissingField(i + 1, l10n.termLabel));
      } else if (term.isNotEmpty && def.isEmpty) {
        blankWarnings.add(l10n.cardNMissingField(i + 1, l10n.definitionInput));
      }
      if (term.isNotEmpty || def.isNotEmpty) {
        draftRows.add((
          rowNumber: i + 1,
          id: _cardIds[i],
          term: term,
          definition: def,
          example: _exampleControllers[i].text.trim(),
          imageUrl: _imageUrls[i],
          tags: List<String>.from(_tags[i]),
        ));
      }
    }

    var shouldMergeSameTerm = false;
    final multiMeaningGroups = _sameTermDifferentDefinitionGroupsForSave(
      draftRows,
    );
    if (multiMeaningGroups.isNotEmpty) {
      shouldMergeSameTerm = await _confirmMergeSameTermGroups(
        groups: multiMeaningGroups
            .map((g) => (displayTerm: g.displayTerm, rowNumbers: g.rowNumbers))
            .toList(),
        beforeSave: true,
      );
      if (!mounted) return;
    }

    // Check duplicates only among rows that will actually be saved.
    final rowsToSave = shouldMergeSameTerm
        ? <({int rowNumber, String term})>[
            for (final g
                in draftRows.fold<Map<String, ({int rowNumber, String term})>>(
                  {},
                  (acc, row) {
                    final key = _normalizeTerm(row.term);
                    if (key.isEmpty) return acc;
                    acc.putIfAbsent(
                      key,
                      () => (rowNumber: row.rowNumber, term: row.term),
                    );
                    return acc;
                  },
                ).values)
              g,
          ]
        : <({int rowNumber, String term})>[
            for (final row in draftRows)
              (rowNumber: row.rowNumber, term: row.term),
          ];
    for (var i = 0; i < rowsToSave.length; i++) {
      final termI = rowsToSave[i].term.toLowerCase();
      if (termI.isEmpty) continue;
      for (var j = i + 1; j < rowsToSave.length; j++) {
        final termJ = rowsToSave[j].term.toLowerCase();
        if (termI == termJ) {
          duplicateWarnings.add(
            l10n.cardsAreDuplicates(
              rowsToSave[i].rowNumber,
              rowsToSave[j].rowNumber,
            ),
          );
        }
      }
    }

    if (blankWarnings.isNotEmpty || duplicateWarnings.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => SaveWarningDialog(
          blankWarnings: blankWarnings,
          duplicateWarnings: duplicateWarnings,
        ),
      );
      if (proceed != true) return;
    }

    final cards = <Flashcard>[];
    if (shouldMergeSameTerm) {
      final grouped =
          <
            String,
            List<
              ({
                int rowNumber,
                String id,
                String term,
                String definition,
                String example,
                String imageUrl,
                List<String> tags,
              })
            >
          >{};
      for (final row in draftRows) {
        final key = _normalizeTerm(row.term);
        grouped
            .putIfAbsent(key.isEmpty ? '__row_${row.rowNumber}' : key, () => [])
            .add(row);
      }
      final orderedGroups = grouped.values.toList()
        ..sort((a, b) => a.first.rowNumber.compareTo(b.first.rowNumber));
      for (final rows in orderedGroups) {
        rows.sort((a, b) => a.rowNumber.compareTo(b.rowNumber));
        final base = rows.first;
        final defs = _mergeUniqueTextParts(rows.map((r) => r.definition));
        final examples = _mergeUniqueTextParts(rows.map((r) => r.example));
        final tags = <String>[];
        final seenTagKeys = <String>{};
        for (final row in rows) {
          for (final tag in row.tags) {
            final key = tag.trim().toLowerCase();
            if (key.isEmpty) continue;
            if (seenTagKeys.add(key)) tags.add(tag);
          }
        }
        final imageUrl = rows
            .map((r) => r.imageUrl.trim())
            .firstWhere((v) => v.isNotEmpty, orElse: () => '');
        cards.add(
          Flashcard(
            id: base.id,
            term: base.term,
            definition: defs.join('\n'),
            exampleSentence: examples.join('\n'),
            imageUrl: imageUrl,
            tags: tags,
          ),
        );
      }
    } else {
      for (final row in draftRows) {
        cards.add(
          Flashcard(
            id: row.id,
            term: row.term,
            definition: row.definition,
            exampleSentence: row.example,
            imageUrl: row.imageUrl,
            tags: row.tags,
          ),
        );
      }
    }

    await ref
        .read(studySetsProvider.notifier)
        .update(studySet.copyWith(cards: cards));

    if (!mounted) return;
    AppFeedbackToast.show(
      context,
      message: l10n.savedNCards(cards.length),
      tone: AppToastTone.success,
    );
    context.pop();
  }

  bool get _hasUnsavedChanges => _history.canUndo;

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges) return true;
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.unsavedChanges),
        content: Text(l10n.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: Text(l10n.discard),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (result == 'save') {
      await _save();
      return false; // _save already pops
    }
    return result == 'discard';
  }

  List<int> get _filteredIndices {
    if (_searchQuery.isEmpty) {
      return List.generate(_termControllers.length, (i) => i);
    }
    final q = _searchQuery.toLowerCase();
    return [
      for (var i = 0; i < _termControllers.length; i++)
        if (_termControllers[i].text.toLowerCase().contains(q) ||
            _defControllers[i].text.toLowerCase().contains(q))
          i,
    ];
  }

  int get _effectivePageSize => _pageSize <= 0 ? 1000000 : _pageSize;

  Map<int, List<String>> get _quickIssueLabelsByIndex {
    final labels = <int, List<String>>{};
    final termGroups = <String, List<int>>{};
    final defGroupsByTerm = <String, Set<String>>{};
    for (var i = 0; i < _termControllers.length; i++) {
      final term = _termControllers[i].text.trim();
      final def = _defControllers[i].text.trim();
      if (term.isNotEmpty || def.isNotEmpty) {
        final rowLabels = labels.putIfAbsent(i, () => <String>[]);
        if (term.isEmpty || def.isEmpty) rowLabels.add('缺欄位');
      }
      final termKey = _normalizeTerm(term);
      if (termKey.isEmpty) continue;
      termGroups.putIfAbsent(termKey, () => <int>[]).add(i);
      defGroupsByTerm.putIfAbsent(termKey, () => <String>{});
      final defKey = _normalizeDefinition(def);
      if (defKey.isNotEmpty) {
        defGroupsByTerm[termKey]!.add(defKey);
      }
    }

    for (final entry in termGroups.entries) {
      if (entry.value.length >= 2) {
        final hasMultiMeaning = (defGroupsByTerm[entry.key]?.length ?? 0) >= 2;
        for (final i in entry.value) {
          final rowLabels = labels.putIfAbsent(i, () => <String>[]);
          rowLabels.add(hasMultiMeaning ? '可合併' : '重複詞');
        }
      }
    }
    return labels;
  }

  int _clampedPageIndexForCount(int count) {
    final pageCount = count == 0 ? 1 : ((count - 1) ~/ _effectivePageSize) + 1;
    return _pageIndex.clamp(0, pageCount - 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final issueLabelsByIndex = _quickIssueLabelsByIndex;
    var filteredIndices = _filteredIndices;
    if (_viewMode == _EditorViewMode.quick && _quickIssuesOnly) {
      filteredIndices = [
        for (final i in filteredIndices)
          if ((issueLabelsByIndex[i]?.isNotEmpty ?? false)) i,
      ];
    }
    final pageIndex = _clampedPageIndexForCount(filteredIndices.length);
    final pageCount = filteredIndices.isEmpty
        ? 1
        : ((filteredIndices.length - 1) ~/ _effectivePageSize) + 1;
    final start = pageIndex * _effectivePageSize;
    final end = (start + _effectivePageSize).clamp(0, filteredIndices.length);
    final visibleIndices = filteredIndices.sublist(start, end);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (shouldPop && mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: AppBackButton(
            onPressed: () async {
              final shouldPop = await _confirmDiscard();
              if (shouldPop && mounted) context.pop();
            },
          ),
          title: Text(l10n.editCards),
          actions: [
            if (_history.canUndo)
              IconButton(
                onPressed: _undo,
                icon: const Icon(Icons.undo),
                tooltip: l10n.undoAction,
              ),
            if (_history.canRedo)
              IconButton(
                onPressed: _redo,
                icon: const Icon(Icons.redo),
                tooltip: l10n.redoAction,
              ),
            IconButton(
              onPressed: _toggleSelectMode,
              icon: Icon(_selectMode ? Icons.close : Icons.checklist_rounded),
              tooltip: l10n.selectMode,
            ),
            if (_selectMode)
              IconButton(
                onPressed: _selectAllOrNone,
                icon: Icon(
                  _selectedIndices.length == _termControllers.length
                      ? Icons.deselect
                      : Icons.select_all,
                ),
                tooltip: _selectedIndices.length == _termControllers.length
                    ? l10n.deselectAll
                    : l10n.selectAll,
              ),
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(l10n.save),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchCards,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _pageIndex = 0;
                            });
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                onChanged: (v) => setState(() {
                  _searchQuery = v.trim();
                  _pageIndex = 0;
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  SegmentedButton<_EditorViewMode>(
                    segments: const [
                      ButtonSegment(
                        value: _EditorViewMode.detailed,
                        icon: Icon(Icons.view_agenda_outlined, size: 18),
                        label: Text('精編'),
                      ),
                      ButtonSegment(
                        value: _EditorViewMode.quick,
                        icon: Icon(Icons.view_headline_rounded, size: 18),
                        label: Text('快修'),
                      ),
                    ],
                    selected: {_viewMode},
                    onSelectionChanged: (values) => setState(() {
                      _viewMode = values.first;
                      _pageIndex = 0;
                    }),
                  ),
                  const Spacer(),
                  if (_viewMode == _EditorViewMode.quick)
                    FilterChip(
                      label: const Text('只看有問題'),
                      selected: _quickIssuesOnly,
                      onSelected: (v) => setState(() {
                        _quickIssuesOnly = v;
                        _pageIndex = 0;
                      }),
                    ),
                  if (_viewMode == _EditorViewMode.quick) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _jumpToCardDialog,
                      icon: const Icon(Icons.pin_drop_outlined, size: 16),
                      label: const Text('跳卡號'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
                spacing: 8,
                children: [
                  Text(
                    '顯示 ${filteredIndices.isEmpty ? 0 : start + 1}-${end} / ${filteredIndices.length}（總共 ${_termControllers.length} 張）',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<int>(
                        tooltip: '每頁張數',
                        onSelected: (value) => setState(() {
                          _pageSize = value;
                          _pageIndex = 0;
                        }),
                        itemBuilder: (ctx) => const [
                          PopupMenuItem(value: 20, child: Text('每頁 20')),
                          PopupMenuItem(value: 30, child: Text('每頁 30')),
                          PopupMenuItem(value: 50, child: Text('每頁 50')),
                          PopupMenuItem(value: 100, child: Text('每頁 100')),
                          PopupMenuItem(value: -1, child: Text('全部顯示')),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _pageSize <= 0 ? '全部' : '每頁 $_pageSize',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: pageIndex > 0
                            ? () => setState(() => _pageIndex = pageIndex - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                        tooltip: '上一頁',
                      ),
                      Text(
                        '${filteredIndices.isEmpty ? 0 : pageIndex + 1}/$pageCount',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: pageIndex + 1 < pageCount
                            ? () => setState(() => _pageIndex = pageIndex + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                        tooltip: '下一頁',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: visibleIndices.length,
                itemBuilder: (context, vi) {
                  final index = visibleIndices[vi];
                  if (_viewMode == _EditorViewMode.quick) {
                    return QuickCardEditRow(
                      key: ValueKey(
                        'quick_card_${_cardIds[index]}_$_rebuildKey',
                      ),
                      index: index,
                      termController: _termControllers[index],
                      definitionController: _defControllers[index],
                      exampleSentenceController: _exampleControllers[index],
                      imageUrl: _imageUrls[index],
                      tags: _tags[index],
                      issueLabels: issueLabelsByIndex[index] ?? const [],
                      expanded: _quickExpandedRows.contains(index),
                      onToggleExpanded: () => setState(() {
                        if (_quickExpandedRows.contains(index)) {
                          _quickExpandedRows.remove(index);
                        } else {
                          _quickExpandedRows.add(index);
                        }
                      }),
                      onAutoImage: () => _autoImage(index),
                      onEditImage: () => _editImageUrl(index),
                      onClearImage: () => _clearImage(index),
                      onAddTag: (tag) {
                        setState(() {
                          if (!_tags[index].contains(tag)) {
                            _tags[index].add(tag);
                          }
                        });
                      },
                      onRemoveTag: (tag) {
                        setState(() => _tags[index].remove(tag));
                      },
                      onDelete: () => _deleteOneCardWithConfirm(index),
                      isSelected: _selectedIndices.contains(index),
                      onSelectionChanged: _selectMode
                          ? (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedIndices.add(index);
                                } else {
                                  _selectedIndices.remove(index);
                                }
                              });
                            }
                          : null,
                    );
                  }
                  return CardEditRow(
                    key: ValueKey('card_${_cardIds[index]}_$_rebuildKey'),
                    index: index,
                    termController: _termControllers[index],
                    definitionController: _defControllers[index],
                    exampleSentenceController: _exampleControllers[index],
                    imageUrl: _imageUrls[index],
                    tags: _tags[index],
                    onDelete: () => _deleteOneCardWithConfirm(index),
                    onAutoImage: () => _autoImage(index),
                    onEditImage: () => _editImageUrl(index),
                    onClearImage: () => _clearImage(index),
                    onAddTag: (tag) {
                      setState(() {
                        if (!_tags[index].contains(tag)) {
                          _tags[index].add(tag);
                        }
                      });
                    },
                    onRemoveTag: (tag) {
                      setState(() => _tags[index].remove(tag));
                    },
                    isSelected: _selectedIndices.contains(index),
                    onSelectionChanged: _selectMode
                        ? (val) {
                            setState(() {
                              if (val == true) {
                                _selectedIndices.add(index);
                              } else {
                                _selectedIndices.remove(index);
                              }
                            });
                          }
                        : null,
                  );
                },
              ),
            ),
            if (_selectMode && _selectedIndices.isNotEmpty)
              BatchEditBar(
                selectedCount: _selectedIndices.length,
                onDelete: _deleteSelected,
                onMerge: _mergeSelectedSameTermCards,
                onAddTag: _addTagToSelected,
                onRemoveTag: _removeTagFromSelected,
                onAiGenerate: _generateAiExamples,
              ),
          ],
        ),
        floatingActionButton: _selectMode
            ? null
            : FloatingActionButton(
                onPressed: _addEmptyCard,
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}

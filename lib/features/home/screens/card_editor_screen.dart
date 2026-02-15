import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/features/home/widgets/card_edit_row.dart';
import 'package:recall_app/features/home/widgets/batch_edit_bar.dart';
import 'package:recall_app/features/home/widgets/save_warning_dialog.dart';
import 'package:recall_app/features/home/utils/editor_history.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/services/unsplash_service.dart';

class CardEditorScreen extends ConsumerStatefulWidget {
  final String setId;

  const CardEditorScreen({super.key, required this.setId});

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

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

  @override
  void initState() {
    super.initState();
    final studySet =
        ref.read(studySetsProvider.notifier).getById(widget.setId);
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
    }

    _addListenersToAll();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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
    return List.generate(_termControllers.length, (i) => CardSnapshot(
      id: _cardIds[i],
      term: _termControllers[i].text,
      definition: _defControllers[i].text,
      example: _exampleControllers[i].text,
      imageUrl: _imageUrls[i],
      tags: List<String>.from(_tags[i]),
    ));
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

  void _addEmptyCard() {
    _history.pushState(_currentSnapshot());
    setState(() {
      _addCardControllers();
      final i = _termControllers.length - 1;
      _termControllers[i].addListener(_onTextChanged);
      _defControllers[i].addListener(_onTextChanged);
      _exampleControllers[i].addListener(_onTextChanged);
    });
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

  Future<void> _autoImage(int index) async {
    final term = _termControllers[index].text.trim();
    if (term.isEmpty) return;
    final url = await UnsplashService().searchPhoto(term);
    if (url.isNotEmpty && mounted) {
      setState(() => _imageUrls[index] = url);
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
            List.generate(_termControllers.length, (i) => i));
      }
    });
  }

  void _deleteSelected() {
    if (_selectedIndices.isEmpty) return;
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
        children: allTags.map((tag) => SimpleDialogOption(
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
        )).toList(),
      ),
    );
  }

  // -- Save with validation --

  Future<void> _save() async {
    final studySet =
        ref.read(studySetsProvider.notifier).getById(widget.setId);
    if (studySet == null) return;

    final l10n = AppLocalizations.of(context);
    final blankWarnings = <String>[];
    final duplicateWarnings = <String>[];

    // Check blanks
    for (var i = 0; i < _termControllers.length; i++) {
      final term = _termControllers[i].text.trim();
      final def = _defControllers[i].text.trim();
      if (term.isEmpty && def.isNotEmpty) {
        blankWarnings.add(l10n.cardNMissingField(i + 1, l10n.termLabel));
      } else if (term.isNotEmpty && def.isEmpty) {
        blankWarnings.add(l10n.cardNMissingField(i + 1, l10n.definitionInput));
      }
    }

    // Check duplicates
    for (var i = 0; i < _termControllers.length; i++) {
      final termI = _termControllers[i].text.trim().toLowerCase();
      if (termI.isEmpty) continue;
      for (var j = i + 1; j < _termControllers.length; j++) {
        final termJ = _termControllers[j].text.trim().toLowerCase();
        if (termI == termJ) {
          duplicateWarnings.add(l10n.cardsAreDuplicates(i + 1, j + 1));
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
    for (var i = 0; i < _termControllers.length; i++) {
      final term = _termControllers[i].text.trim();
      final def = _defControllers[i].text.trim();
      final example = _exampleControllers[i].text.trim();
      if (term.isNotEmpty || def.isNotEmpty) {
        cards.add(Flashcard(
          id: _cardIds[i],
          term: term,
          definition: def,
          exampleSentence: example,
          imageUrl: _imageUrls[i],
          tags: _tags[i],
        ));
      }
    }

    ref
        .read(studySetsProvider.notifier)
        .update(studySet.copyWith(cards: cards));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.savedNCards(cards.length))),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
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
            icon: Icon(_selectMode
                ? Icons.close
                : Icons.checklist_rounded),
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: _termControllers.length,
              itemBuilder: (context, index) {
                return CardEditRow(
                  key: ValueKey('card_${_cardIds[index]}_$_rebuildKey'),
                  index: index,
                  termController: _termControllers[index],
                  definitionController: _defControllers[index],
                  exampleSentenceController: _exampleControllers[index],
                  imageUrl: _imageUrls[index],
                  tags: _tags[index],
                  onDelete: () => _removeCard(index),
                  onAutoImage: () => _autoImage(index),
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
              onAddTag: _addTagToSelected,
              onRemoveTag: _removeTagFromSelected,
            ),
        ],
      ),
      floatingActionButton: _selectMode
          ? null
          : FloatingActionButton(
              onPressed: _addEmptyCard,
              child: const Icon(Icons.add),
            ),
    );
  }
}

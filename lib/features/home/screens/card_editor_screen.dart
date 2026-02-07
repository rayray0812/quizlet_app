import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/features/home/widgets/card_edit_row.dart';
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

  @override
  void initState() {
    super.initState();
    final studySet =
        ref.read(studySetsProvider.notifier).getById(widget.setId);
    if (studySet != null) {
      for (final card in studySet.cards) {
        _termControllers.add(TextEditingController(text: card.term));
        _defControllers.add(TextEditingController(text: card.definition));
        _exampleControllers.add(
          TextEditingController(text: card.exampleSentence),
        );
        _cardIds.add(card.id);
        _imageUrls.add(card.imageUrl);
        _tags.add(List<String>.from(card.tags));
      }
    }
    // Start with one empty card if set has none
    if (_termControllers.isEmpty) {
      _addEmptyCard();
    }
  }

  @override
  void dispose() {
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

  void _addEmptyCard() {
    setState(() {
      _termControllers.add(TextEditingController());
      _defControllers.add(TextEditingController());
      _exampleControllers.add(TextEditingController());
      _cardIds.add(const Uuid().v4());
      _imageUrls.add('');
      _tags.add([]);
    });
  }

  void _removeCard(int index) {
    setState(() {
      _termControllers[index].dispose();
      _defControllers[index].dispose();
      _exampleControllers[index].dispose();
      _termControllers.removeAt(index);
      _defControllers.removeAt(index);
      _exampleControllers.removeAt(index);
      _cardIds.removeAt(index);
      _imageUrls.removeAt(index);
      _tags.removeAt(index);
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

  void _save() {
    final studySet =
        ref.read(studySetsProvider.notifier).getById(widget.setId);
    if (studySet == null) return;

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

    final l10n = AppLocalizations.of(context);
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
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEmptyCard,
        child: const Icon(Icons.add),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:quizlet_app/models/flashcard.dart';
import 'package:quizlet_app/providers/study_set_provider.dart';
import 'package:quizlet_app/features/home/widgets/card_edit_row.dart';

class CardEditorScreen extends ConsumerStatefulWidget {
  final String setId;

  const CardEditorScreen({super.key, required this.setId});

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends ConsumerState<CardEditorScreen> {
  final List<TextEditingController> _termControllers = [];
  final List<TextEditingController> _defControllers = [];
  final List<String> _cardIds = [];

  @override
  void initState() {
    super.initState();
    final studySet =
        ref.read(studySetsProvider.notifier).getById(widget.setId);
    if (studySet != null) {
      for (final card in studySet.cards) {
        _termControllers.add(TextEditingController(text: card.term));
        _defControllers.add(TextEditingController(text: card.definition));
        _cardIds.add(card.id);
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
    super.dispose();
  }

  void _addEmptyCard() {
    setState(() {
      _termControllers.add(TextEditingController());
      _defControllers.add(TextEditingController());
      _cardIds.add(const Uuid().v4());
    });
  }

  void _removeCard(int index) {
    setState(() {
      _termControllers[index].dispose();
      _defControllers[index].dispose();
      _termControllers.removeAt(index);
      _defControllers.removeAt(index);
      _cardIds.removeAt(index);
    });
  }

  void _save() {
    final studySet =
        ref.read(studySetsProvider.notifier).getById(widget.setId);
    if (studySet == null) return;

    final cards = <Flashcard>[];
    for (var i = 0; i < _termControllers.length; i++) {
      final term = _termControllers[i].text.trim();
      final def = _defControllers[i].text.trim();
      if (term.isNotEmpty || def.isNotEmpty) {
        cards.add(Flashcard(
          id: _cardIds[i],
          term: term,
          definition: def,
        ));
      }
    }

    ref
        .read(studySetsProvider.notifier)
        .update(studySet.copyWith(cards: cards));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved ${cards.length} cards')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Cards'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Save'),
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
                  onDelete: () => _removeCard(index),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizlet_app/models/study_set.dart';
import 'package:quizlet_app/models/flashcard.dart';
import 'package:quizlet_app/providers/study_set_provider.dart';
import 'package:quizlet_app/features/import/widgets/import_preview_card.dart';

class ReviewImportScreen extends ConsumerStatefulWidget {
  final StudySet studySet;

  const ReviewImportScreen({super.key, required this.studySet});

  @override
  ConsumerState<ReviewImportScreen> createState() => _ReviewImportScreenState();
}

class _ReviewImportScreenState extends ConsumerState<ReviewImportScreen> {
  late TextEditingController _titleController;
  late List<Flashcard> _cards;

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

  void _removeCard(int index) {
    setState(() => _cards.removeAt(index));
  }

  void _save() {
    if (_cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one card')),
      );
      return;
    }

    final updatedSet = widget.studySet.copyWith(
      title: _titleController.text.trim().isEmpty
          ? 'Imported Set'
          : _titleController.text.trim(),
      cards: _cards,
    );

    ref.read(studySetsProvider.notifier).add(updatedSet);
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Import'),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Set Title',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_cards.length} cards',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                return ImportPreviewCard(
                  flashcard: _cards[index],
                  index: index,
                  onDelete: () => _removeCard(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/features/import/widgets/import_preview_card.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/app_back_button.dart';

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
              decoration: const InputDecoration(
                labelText: 'Set Title',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  onDelete: () {
                    _removeCard(index);
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


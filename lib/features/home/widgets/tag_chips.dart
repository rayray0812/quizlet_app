import 'package:flutter/material.dart';

/// Displays tags as chips with optional add/remove capability.
class TagChips extends StatelessWidget {
  final List<String> tags;
  final bool editable;
  final void Function(String tag)? onAdd;
  final void Function(String tag)? onRemove;

  const TagChips({
    super.key,
    required this.tags,
    this.editable = false,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        ...tags.map((tag) => Chip(
              label: Text(tag, style: const TextStyle(fontSize: 12)),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              deleteIcon: editable
                  ? const Icon(Icons.close, size: 14)
                  : null,
              onDeleted: editable && onRemove != null
                  ? () => onRemove!(tag)
                  : null,
            )),
        if (editable && onAdd != null)
          ActionChip(
            label: const Icon(Icons.add, size: 16),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            onPressed: () => _showAddTagDialog(context),
          ),
      ],
    );
  }

  void _showAddTagDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tag name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final tag = value.trim();
            if (tag.isNotEmpty) {
              onAdd!(tag);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final tag = controller.text.trim();
              if (tag.isNotEmpty) {
                onAdd!(tag);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

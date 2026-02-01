import 'package:flutter/material.dart';

class CardEditRow extends StatelessWidget {
  final int index;
  final TextEditingController termController;
  final TextEditingController definitionController;
  final VoidCallback onDelete;

  const CardEditRow({
    super.key,
    required this.index,
    required this.termController,
    required this.definitionController,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${index + 1}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Delete card',
                ),
              ],
            ),
            TextField(
              controller: termController,
              decoration: const InputDecoration(
                labelText: 'Term',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: definitionController,
              decoration: const InputDecoration(
                labelText: 'Definition',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textInputAction: TextInputAction.next,
              maxLines: null,
            ),
          ],
        ),
      ),
    );
  }
}

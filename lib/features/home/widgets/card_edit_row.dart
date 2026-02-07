import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:recall_app/features/home/widgets/tag_chips.dart';

class CardEditRow extends StatelessWidget {
  final int index;
  final TextEditingController termController;
  final TextEditingController definitionController;
  final TextEditingController? exampleSentenceController;
  final String imageUrl;
  final List<String> tags;
  final VoidCallback onDelete;
  final VoidCallback? onAutoImage;
  final void Function(String tag)? onAddTag;
  final void Function(String tag)? onRemoveTag;

  const CardEditRow({
    super.key,
    required this.index,
    required this.termController,
    required this.definitionController,
    this.exampleSentenceController,
    this.imageUrl = '',
    this.tags = const [],
    required this.onDelete,
    this.onAutoImage,
    this.onAddTag,
    this.onRemoveTag,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: number + actions
            Row(
              children: [
                Text(
                  '#${index + 1}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const Spacer(),
                if (onAutoImage != null)
                  IconButton(
                    onPressed: onAutoImage,
                    icon: Icon(
                      Icons.image_search,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: 'Auto Image',
                    visualDensity: VisualDensity.compact,
                  ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Delete card',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            // Image thumbnail
            if (imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),

            // Term field
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextField(
                controller: termController,
                decoration: const InputDecoration(
                  labelText: 'Term',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(height: 14),

            // Definition field
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextField(
                controller: definitionController,
                decoration: const InputDecoration(
                  labelText: 'Definition',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                maxLines: null,
              ),
            ),
            if (exampleSentenceController != null) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextField(
                  controller: exampleSentenceController,
                  decoration: const InputDecoration(
                    labelText: 'Example sentence',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  maxLines: null,
                ),
              ),
            ],

            // Tags
            if (onAddTag != null) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TagChips(
                  tags: tags,
                  editable: true,
                  onAdd: onAddTag,
                  onRemove: onRemoveTag,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


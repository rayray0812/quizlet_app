import 'dart:math';
import 'package:flutter/material.dart';

/// Shows a dialog for picking the number of questions/pairs.
/// Returns the selected count, or null if dismissed.
Future<int?> showCountPickerDialog({
  required BuildContext context,
  required int maxCount,
  int minCount = 2,
  int? defaultCount,
  String label = 'items',
}) {
  return showDialog<int>(
    context: context,
    builder: (context) => _CountPickerDialog(
      maxCount: maxCount,
      minCount: minCount,
      initialCount: defaultCount ?? min(10, maxCount),
      label: label,
    ),
  );
}

class _CountPickerDialog extends StatefulWidget {
  final int maxCount;
  final int minCount;
  final int initialCount;
  final String label;

  const _CountPickerDialog({
    required this.maxCount,
    required this.minCount,
    required this.initialCount,
    required this.label,
  });

  @override
  State<_CountPickerDialog> createState() => _CountPickerDialogState();
}

class _CountPickerDialogState extends State<_CountPickerDialog> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.initialCount.clamp(widget.minCount, widget.maxCount);
  }

  @override
  Widget build(BuildContext context) {
    final presets = [5, 10, 20].where((n) => n <= widget.maxCount && n >= widget.minCount).toList();

    return AlertDialog(
      title: Text('How many ${widget.label}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_count',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Slider(
            value: _count.toDouble(),
            min: widget.minCount.toDouble(),
            max: widget.maxCount.toDouble(),
            divisions: max(1, widget.maxCount - widget.minCount),
            onChanged: (v) => setState(() => _count = v.round()),
          ),
          Wrap(
            spacing: 8,
            children: [
              ...presets.map((n) => ActionChip(
                    label: Text('$n'),
                    onPressed: () => setState(() => _count = n),
                  )),
              ActionChip(
                label: const Text('All'),
                onPressed: () =>
                    setState(() => _count = widget.maxCount),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _count),
          child: const Text('Start'),
        ),
      ],
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quizlet_app/core/l10n/app_localizations.dart';

/// Shows a dialog for picking the number of questions.
/// Returns the selected count, or null if dismissed.
Future<int?> showCountPickerDialog({
  required BuildContext context,
  required int maxCount,
  int minCount = 2,
  int? defaultCount,
}) {
  return showDialog<int>(
    context: context,
    builder: (context) => _CountPickerDialog(
      maxCount: maxCount,
      minCount: minCount,
      initialCount: defaultCount ?? min(10, maxCount),
    ),
  );
}

class _CountPickerDialog extends StatefulWidget {
  final int maxCount;
  final int minCount;
  final int initialCount;

  const _CountPickerDialog({
    required this.maxCount,
    required this.minCount,
    required this.initialCount,
  });

  @override
  State<_CountPickerDialog> createState() => _CountPickerDialogState();
}

class _CountPickerDialogState extends State<_CountPickerDialog> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    final initial =
        widget.initialCount.clamp(widget.minCount, widget.maxCount);
    _textController = TextEditingController(text: '$initial');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  int get _parsedCount {
    final v = int.tryParse(_textController.text) ?? widget.minCount;
    return v.clamp(widget.minCount, widget.maxCount);
  }

  void _setCount(int n) {
    _textController.text = '$n';
    _textController.selection =
        TextSelection.collapsed(offset: _textController.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final presets = [5, 10, 20]
        .where((n) => n <= widget.maxCount && n >= widget.minCount)
        .toList();

    return AlertDialog(
      title: Text(l10n.howMany),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          SizedBox(
            width: 120,
            child: TextField(
              controller: _textController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
              decoration: InputDecoration(
                hintText: '${widget.minCount}–${widget.maxCount}',
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ...presets.map((n) => ActionChip(
                    label: Text('$n'),
                    onPressed: () => _setCount(n),
                  )),
              ActionChip(
                label: Text(l10n.allTerms),
                onPressed: () => _setCount(widget.maxCount),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _parsedCount),
          child: Text(l10n.start),
        ),
      ],
    );
  }
}

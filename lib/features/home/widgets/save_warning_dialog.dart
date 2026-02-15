import 'package:flutter/material.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';

class SaveWarningDialog extends StatelessWidget {
  final List<String> blankWarnings;
  final List<String> duplicateWarnings;

  const SaveWarningDialog({
    super.key,
    this.blankWarnings = const [],
    this.duplicateWarnings = const [],
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              blankWarnings.isNotEmpty
                  ? l10n.blankWarning
                  : l10n.duplicateWarning,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (blankWarnings.isNotEmpty) ...[
              Text(
                l10n.blankWarning,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              for (final w in blankWarnings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '\u2022 $w',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
            if (blankWarnings.isNotEmpty && duplicateWarnings.isNotEmpty)
              const SizedBox(height: 12),
            if (duplicateWarnings.isNotEmpty) ...[
              Text(
                l10n.duplicateWarning,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              for (final w in duplicateWarnings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '\u2022 $w',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.goBackToFix),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.saveAnyway),
        ),
      ],
    );
  }
}

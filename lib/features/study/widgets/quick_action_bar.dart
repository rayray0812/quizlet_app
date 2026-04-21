import 'package:flutter/material.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';

class QuickActionBar extends StatelessWidget {
  final ValueChanged<String> onAction;
  final bool enabled;

  const QuickActionBar({
    super.key,
    required this.onAction,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _chip(context, Icons.replay_rounded, l10n.repeatPlease,
              'Can you repeat that?'),
          const SizedBox(width: 8),
          _chip(context, Icons.short_text_rounded, l10n.speakSimpler,
              'Can you say that in simpler words?'),
          const SizedBox(width: 8),
          _chip(context, Icons.lightbulb_outline_rounded, l10n.giveHint,
              'Can you give me a hint?'),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    IconData icon,
    String label,
    String message,
  ) {
    return Expanded(
      child: ActionChip(
        avatar: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: enabled ? () => onAction(message) : null,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

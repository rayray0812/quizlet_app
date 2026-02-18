import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/widgets/app_back_button.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/core/theme/app_theme.dart';

class ConversationSetupScreen extends ConsumerStatefulWidget {
  final String setId;

  const ConversationSetupScreen({super.key, required this.setId});

  @override
  ConsumerState<ConversationSetupScreen> createState() =>
      _ConversationSetupScreenState();
}

class _ConversationSetupScreenState
    extends ConsumerState<ConversationSetupScreen> {
  int _turns = 5;
  String _difficulty = 'medium'; // easy, medium, hard

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final studySet = ref
        .watch(studySetsProvider.notifier)
        .getById(widget.setId);

    if (studySet == null) {
      return Scaffold(
        appBar: AppBar(leading: const AppBackButton()),
        body: Center(child: Text(l10n.studySetNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.conversationPractice),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle(l10n.turns, context),
            const SizedBox(height: 12),
            _buildTurnOption(3, l10n),
            _buildTurnOption(5, l10n),
            _buildTurnOption(10, l10n),
            _buildTurnOption(20, l10n),
            const SizedBox(height: 24),
            _buildSectionTitle(l10n.difficulty, context),
            const SizedBox(height: 12),
            _buildDifficultyOption('easy', l10n.easy, l10n.difficultyEasyDesc),
            _buildDifficultyOption('medium', l10n.medium, l10n.difficultyMediumDesc),
            _buildDifficultyOption('hard', l10n.hard, l10n.difficultyHardDesc),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: () {
                context.push(
                  '/study/${widget.setId}/conversation/practice',
                  extra: {
                    'turns': _turns,
                    'difficulty': _difficulty,
                  },
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.startConversation, style: const TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildTurnOption(int count, AppLocalizations l10n) {
    final isSelected = _turns == count;
    return RadioListTile<int>(
      title: Text(l10n.nTurns(count)),
      value: count,
      groupValue: _turns,
      onChanged: (val) => setState(() => _turns = val!),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: EdgeInsets.zero,
      activeColor: AppTheme.indigo,
      selected: isSelected,
    );
  }

  Widget _buildDifficultyOption(
    String value,
    String label,
    String description,
  ) {
    final isSelected = _difficulty == value;
    return RadioListTile<String>(
      title: Text(label),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      value: value,
      groupValue: _difficulty,
      onChanged: (val) => setState(() => _difficulty = val!),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: EdgeInsets.zero,
      activeColor: AppTheme.indigo,
      selected: isSelected,
    );
  }

}

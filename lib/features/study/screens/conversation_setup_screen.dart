import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/widgets/app_back_button.dart';
import 'package:recall_app/features/study/data/conversation_scenarios.dart';
import 'package:recall_app/features/study/widgets/scenario_preview_card.dart';
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
  String? _selectedScenarioId; // null = random

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
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: l10n.viewHistory,
            onPressed: () => context.push('/conversation/history'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scenario selector
            _buildSectionTitle(l10n.selectScenario, context),
            const SizedBox(height: 12),
            _buildScenarioSelector(l10n),
            const SizedBox(height: 24),
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
                    'scenarioId': _selectedScenarioId,
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

  Widget _buildScenarioSelector(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kConversationScenarios.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            // "Random" option
            final isSelected = _selectedScenarioId == null;
            return GestureDetector(
              onTap: () => setState(() => _selectedScenarioId = null),
              child: Container(
                width: 120,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shuffle_rounded,
                      size: 32,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.randomScenario,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          final scenario = kConversationScenarios[index - 1];
          return ScenarioPreviewCard(
            scenario: scenario,
            isSelected: _selectedScenarioId == scenario.id,
            onTap: () => setState(() => _selectedScenarioId = scenario.id),
          );
        },
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

import 'package:flutter/material.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/features/study/screens/quiz_screen.dart';

/// Shows a dialog for configuring quiz settings.
///
/// Returns a [QuizSettings] object or null if cancelled.
Future<QuizSettings?> showQuizSettingsDialog({
  required BuildContext context,
  required int maxCount,
  int minCount = 4,
}) {
  return showModalBottomSheet<QuizSettings>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _QuizSettingsSheet(
      maxCount: maxCount,
      minCount: minCount,
    ),
  );
}

class _QuizSettingsSheet extends StatefulWidget {
  final int maxCount;
  final int minCount;

  const _QuizSettingsSheet({
    required this.maxCount,
    required this.minCount,
  });

  @override
  State<_QuizSettingsSheet> createState() => _QuizSettingsSheetState();
}

class _QuizSettingsSheetState extends State<_QuizSettingsSheet> {
  late final TextEditingController _countController;
  late int _count;
  Set<QuizQuestionType> _enabledTypes = {
    QuizQuestionType.multipleChoice,
    QuizQuestionType.textInput,
    QuizQuestionType.trueFalse,
  };
  QuizDirection _direction = QuizDirection.termToDef;
  bool _prioritizeWeak = false;

  @override
  void initState() {
    super.initState();
    _count = widget.maxCount.clamp(widget.minCount, widget.maxCount);
    _countController = TextEditingController(text: '$_count');
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  void _setCount(int value) {
    final clamped = value.clamp(widget.minCount, widget.maxCount);
    setState(() => _count = clamped);
    _countController.text = '$clamped';
    _countController.selection = TextSelection.collapsed(
      offset: _countController.text.length,
    );
  }

  void _onCountFieldChanged(String text) {
    final parsed = int.tryParse(text);
    if (parsed != null) {
      setState(() => _count = parsed.clamp(widget.minCount, widget.maxCount));
    }
  }

  void _toggleType(QuizQuestionType type) {
    setState(() {
      if (_enabledTypes.contains(type)) {
        if (_enabledTypes.length > 1) {
          _enabledTypes = Set.of(_enabledTypes)..remove(type);
        }
      } else {
        _enabledTypes = Set.of(_enabledTypes)..add(type);
      }
    });
  }

  void _confirm() {
    if (_enabledTypes.isEmpty) return;
    Navigator.pop(
      context,
      QuizSettings(
        questionCount: _count,
        enabledTypes: _enabledTypes,
        direction: _direction,
        prioritizeWeakCards: _prioritizeWeak,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                l10n.quizSettings,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),

              // -- Question count --
              _SectionLabel(label: l10n.howMany),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 36,
                    child: TextField(
                      controller: _countController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      onChanged: _onCountFieldChanged,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  ..._buildQuickButtons(),
                ],
              ),

              const SizedBox(height: 28),

              // -- Question types --
              _SectionLabel(label: l10n.questionTypes),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _TypeChip(
                    label: l10n.multipleChoice,
                    icon: Icons.list_rounded,
                    selected: _enabledTypes.contains(QuizQuestionType.multipleChoice),
                    onTap: () => _toggleType(QuizQuestionType.multipleChoice),
                  ),
                  _TypeChip(
                    label: l10n.trueFalseLabel,
                    icon: Icons.check_circle_outline_rounded,
                    selected: _enabledTypes.contains(QuizQuestionType.trueFalse),
                    onTap: () => _toggleType(QuizQuestionType.trueFalse),
                  ),
                  _TypeChip(
                    label: l10n.textInput,
                    icon: Icons.edit_rounded,
                    selected: _enabledTypes.contains(QuizQuestionType.textInput),
                    onTap: () => _toggleType(QuizQuestionType.textInput),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // -- Direction --
              _SectionLabel(label: l10n.direction),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<QuizDirection>(
                  style: ButtonStyle(
                    visualDensity: VisualDensity.comfortable,
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  segments: [
                    ButtonSegment(
                      value: QuizDirection.termToDef,
                      label: Text(
                        l10n.termToDef,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    ButtonSegment(
                      value: QuizDirection.defToTerm,
                      label: Text(
                        l10n.defToTerm,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    ButtonSegment(
                      value: QuizDirection.mixed,
                      label: Text(
                        l10n.mixedDirection,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                  selected: {_direction},
                  onSelectionChanged: (v) =>
                      setState(() => _direction = v.first),
                ),
              ),

              const SizedBox(height: 24),

              // -- Prioritize weak cards --
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.purple.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.purple.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.prioritizeWeak,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.prioritizeWeakDesc,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: _prioritizeWeak,
                      onChanged: (v) => setState(() => _prioritizeWeak = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // -- Actions --
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _confirm,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        l10n.start,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildQuickButtons() {
    final presets = [5, 10, 20];
    final widgets = <Widget>[];

    for (final n in presets) {
      if (n <= widget.maxCount) {
        widgets.add(
          _QuickCountChip(
            label: '$n',
            selected: _count == n,
            onTap: () => _setCount(n),
          ),
        );
      }
    }

    // "All" button
    widgets.add(
      _QuickCountChip(
        label: '${widget.maxCount}',
        selected: _count == widget.maxCount,
        onTap: () => _setCount(widget.maxCount),
      ),
    );

    return widgets;
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _QuickCountChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickCountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.orange.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.orange
                : Colors.grey.withValues(alpha: 0.25),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppTheme.orange : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.indigo : Colors.grey.shade500;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.indigo.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppTheme.indigo.withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.2),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppTheme.indigo : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

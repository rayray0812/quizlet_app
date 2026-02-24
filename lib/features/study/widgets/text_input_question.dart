import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/features/study/utils/fuzzy_match.dart';

class TextInputQuestion extends StatefulWidget {
  final String definition;
  final String correctAnswer;
  final void Function(bool isCorrect) onAnswered;
  final Widget? headerTrailing;
  final bool enableHint;
  final int maxHints;
  final void Function(int usedHints)? onHintUsed;
  final String Function(String correctAnswer, int usedHints)? hintBuilder;

  const TextInputQuestion({
    super.key,
    required this.definition,
    required this.correctAnswer,
    required this.onAnswered,
    this.headerTrailing,
    this.enableHint = false,
    this.maxHints = 2,
    this.onHintUsed,
    this.hintBuilder,
  });

  @override
  State<TextInputQuestion> createState() => _TextInputQuestionState();
}

class _TextInputQuestionState extends State<TextInputQuestion> {
  final _controller = TextEditingController();
  final _blankFocusNode = FocusNode();
  bool? _isCorrect;
  int _hintUsed = 0;
  String _hintText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_useBlankInputStyle) {
        _blankFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _blankFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isCorrect != null) return;
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    final correct = isFuzzyMatch(input, widget.correctAnswer);
    setState(() => _isCorrect = correct);
    widget.onAnswered(correct);
  }

  void _markDontKnow() {
    if (_isCorrect != null) return;
    setState(() => _isCorrect = false);
    widget.onAnswered(false);
  }

  String _defaultHintBuilder(String answer, int usedHints) {
    final trimmed = answer.trim();
    if (trimmed.isEmpty) return '';
    final revealCount = (usedHints * 2).clamp(1, trimmed.length).toInt();
    final revealed = trimmed.substring(0, revealCount);
    if (revealCount >= trimmed.length) return revealed;
    return '$revealed...';
  }

  void _useHint() {
    if (_isCorrect != null || !widget.enableHint) return;
    if (_hintUsed >= widget.maxHints) return;
    final next = _hintUsed + 1;
    final builder = widget.hintBuilder ?? _defaultHintBuilder;
    final text = builder(widget.correctAnswer, next);
    setState(() {
      _hintUsed = next;
      _hintText = text;
    });
    widget.onHintUsed?.call(_hintUsed);
  }

  bool get _useBlankInputStyle {
    final answer = widget.correctAnswer.trim();
    if (answer.isEmpty) return false;
    if (answer.length > 18) return false;
    if (RegExp(r'[\u3040-\u30FF\u3400-\u9FFF\uF900-\uFAFF]').hasMatch(answer)) {
      return false;
    }
    return RegExp(r"^[A-Za-z]+$").hasMatch(answer);
  }

  void _onBlankChanged(String raw) {
    if (!_useBlankInputStyle) return;
    final lettersOnly = raw.replaceAll(RegExp(r'[^A-Za-z]'), '').toLowerCase();
    final maxLen = widget.correctAnswer.trim().length;
    final clipped = lettersOnly.length > maxLen ? lettersOnly.substring(0, maxLen) : lettersOnly;
    if (clipped != raw) {
      _controller.value = TextEditingValue(
        text: clipped,
        selection: TextSelection.collapsed(offset: clipped.length),
      );
    }
    if (_isCorrect != null) return;
    if (clipped.length == maxLen) {
      Future<void>.microtask(() {
        if (!mounted || _isCorrect != null) return;
        _submit();
      });
    } else if (mounted) {
      setState(() {});
    }
  }

  Future<void> _focusBlankInput() async {
    if (!_useBlankInputStyle || _isCorrect != null) return;
    if (!_blankFocusNode.hasFocus) {
      _blankFocusNode.requestFocus();
    }
    // Some devices won't reopen the keyboard for nearly-hidden fields unless
    // we explicitly ask the text input channel to show it again.
    await SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  Widget _buildBlankInput(ThemeData theme, AppLocalizations l10n, bool answered) {
    final answer = widget.correctAnswer.trim();
    final typed = _controller.text;
    final activeIndex = typed.length.clamp(0, answer.length);

    Color borderColorFor(int index) {
      if (answered) {
        return (_isCorrect ?? false) ? AppTheme.green : AppTheme.red;
      }
      if (index < typed.length) return AppTheme.indigo;
      if (index == activeIndex) return AppTheme.indigo;
      return Theme.of(context).colorScheme.outlineVariant;
    }

    Color fillColorFor(int index) {
      if (answered) {
        return ((_isCorrect ?? false) ? AppTheme.green : AppTheme.red)
            .withValues(alpha: 0.08);
      }
      if (index < typed.length) return AppTheme.indigo.withValues(alpha: 0.08);
      return Colors.white;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.indigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppTheme.indigo.withValues(alpha: 0.16)),
              ),
              child: Text(
                '拼字填空',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.indigo,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${answer.length} 個字母',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: answered ? null : _focusBlankInput,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 16),
            decoration: BoxDecoration(
              color: AppTheme.indigo.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.indigo.withValues(alpha: 0.10)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 10,
                children: List.generate(answer.length, (index) {
                  final char = index < typed.length ? typed[index] : '';
                  final isActive = index == activeIndex && !answered;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 26,
                    height: 34,
                    alignment: Alignment.bottomCenter,
                    decoration: BoxDecoration(
                      color: (index < typed.length || answered)
                          ? fillColorFor(index).withValues(alpha: 0.45)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border(
                        bottom: BorderSide(
                          color: borderColorFor(index),
                          width: isActive ? 2.2 : 1.4,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        char,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          height: 1,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 1,
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _blankFocusNode,
              enabled: !answered,
              autofocus: true,
              enableSuggestions: false,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.text,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                LengthLimitingTextInputFormatter(answer.length),
              ],
              onChanged: _onBlankChanged,
              onTap: _focusBlankInput,
              decoration: const InputDecoration.collapsed(hintText: ''),
            ),
          ),
        ),
        if (!answered) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _controller.text.isEmpty ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(l10n.submit),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _markDontKnow,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(l10n.dontKnow),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final answered = _isCorrect != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.definition,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (widget.headerTrailing != null) ...[
              const SizedBox(width: 8),
              widget.headerTrailing!,
            ],
          ],
        ),
        const SizedBox(height: 20),
        if (_useBlankInputStyle)
          _buildBlankInput(theme, l10n, answered)
        else ...[
          TextField(
            controller: _controller,
            enabled: !answered,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.typeYourAnswer,
              border: const OutlineInputBorder(),
              suffixIcon: answered
                  ? Icon(
                      _isCorrect! ? Icons.check_circle : Icons.cancel,
                      color: _isCorrect! ? AppTheme.green : AppTheme.red,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          if (!answered)
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    child: Text(l10n.submit),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _markDontKnow,
                    child: Text(l10n.dontKnow),
                  ),
                ),
              ],
            ),
        ],
        if (!answered && widget.enableHint) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _hintUsed < widget.maxHints ? _useHint : null,
            icon: const Icon(Icons.lightbulb_outline_rounded),
            label: Text('提示 ($_hintUsed/${widget.maxHints})'),
          ),
        ],
        if (!answered && _hintText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.orange.withValues(alpha: 0.4)),
            ),
            child: Text(
              _hintText,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        if (answered) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (_isCorrect! ? AppTheme.green : AppTheme.red)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isCorrect! ? AppTheme.green : AppTheme.red,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isCorrect! ? l10n.correctAnswer : l10n.almostCorrect,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _isCorrect! ? AppTheme.green : AppTheme.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!_isCorrect!) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.correctAnswer,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

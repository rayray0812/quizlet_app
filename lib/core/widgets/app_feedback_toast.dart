import 'package:flutter/material.dart';

enum AppToastTone { neutral, success, warning, error }

class AppFeedbackToast {
  static void show(
    BuildContext context, {
    required String message,
    AppToastTone tone = AppToastTone.neutral,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;

    final toneColors = switch (tone) {
      AppToastTone.neutral => (
        bg: scheme.surface.withValues(alpha: 0.95),
        fg: scheme.onSurface,
        border: scheme.outlineVariant.withValues(alpha: 0.8),
      ),
      AppToastTone.success => (
        bg: const Color(0xFFF0F8F2),
        fg: const Color(0xFF1C5E34),
        border: const Color(0xFFB9DDC5),
      ),
      AppToastTone.warning => (
        bg: const Color(0xFFFFF7EB),
        fg: const Color(0xFF8A5A17),
        border: const Color(0xFFEAD1A5),
      ),
      AppToastTone.error => (
        bg: scheme.errorContainer.withValues(alpha: 0.9),
        fg: scheme.onErrorContainer,
        border: scheme.error.withValues(alpha: 0.25),
      ),
    };

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        duration: duration,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: toneColors.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: toneColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DefaultTextStyle(
            style: TextStyle(color: toneColors.fg, fontWeight: FontWeight.w600),
            child: Text(message),
          ),
        ),
        action: action == null
            ? null
            : SnackBarAction(
                label: action.label,
                textColor: toneColors.fg,
                onPressed: action.onPressed,
              ),
      ),
    );
  }
}

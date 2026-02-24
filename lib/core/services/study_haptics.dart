import 'package:flutter/services.dart';

/// Centralised haptic feedback for all study modes.
abstract final class StudyHaptics {
  static void onCardFlip() => HapticFeedback.selectionClick();
  static void onSwipe() => HapticFeedback.lightImpact();
  static void onCorrect() => HapticFeedback.lightImpact();
  static void onWrong() => HapticFeedback.mediumImpact();
  static void onMatch() => HapticFeedback.selectionClick();
  static void onMismatch() => HapticFeedback.mediumImpact();
  static void onNextCard() => HapticFeedback.lightImpact();
  static void onComplete() => HapticFeedback.mediumImpact();
}

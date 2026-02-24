import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionXp {
  final int totalXp;
  final int comboCount;
  final int maxCombo;
  final double multiplier;

  const SessionXp({
    this.totalXp = 0,
    this.comboCount = 0,
    this.maxCombo = 0,
    this.multiplier = 1.0,
  });

  SessionXp copyWith({
    int? totalXp,
    int? comboCount,
    int? maxCombo,
    double? multiplier,
  }) {
    return SessionXp(
      totalXp: totalXp ?? this.totalXp,
      comboCount: comboCount ?? this.comboCount,
      maxCombo: maxCombo ?? this.maxCombo,
      multiplier: multiplier ?? this.multiplier,
    );
  }
}

double _multiplierForCombo(int combo) {
  if (combo >= 10) return 3.0;
  if (combo >= 5) return 2.0;
  if (combo >= 3) return 1.5;
  return 1.0;
}

class SessionXpNotifier extends StateNotifier<SessionXp> {
  SessionXpNotifier() : super(const SessionXp());

  /// Called when the user answers correctly in any study mode.
  /// [baseXp] defaults to 10 for quiz/matching, 5 for flashcard swipe.
  int onCorrect({int baseXp = 10}) {
    final newCombo = state.comboCount + 1;
    final mult = _multiplierForCombo(newCombo);
    final earned = (baseXp * mult).round();
    state = state.copyWith(
      totalXp: state.totalXp + earned,
      comboCount: newCombo,
      maxCombo: newCombo > state.maxCombo ? newCombo : state.maxCombo,
      multiplier: mult,
    );
    return earned;
  }

  /// Called when the user answers incorrectly — resets combo.
  void onIncorrect() {
    state = state.copyWith(
      comboCount: 0,
      multiplier: 1.0,
    );
  }

  /// SRS-specific rating-based XP.
  int onSrsRating(int rating) {
    switch (rating) {
      case 1: // Again
        onIncorrect();
        state = state.copyWith(totalXp: state.totalXp + 3);
        return 3;
      case 2: // Hard
        onIncorrect();
        state = state.copyWith(totalXp: state.totalXp + 5);
        return 5;
      case 3: // Good
        return onCorrect(baseXp: 10);
      case 4: // Easy
        return onCorrect(baseXp: 15);
      default:
        return 0;
    }
  }

  /// Flashcard "remembered" swipe.
  int onFlashcardRemembered() => onCorrect(baseXp: 5);

  /// Flashcard "forgot" swipe.
  void onFlashcardForgot() => onIncorrect();

  /// Reset for a new study session.
  void reset() => state = const SessionXp();
}

final sessionXpProvider =
    StateNotifierProvider.autoDispose<SessionXpNotifier, SessionXp>(
  (ref) => SessionXpNotifier(),
);

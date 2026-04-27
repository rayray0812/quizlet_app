/// Outcome types emitted by AI-driven modes.
///
/// Each outcome represents a semantic event from a session — OutcomeAdapter
/// translates these into FSRS scheduling actions without any AI mode needing
/// to know FSRS internals.
enum ConversationOutcome {
  /// User demonstrated the term in natural conversation.
  conversationSuccess,

  /// Target term was never used during the session.
  conversationUnusedTerm,

  /// Speaking mode: user explicitly used the target term in their response.
  speakingTargetUsed,

  /// Quiz mode: a confusion signal was detected (wrong answer, similar distractor).
  quizConfusionDetected,
}

/// An FSRS scheduling action returned by OutcomeAdapter.resolve().
sealed class FsrsAction {
  const FsrsAction();
}

/// No FSRS scheduling change — the outcome is informational only.
class NoScheduleImpact extends FsrsAction {
  const NoScheduleImpact();
}

/// Apply an FSRS review with [rating] (1=Again, 2=Hard, 3=Good, 4=Easy).
class ApplyFsrsRating extends FsrsAction {
  final int rating;
  const ApplyFsrsRating(this.rating) : assert(rating >= 1 && rating <= 4);
}

/// Translates AI-mode outcome events into FSRS scheduling actions.
///
/// Enforces the FSRS boundary: only FsrsService writes stability/difficulty/due.
/// All AI modes emit a ConversationOutcome; this adapter decides the rating.
abstract final class OutcomeAdapter {
  /// Resolve [outcome] into a scheduling action.
  static FsrsAction resolve(ConversationOutcome outcome) {
    switch (outcome) {
      case ConversationOutcome.conversationSuccess:
        return const ApplyFsrsRating(3); // Good — term used naturally
      case ConversationOutcome.conversationUnusedTerm:
        return const ApplyFsrsRating(1); // Again — missed, reschedule sooner
      case ConversationOutcome.speakingTargetUsed:
        return const ApplyFsrsRating(3); // Good — target confirmed in output
      case ConversationOutcome.quizConfusionDetected:
        return const NoScheduleImpact(); // Telemetry only, no schedule change
    }
  }
}

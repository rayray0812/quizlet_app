import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/providers/ai_provider_provider.dart';
import 'package:recall_app/services/local_ai_service.dart';

/// Whether the local Gemma model is configured (path set).
///
/// UI uses this to gate visibility of L1/L2/L3 affordances — if no model is
/// available, the buttons are simply hidden rather than showing errors.
final hasLocalAiModelProvider = Provider<bool>((ref) {
  final path = ref.watch(gemmaLocalModelPathProvider);
  return path.trim().isNotEmpty;
});

/// Argument for [reviewHintProvider].
class ReviewHintRequest {
  final String cardId;
  final String term;
  final String definition;

  const ReviewHintRequest({
    required this.cardId,
    required this.term,
    required this.definition,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewHintRequest &&
          cardId == other.cardId &&
          term == other.term &&
          definition == other.definition;

  @override
  int get hashCode => Object.hash(cardId, term, definition);
}

/// L1: lazy provider that produces a one-sentence hint for a card.
///
/// AutoDispose so hints don't pile up across review sessions.
/// Family-keyed by [ReviewHintRequest] so different cards have independent
/// caches within the same session.
final reviewHintProvider =
    FutureProvider.autoDispose.family<String?, ReviewHintRequest>((ref, req) async {
      final modelPath = ref.read(gemmaLocalModelPathProvider);
      if (modelPath.trim().isEmpty) return null;
      return LocalAiService.generateReviewHint(
        modelPath: modelPath,
        term: req.term,
        definition: req.definition,
      );
    });

/// L2: lazy provider that produces a memory mnemonic.
final mnemonicProvider =
    FutureProvider.autoDispose.family<String?, ReviewHintRequest>((ref, req) async {
      final modelPath = ref.read(gemmaLocalModelPathProvider);
      if (modelPath.trim().isEmpty) return null;
      return LocalAiService.generateMnemonic(
        modelPath: modelPath,
        term: req.term,
        definition: req.definition,
      );
    });

/// Argument for [confusionExplanationProvider].
class ConfusionRequest {
  final String targetTerm;
  final String targetDefinition;
  final String chosenTerm;
  final String chosenDefinition;

  const ConfusionRequest({
    required this.targetTerm,
    required this.targetDefinition,
    required this.chosenTerm,
    required this.chosenDefinition,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfusionRequest &&
          targetTerm == other.targetTerm &&
          chosenTerm == other.chosenTerm;

  @override
  int get hashCode => Object.hash(targetTerm, chosenTerm);
}

/// L3: lazy provider that explains a quiz confusion.
final confusionExplanationProvider =
    FutureProvider.autoDispose.family<String?, ConfusionRequest>((ref, req) async {
      final modelPath = ref.read(gemmaLocalModelPathProvider);
      if (modelPath.trim().isEmpty) return null;
      return LocalAiService.generateConfusionExplanation(
        modelPath: modelPath,
        targetTerm: req.targetTerm,
        targetDefinition: req.targetDefinition,
        chosenTerm: req.chosenTerm,
        chosenDefinition: req.chosenDefinition,
      );
    });

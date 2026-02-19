import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/features/study/models/conversation_transcript.dart';
import 'package:recall_app/features/study/screens/conversation_practice_screen.dart';

TranscriptTurn _turn() =>
    const TranscriptTurn(aiQuestion: 'Q', userResponse: 'A');

ConversationTranscript _transcript({
  required String id,
  required String setId,
  required String scenarioTitle,
  required String difficulty,
  required int totalTurns,
}) {
  return ConversationTranscript(
    id: id,
    setId: setId,
    setTitle: 'Set',
    scenarioTitle: scenarioTitle,
    difficulty: difficulty,
    totalTurns: totalTurns,
    overallScore: 4.0,
    completedAt: DateTime.utc(2026, 2, 19),
    turns: List<TranscriptTurn>.generate(totalTurns, (_) => _turn()),
  );
}

void main() {
  group('ConversationPracticeScreen.selectSummaryTranscript', () {
    test('prefers exact match for current session metadata', () {
      final old = _transcript(
        id: 'old',
        setId: 'set-1',
        scenarioTitle: 'Old Scenario',
        difficulty: 'easy',
        totalTurns: 3,
      );
      final exact = _transcript(
        id: 'exact',
        setId: 'set-1',
        scenarioTitle: 'Cafe Mobile Order Fix',
        difficulty: 'medium',
        totalTurns: 5,
      );

      final selected = ConversationPracticeScreen.selectSummaryTranscript(
        transcripts: [old, exact],
        setId: 'set-1',
        difficulty: 'medium',
        scenarioTitle: 'Cafe Mobile Order Fix',
        totalTurns: 5,
      );

      expect(selected?.id, 'exact');
    });

    test('falls back to latest transcript in same set when no exact match', () {
      final sameSetNewest = _transcript(
        id: 'same-set',
        setId: 'set-1',
        scenarioTitle: 'Other',
        difficulty: 'hard',
        totalTurns: 10,
      );
      final otherSet = _transcript(
        id: 'other-set',
        setId: 'set-2',
        scenarioTitle: 'Cafe Mobile Order Fix',
        difficulty: 'medium',
        totalTurns: 5,
      );

      final selected = ConversationPracticeScreen.selectSummaryTranscript(
        transcripts: [sameSetNewest, otherSet],
        setId: 'set-1',
        difficulty: 'medium',
        scenarioTitle: 'Cafe Mobile Order Fix',
        totalTurns: 5,
      );

      expect(selected?.id, 'same-set');
    });
  });
}

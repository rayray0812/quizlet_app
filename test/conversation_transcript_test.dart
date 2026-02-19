import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/features/study/models/conversation_transcript.dart';

void main() {
  group('ConversationTranscript', () {
    test('toJson and fromJson round-trip', () {
      final transcript = ConversationTranscript(
        id: 'test-id',
        setId: 'set-1',
        setTitle: 'English 101',
        scenarioTitle: 'Pharmacy Pickup',
        difficulty: 'medium',
        totalTurns: 3,
        overallScore: 4.2,
        completedAt: DateTime.utc(2026, 2, 18, 10, 30),
        turns: [
          const TranscriptTurn(
            aiQuestion: 'What do you need?',
            userResponse: 'I need medicine.',
            grammarScore: 4,
            vocabScore: 3,
            relevanceScore: 5,
            correction: '',
            termsUsed: ['medicine'],
          ),
          const TranscriptTurn(
            aiQuestion: 'Which brand?',
            userResponse: 'I want aspirin.',
            grammarScore: 5,
            vocabScore: 4,
            relevanceScore: 4,
            correction: 'I would like aspirin.',
            termsUsed: ['aspirin'],
          ),
        ],
      );

      final json = transcript.toJson();
      final decoded = ConversationTranscript.fromJson(json);

      expect(decoded.id, 'test-id');
      expect(decoded.setId, 'set-1');
      expect(decoded.setTitle, 'English 101');
      expect(decoded.scenarioTitle, 'Pharmacy Pickup');
      expect(decoded.difficulty, 'medium');
      expect(decoded.totalTurns, 3);
      expect(decoded.overallScore, 4.2);
      expect(decoded.turns.length, 2);
      expect(decoded.turns[0].aiQuestion, 'What do you need?');
      expect(decoded.turns[1].correction, 'I would like aspirin.');
    });

    test('encodeList and decodeList round-trip', () {
      final transcripts = [
        ConversationTranscript(
          id: 'a',
          setId: 's1',
          setTitle: 'Set 1',
          scenarioTitle: 'Test',
          difficulty: 'easy',
          totalTurns: 2,
          overallScore: 3.5,
          completedAt: DateTime.utc(2026, 1, 1),
          turns: const [
            TranscriptTurn(
              aiQuestion: 'Q1',
              userResponse: 'R1',
            ),
          ],
        ),
      ];

      final encoded = ConversationTranscript.encodeList(transcripts);
      final decoded = ConversationTranscript.decodeList(encoded);

      expect(decoded.length, 1);
      expect(decoded[0].id, 'a');
      expect(decoded[0].turns[0].aiQuestion, 'Q1');
    });

    test('decodeList handles invalid JSON', () {
      expect(ConversationTranscript.decodeList('not json'), isEmpty);
      expect(ConversationTranscript.decodeList(''), isEmpty);
    });

    test('fromJson handles missing fields gracefully', () {
      final t = ConversationTranscript.fromJson({});
      expect(t.id, '');
      expect(t.totalTurns, 0);
      expect(t.turns, isEmpty);
    });
  });

  group('TranscriptTurn', () {
    test('toJson and fromJson round-trip', () {
      const turn = TranscriptTurn(
        aiQuestion: 'How are you?',
        userResponse: 'I am fine.',
        grammarScore: 4,
        vocabScore: 3,
        relevanceScore: 5,
        correction: '',
        termsUsed: ['fine'],
      );

      final json = turn.toJson();
      final decoded = TranscriptTurn.fromJson(json);

      expect(decoded.aiQuestion, 'How are you?');
      expect(decoded.userResponse, 'I am fine.');
      expect(decoded.grammarScore, 4);
      expect(decoded.termsUsed, ['fine']);
    });

    test('defaults are correct', () {
      const turn = TranscriptTurn(
        aiQuestion: 'Q',
        userResponse: 'R',
      );
      expect(turn.grammarScore, 0);
      expect(turn.vocabScore, 0);
      expect(turn.relevanceScore, 0);
      expect(turn.correction, '');
      expect(turn.termsUsed, isEmpty);
    });
  });
}

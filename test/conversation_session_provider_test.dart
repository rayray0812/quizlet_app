import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/features/study/models/conversation_turn_record.dart';
import 'package:recall_app/providers/conversation_session_provider.dart';

void main() {
  group('ConversationTurnRecord', () {
    test('creates with correct fields', () {
      final now = DateTime.now().toUtc();
      final record = ConversationTurnRecord(
        turnIndex: 0,
        aiQuestion: 'What do you need?',
        userResponse: 'I want an apple.',
        replyHint: 'Start with "I need..."',
        termsUsed: {'apple'},
        timestamp: now,
      );

      expect(record.turnIndex, 0);
      expect(record.aiQuestion, 'What do you need?');
      expect(record.userResponse, 'I want an apple.');
      expect(record.replyHint, 'Start with "I need..."');
      expect(record.termsUsed, {'apple'});
      expect(record.timestamp, now);
    });

    test('termsUsed can be empty', () {
      final record = ConversationTurnRecord(
        turnIndex: 1,
        aiQuestion: 'How are you?',
        userResponse: 'I am fine.',
        replyHint: '',
        termsUsed: {},
        timestamp: DateTime.now().toUtc(),
      );
      expect(record.termsUsed, isEmpty);
    });
  });

  group('ConversationSessionState', () {
    test('defaults are correct', () {
      const state = ConversationSessionState();
      expect(state.messages, isEmpty);
      expect(state.turnRecords, isEmpty);
      expect(state.practicedTerms, isEmpty);
      expect(state.targetTerms, isEmpty);
      expect(state.isSessionEnded, false);
      expect(state.isAiTyping, false);
      expect(state.currentTurn, 0);
      expect(state.latestReplyHint, '');
      expect(state.suggestedReplies, isEmpty);
      expect(state.isGeneratingSuggestions, false);
      expect(state.useLocalCoachOnly, false);
      expect(state.isQuotaExhausted, false);
      expect(state.chatApiCalls, 0);
      expect(state.suggestionApiCalls, 0);
      expect(state.voiceStateName, 'idle');
    });

    test('copyWith updates specific fields', () {
      const state = ConversationSessionState();
      final updated = state.copyWith(
        isAiTyping: true,
        currentTurn: 3,
        scenarioTitle: 'Cafe',
      );
      expect(updated.isAiTyping, true);
      expect(updated.currentTurn, 3);
      expect(updated.scenarioTitle, 'Cafe');
      expect(updated.isSessionEnded, false); // unchanged
    });

    test('copyWith preserves existing values', () {
      final state = const ConversationSessionState().copyWith(
        targetTerms: ['hello', 'world'],
        aiRole: 'Barista',
      );
      final updated = state.copyWith(currentTurn: 2);
      expect(updated.targetTerms, ['hello', 'world']);
      expect(updated.aiRole, 'Barista');
      expect(updated.currentTurn, 2);
    });

    test('currentStage returns correct stage', () {
      final state = const ConversationSessionState().copyWith(
        stages: ['Step 1', 'Step 2', 'Step 3'],
        currentTurn: 1,
      );
      expect(state.currentStage, 'Step 2');
    });

    test('currentStage wraps around', () {
      final state = const ConversationSessionState().copyWith(
        stages: ['Step 1', 'Step 2'],
        currentTurn: 3,
      );
      expect(state.currentStage, 'Step 2'); // 3 % 2 = 1
    });

    test('currentStage with empty stages', () {
      const state = ConversationSessionState();
      expect(state.currentStage, 'Continue the conversation.');
    });

    test('currentStageZh with empty stagesZh', () {
      const state = ConversationSessionState();
      expect(state.currentStageZh, '');
    });
  });

  group('ChatMessageData', () {
    test('creates AI message', () {
      const msg = ChatMessageData(isAi: true, text: 'Hello!');
      expect(msg.isAi, true);
      expect(msg.text, 'Hello!');
    });

    test('creates user message', () {
      const msg = ChatMessageData(isAi: false, text: 'Hi!');
      expect(msg.isAi, false);
      expect(msg.text, 'Hi!');
    });
  });

  group('SuggestedReplyData', () {
    test('creates with all fields', () {
      const reply = SuggestedReplyData(
        reply: 'Could you help me?',
        zhHint: '\u5148\u79AE\u8C8C\u958B\u5834',
        focusWord: 'help',
      );
      expect(reply.reply, 'Could you help me?');
      expect(reply.zhHint, '\u5148\u79AE\u8C8C\u958B\u5834');
      expect(reply.focusWord, 'help');
    });
  });

  group('ConversationSessionParams', () {
    test('equality works', () {
      const a = ConversationSessionParams(
        setId: 'abc',
        turns: 5,
        difficulty: 'medium',
      );
      const b = ConversationSessionParams(
        setId: 'abc',
        turns: 5,
        difficulty: 'medium',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different params are not equal', () {
      const a = ConversationSessionParams(
        setId: 'abc',
        turns: 5,
        difficulty: 'medium',
      );
      const b = ConversationSessionParams(
        setId: 'abc',
        turns: 5,
        difficulty: 'hard',
      );
      expect(a, isNot(equals(b)));
    });
  });
}

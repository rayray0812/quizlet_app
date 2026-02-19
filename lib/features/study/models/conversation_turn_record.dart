import 'package:recall_app/features/study/services/conversation_scorer.dart';

/// Records a single turn in a conversation practice session.
class ConversationTurnRecord {
  final int turnIndex;
  final String aiQuestion;
  final String userResponse;
  final String replyHint;
  final Set<String> termsUsed;
  final DateTime timestamp;
  final TurnFeedback? feedback;
  final bool isEvaluating;

  const ConversationTurnRecord({
    required this.turnIndex,
    required this.aiQuestion,
    required this.userResponse,
    required this.replyHint,
    required this.termsUsed,
    required this.timestamp,
    this.feedback,
    this.isEvaluating = false,
  });

  ConversationTurnRecord copyWith({
    TurnFeedback? feedback,
    bool? isEvaluating,
  }) {
    return ConversationTurnRecord(
      turnIndex: turnIndex,
      aiQuestion: aiQuestion,
      userResponse: userResponse,
      replyHint: replyHint,
      termsUsed: termsUsed,
      timestamp: timestamp,
      feedback: feedback ?? this.feedback,
      isEvaluating: isEvaluating ?? this.isEvaluating,
    );
  }
}

/// Session-scoped state for a conversation practice session.
class ConversationSessionState {
  final List<ChatMessageData> messages;
  final List<ConversationTurnRecord> turnRecords;
  final Set<String> practicedTerms;
  final List<String> targetTerms;
  final bool isSessionEnded;
  final bool isAiTyping;
  final int currentTurn;
  final String latestReplyHint;
  final List<SuggestedReplyData> suggestedReplies;
  final bool isGeneratingSuggestions;
  final bool useLocalCoachOnly;
  final bool isQuotaExhausted;
  final String scenarioTitle;
  final String scenarioTitleZh;
  final String scenarioSetting;
  final String scenarioSettingZh;
  final String aiRole;
  final String aiRoleZh;
  final String userRole;
  final String userRoleZh;
  final List<String> stages;
  final List<String> stagesZh;
  final int chatApiCalls;
  final int suggestionApiCalls;
  final String voiceStateName;
  final String voiceDiagnostic;
  final bool isInRateCooldown;
  final int cooldownSecondsLeft;

  const ConversationSessionState({
    this.messages = const [],
    this.turnRecords = const [],
    this.practicedTerms = const {},
    this.targetTerms = const [],
    this.isSessionEnded = false,
    this.isAiTyping = false,
    this.currentTurn = 0,
    this.latestReplyHint = '',
    this.suggestedReplies = const [],
    this.isGeneratingSuggestions = false,
    this.useLocalCoachOnly = false,
    this.isQuotaExhausted = false,
    this.scenarioTitle = '',
    this.scenarioTitleZh = '',
    this.scenarioSetting = '',
    this.scenarioSettingZh = '',
    this.aiRole = '',
    this.aiRoleZh = '',
    this.userRole = '',
    this.userRoleZh = '',
    this.stages = const [],
    this.stagesZh = const [],
    this.chatApiCalls = 0,
    this.suggestionApiCalls = 0,
    this.voiceStateName = 'idle',
    this.voiceDiagnostic = 'Idle',
    this.isInRateCooldown = false,
    this.cooldownSecondsLeft = 0,
  });

  ConversationSessionState copyWith({
    List<ChatMessageData>? messages,
    List<ConversationTurnRecord>? turnRecords,
    Set<String>? practicedTerms,
    List<String>? targetTerms,
    bool? isSessionEnded,
    bool? isAiTyping,
    int? currentTurn,
    String? latestReplyHint,
    List<SuggestedReplyData>? suggestedReplies,
    bool? isGeneratingSuggestions,
    bool? useLocalCoachOnly,
    bool? isQuotaExhausted,
    String? scenarioTitle,
    String? scenarioTitleZh,
    String? scenarioSetting,
    String? scenarioSettingZh,
    String? aiRole,
    String? aiRoleZh,
    String? userRole,
    String? userRoleZh,
    List<String>? stages,
    List<String>? stagesZh,
    int? chatApiCalls,
    int? suggestionApiCalls,
    String? voiceStateName,
    String? voiceDiagnostic,
    bool? isInRateCooldown,
    int? cooldownSecondsLeft,
  }) {
    return ConversationSessionState(
      messages: messages ?? this.messages,
      turnRecords: turnRecords ?? this.turnRecords,
      practicedTerms: practicedTerms ?? this.practicedTerms,
      targetTerms: targetTerms ?? this.targetTerms,
      isSessionEnded: isSessionEnded ?? this.isSessionEnded,
      isAiTyping: isAiTyping ?? this.isAiTyping,
      currentTurn: currentTurn ?? this.currentTurn,
      latestReplyHint: latestReplyHint ?? this.latestReplyHint,
      suggestedReplies: suggestedReplies ?? this.suggestedReplies,
      isGeneratingSuggestions:
          isGeneratingSuggestions ?? this.isGeneratingSuggestions,
      useLocalCoachOnly: useLocalCoachOnly ?? this.useLocalCoachOnly,
      isQuotaExhausted: isQuotaExhausted ?? this.isQuotaExhausted,
      scenarioTitle: scenarioTitle ?? this.scenarioTitle,
      scenarioTitleZh: scenarioTitleZh ?? this.scenarioTitleZh,
      scenarioSetting: scenarioSetting ?? this.scenarioSetting,
      scenarioSettingZh: scenarioSettingZh ?? this.scenarioSettingZh,
      aiRole: aiRole ?? this.aiRole,
      aiRoleZh: aiRoleZh ?? this.aiRoleZh,
      userRole: userRole ?? this.userRole,
      userRoleZh: userRoleZh ?? this.userRoleZh,
      stages: stages ?? this.stages,
      stagesZh: stagesZh ?? this.stagesZh,
      chatApiCalls: chatApiCalls ?? this.chatApiCalls,
      suggestionApiCalls: suggestionApiCalls ?? this.suggestionApiCalls,
      voiceStateName: voiceStateName ?? this.voiceStateName,
      voiceDiagnostic: voiceDiagnostic ?? this.voiceDiagnostic,
      isInRateCooldown: isInRateCooldown ?? this.isInRateCooldown,
      cooldownSecondsLeft: cooldownSecondsLeft ?? this.cooldownSecondsLeft,
    );
  }

  String get currentStage {
    if (stages.isEmpty) return 'Continue the conversation.';
    return stages[currentTurn % stages.length];
  }

  String get currentStageZh {
    if (stagesZh.isEmpty) return '';
    return stagesZh[currentTurn % stagesZh.length];
  }
}

/// Chat message data (pure data, no Sender enum dependency on UI).
class ChatMessageData {
  final bool isAi;
  final String text;

  const ChatMessageData({required this.isAi, required this.text});
}

/// Suggested reply data (pure data mirror of ConversationReplySuggestion).
class SuggestedReplyData {
  final String reply;
  final String zhHint;
  final String focusWord;

  const SuggestedReplyData({
    required this.reply,
    required this.zhHint,
    required this.focusWord,
  });
}

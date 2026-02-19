import 'dart:convert';

/// A complete conversation practice transcript for history/review.
class ConversationTranscript {
  final String id;
  final String setId;
  final String setTitle;
  final String scenarioTitle;
  final String difficulty;
  final int totalTurns;
  final double overallScore;
  final DateTime completedAt;
  final List<TranscriptTurn> turns;

  const ConversationTranscript({
    required this.id,
    required this.setId,
    required this.setTitle,
    required this.scenarioTitle,
    required this.difficulty,
    required this.totalTurns,
    required this.overallScore,
    required this.completedAt,
    required this.turns,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'setId': setId,
        'setTitle': setTitle,
        'scenarioTitle': scenarioTitle,
        'difficulty': difficulty,
        'totalTurns': totalTurns,
        'overallScore': overallScore,
        'completedAt': completedAt.toIso8601String(),
        'turns': turns.map((t) => t.toJson()).toList(),
      };

  factory ConversationTranscript.fromJson(Map<String, dynamic> json) {
    return ConversationTranscript(
      id: json['id'] as String? ?? '',
      setId: json['setId'] as String? ?? '',
      setTitle: json['setTitle'] as String? ?? '',
      scenarioTitle: json['scenarioTitle'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'medium',
      totalTurns: json['totalTurns'] as int? ?? 0,
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0.0,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.now(),
      turns: (json['turns'] as List<dynamic>?)
              ?.map((t) =>
                  TranscriptTurn.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static String encodeList(List<ConversationTranscript> transcripts) {
    return jsonEncode(transcripts.map((t) => t.toJson()).toList());
  }

  static List<ConversationTranscript> decodeList(String jsonStr) {
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) =>
              ConversationTranscript.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

/// A single turn within a transcript.
class TranscriptTurn {
  final String aiQuestion;
  final String userResponse;
  final int grammarScore;
  final int vocabScore;
  final int relevanceScore;
  final String correction;
  final List<String> termsUsed;

  const TranscriptTurn({
    required this.aiQuestion,
    required this.userResponse,
    this.grammarScore = 0,
    this.vocabScore = 0,
    this.relevanceScore = 0,
    this.correction = '',
    this.termsUsed = const [],
  });

  Map<String, dynamic> toJson() => {
        'aiQuestion': aiQuestion,
        'userResponse': userResponse,
        'grammarScore': grammarScore,
        'vocabScore': vocabScore,
        'relevanceScore': relevanceScore,
        'correction': correction,
        'termsUsed': termsUsed,
      };

  factory TranscriptTurn.fromJson(Map<String, dynamic> json) {
    return TranscriptTurn(
      aiQuestion: json['aiQuestion'] as String? ?? '',
      userResponse: json['userResponse'] as String? ?? '',
      grammarScore: json['grammarScore'] as int? ?? 0,
      vocabScore: json['vocabScore'] as int? ?? 0,
      relevanceScore: json['relevanceScore'] as int? ?? 0,
      correction: json['correction'] as String? ?? '',
      termsUsed: (json['termsUsed'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

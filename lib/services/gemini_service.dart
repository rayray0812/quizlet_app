import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

enum PhotoScanMode { vocabularyList, textbookPage }

/// Specific failure reasons for UI to display.
enum ScanFailureReason {
  timeout,
  quotaExceeded,
  authError,
  invalidRequest,
  serverError,
  parseError,
  networkError,
  unknown,
}

class ScanException implements Exception {
  final ScanFailureReason reason;
  final String message;

  ScanException(this.reason, this.message);

  @override
  String toString() => message;
}

class ConversationScenario {
  final String title;
  final String titleZh;
  final String setting;
  final String settingZh;
  final String aiRole;
  final String aiRoleZh;
  final String userRole;
  final String userRoleZh;
  final List<String> stages;
  final List<String> stagesZh;

  const ConversationScenario({
    required this.title,
    required this.titleZh,
    required this.setting,
    required this.settingZh,
    required this.aiRole,
    required this.aiRoleZh,
    required this.userRole,
    required this.userRoleZh,
    required this.stages,
    required this.stagesZh,
  });
}

class ConversationReplySuggestion {
  final String reply;
  final String zhHint;
  final String focusWord;

  const ConversationReplySuggestion({
    required this.reply,
    required this.zhHint,
    required this.focusWord,
  });
}

class GeminiService {
  static const _models = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-1.5-flash',
  ];
  static const _chatModels = [
    'gemini-2.0-flash-lite',
    'gemini-2.0-flash',
    'gemini-2.5-flash',
  ];
  static const _timeout = Duration(seconds: 30);
  static const maxCards = 300;
  static const _lightweightModels = ['gemini-2.0-flash-lite', 'gemini-2.0-flash'];

  static const _vocabularyPrompt =
      'Extract all term-definition pairs from this vocabulary list/word table image. '
      'Keep original language. For bilingual content, use one language as term and the other as definition. '
      'Skip headers and page numbers. '
      'Also include an example sentence for each term in the same language when possible. '
      'If no clear sentence is available, return empty string for exampleSentence.';

  static const _textbookPrompt =
      'Extract 5-15 key concepts from this textbook/study material image as flashcard pairs. '
      'Create concise term (question/concept) and definition (answer/explanation). '
      'Keep original language. Focus on testable knowledge points. '
      'Also provide an example sentence in the same language when possible; otherwise use empty string.';

  static const _jsonOnlySuffix =
      'Return ONLY valid JSON array. Do not use markdown fences. '
      'Each item must be: {"term":"...","definition":"...","exampleSentence":"..."}';

  static final _responseSchema = Schema.array(
    items: Schema.object(
      properties: {
        'term': Schema.string(description: 'The term or question'),
        'definition': Schema.string(description: 'The definition or answer'),
        'exampleSentence': Schema.string(
          description:
              'Optional example sentence for the term. Empty string when unavailable.',
        ),
      },
      requiredProperties: ['term', 'definition'],
    ),
  );

  /// Extract flashcards from an image using Gemini Flash.
  /// Tries models in order; falls back to the next on quota/rate errors.
  /// Returns a list of {term, definition, exampleSentence} maps.
  /// Throws [ScanException] with a specific reason on failure.
  static Future<List<Map<String, String>>> extractFlashcards({
    required String apiKey,
    required Uint8List imageBytes,
    required String mimeType,
    required PhotoScanMode mode,
  }) async {
    final prompt = switch (mode) {
      PhotoScanMode.vocabularyList => _vocabularyPrompt,
      PhotoScanMode.textbookPage => _textbookPrompt,
    };

    final content = Content.multi([
      TextPart(prompt),
      DataPart(mimeType, imageBytes),
    ]);

    ScanException? lastError;

    for (final modelName in _models) {
      try {
        final response = await _generateWithFallback(
          apiKey: apiKey,
          modelName: modelName,
          content: content,
          prompt: prompt,
        ).timeout(_timeout);
        final text = response.text;
        if (text == null || text.trim().isEmpty) return [];

        final results = parseResponse(text);
        if (results.length > maxCards) {
          return results.sublist(0, maxCards);
        }
        return results;
      } on TimeoutException {
        lastError = ScanException(
          ScanFailureReason.timeout,
          'Request timed out',
        );
      } on GenerativeAIException catch (e) {
        final reason = _classifyAiError(e.toString());
        lastError = ScanException(reason, e.toString());
        if (reason == ScanFailureReason.quotaExceeded ||
            reason == ScanFailureReason.serverError) {
          // Retry with next model only on transient/server-like failures.
          continue;
        }
      } on FormatException catch (e) {
        lastError = ScanException(ScanFailureReason.parseError, e.toString());
      } catch (e) {
        if (e is ScanException) throw e;
        lastError = ScanException(ScanFailureReason.networkError, e.toString());
      }
    }

    throw lastError ??
        ScanException(ScanFailureReason.unknown, 'All models failed');
  }

  static Future<GenerateContentResponse> _generateWithFallback({
    required String apiKey,
    required String modelName,
    required Content content,
    required String prompt,
  }) async {
    try {
      final structuredModel = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0,
          maxOutputTokens: 4096,
          responseMimeType: 'application/json',
          responseSchema: _responseSchema,
        ),
      );
      return await structuredModel.generateContent([content]);
    } on GenerativeAIException catch (e) {
      final msg = e.toString().toLowerCase();
      final likelySchemaIssue =
          msg.contains('response_schema') ||
          msg.contains('responsemime') ||
          msg.contains('invalid argument') ||
          msg.contains('unsupported');
      if (!likelySchemaIssue) throw e;
    }

    final jsonOnlyModel = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0, maxOutputTokens: 4096),
    );
    final dataParts = content.parts.whereType<DataPart>();
    final dataPart = dataParts.isEmpty ? null : dataParts.first;
    final jsonOnlyParts = <Part>[TextPart('$prompt $_jsonOnlySuffix')];
    if (dataPart != null) {
      jsonOnlyParts.add(dataPart);
    }
    final jsonOnlyContent = Content.multi(jsonOnlyParts);
    return jsonOnlyModel.generateContent([jsonOnlyContent]);
  }

  static ScanFailureReason _classifyAiError(String raw) {
    final msg = raw.toLowerCase();
    if (msg.contains('quota') ||
        msg.contains('rate limit') ||
        msg.contains('rate_limit') ||
        msg.contains('429') ||
        msg.contains('resource has been exhausted') ||
        msg.contains('resource_exhausted')) {
      return ScanFailureReason.quotaExceeded;
    }
    if (msg.contains('api key not valid') ||
        msg.contains('unauthenticated') ||
        msg.contains('permission denied') ||
        msg.contains('401') ||
        msg.contains('403')) {
      return ScanFailureReason.authError;
    }
    if (msg.contains('invalid argument') ||
        msg.contains('bad request') ||
        msg.contains('request contains an invalid') ||
        msg.contains('400')) {
      return ScanFailureReason.invalidRequest;
    }
    if (msg.contains('internal') ||
        msg.contains('unavailable') ||
        msg.contains('deadline exceeded') ||
        msg.contains('503') ||
        msg.contains('500')) {
      return ScanFailureReason.serverError;
    }
    if (msg.contains('failed host lookup') ||
        msg.contains('socketexception') ||
        msg.contains('network')) {
      return ScanFailureReason.networkError;
    }
    return ScanFailureReason.unknown;
  }

  /// Parses Gemini response text into flashcard maps.
  /// Visible for testing.
  static List<Map<String, String>> parseResponse(String raw) {
    var cleaned = raw.trim();

    // Strip markdown code fences if present
    if (cleaned.startsWith('```')) {
      final firstNewline = cleaned.indexOf('\n');
      if (firstNewline != -1) {
        cleaned = cleaned.substring(firstNewline + 1);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3).trim();
      }
    }

    // Extract JSON from response - find first [ or { and last ] or }
    final bracketIdx = cleaned.indexOf('[');
    final braceIdx = cleaned.indexOf('{');
    int startIdx = -1;
    if (bracketIdx != -1 && braceIdx != -1) {
      startIdx = bracketIdx < braceIdx ? bracketIdx : braceIdx;
    } else if (bracketIdx != -1) {
      startIdx = bracketIdx;
    } else if (braceIdx != -1) {
      startIdx = braceIdx;
    }
    if (startIdx != -1) {
      cleaned = cleaned.substring(startIdx);
      final lastBracket = cleaned.lastIndexOf(']');
      final lastBrace = cleaned.lastIndexOf('}');
      final endIdx = lastBracket > lastBrace ? lastBracket : lastBrace;
      if (endIdx != -1) {
        cleaned = cleaned.substring(0, endIdx + 1);
      }
    }

    final decoded = jsonDecode(cleaned);
    List<dynamic> items;

    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map) {
      // Support {"cards": [...]} or {"flashcards": [...]} or any key with a list value
      final listValue = decoded.values.firstWhere(
        (v) => v is List,
        orElse: () => null,
      );
      if (listValue is List) {
        items = listValue;
      } else {
        return [];
      }
    } else {
      return [];
    }

    final results = <Map<String, String>>[];

    for (final item in items) {
      if (item is Map) {
        final term = (item['term'] ?? '').toString().trim();
        final definition = (item['definition'] ?? '').toString().trim();
        final exampleSentence = (item['exampleSentence'] ?? '')
            .toString()
            .trim();
        if (term.isNotEmpty && definition.isNotEmpty) {
          results.add({
            'term': term,
            'definition': definition,
            'exampleSentence': exampleSentence,
          });
        }
      }
    }

    return results;
  }

  /// Generates example sentences for a batch of terms.
  /// Returns a map of {term: exampleSentence}.
  static Future<Map<String, String>> generateExampleSentencesBatch({
    required String apiKey,
    required List<Map<String, String>> terms,
  }) async {
    if (terms.isEmpty) return {};

    final promptBuffer = StringBuffer();
    promptBuffer.writeln(
      'Generate a simple, natural example sentence for each of the following terms. '
      'The sentence should help understand the meaning of the term. '
      'Return ONLY a valid JSON array of objects with keys: "term", "exampleSentence". '
      'Do not include the definition in the output.',
    );
    promptBuffer.writeln('Terms:');
    for (final t in terms) {
      promptBuffer.writeln(
        '- Term: "${t['term']}", Meaning: "${t['definition']}"',
      );
    }

    final content = Content.text(promptBuffer.toString());

    for (final modelName in _models) {
      try {
        final response = await _generateWithFallback(
          apiKey: apiKey,
          modelName: modelName,
          content: content,
          prompt: promptBuffer.toString(),
        ).timeout(_timeout);

        final text = response.text;
        if (text == null || text.trim().isEmpty) continue;

        final results = parseResponse(text);
        final map = <String, String>{};
        for (final item in results) {
          final term = item['term'];
          final sentence = item['exampleSentence'];
          if (term != null && sentence != null && sentence.isNotEmpty) {
            map[term] = sentence;
          }
        }
        return map;
      } catch (e) {
        // Try next model
        continue;
      }
    }

    // If all fail
    return {};
  }
  // -- Conversation Mode --

  /// Starts a chat session for practicing vocabulary.
  /// Returns a [ChatSession] that maintains history.
  static ChatSession startConversation({
    required String apiKey,
    required List<String> terms,
    required String difficulty,
    required String scenarioTitle,
    required String scenarioSetting,
    required String aiRole,
    required String userRole,
  }) {
    final normalizedDifficulty = difficulty.toLowerCase().trim();
    final difficultyRules = switch (normalizedDifficulty) {
      'easy' =>
        '''
Difficulty profile (EASY):
- Use exactly 1 target word per turn.
- Keep question very simple (A1-A2 level), one idea only.
- Prioritize guidance over correction. Do not nitpick grammar.
- Reply hint must be highly scaffolded and directly reusable.
''',
      'hard' =>
        '''
Difficulty profile (HARD):
- Use 2-3 target words per turn.
- Ask a more specific scenario-based question (B2+ level).
- If student has mistakes, briefly correct then continue.
- Reply hint should be shorter and less hand-holding.
''',
      _ =>
        '''
Difficulty profile (MEDIUM):
- Use 1-2 target words per turn.
- Ask practical daily-life question (around B1 level).
- Give concise correction only when needed.
- Reply hint should guide but leave room to compose.
''',
    };

    final systemPrompt =
        '''
You are a strict vocabulary conversation coach. No greetings, no small talk.
Target words the student must practice: ${terms.join(', ')}.
Difficulty: $normalizedDifficulty.
Scenario: $scenarioTitle
Setting: $scenarioSetting
Stay in this scenario for the whole session.
Your role: $aiRole
Student role: $userRole
$difficultyRules
Rules:
1. Every turn must make it easy for the student to answer.
2. Every response MUST include target words according to the difficulty profile.
3. Ask exactly ONE concrete question with specific detail (item/time/price/quantity).
4. Also provide ONE short "Reply hint" starter sentence the student can copy and complete.
5. Rotate target words and prioritize words not practiced yet.
6. If there is an error, correct in one short sentence, then ask the next question.
7. Keep total output under 35 words, natural spoken English, use contractions when appropriate.
8. Output must be exactly 2 lines:
Question: ...
Reply hint: ...
9. First message must directly ask a question (no greeting).
10. Avoid broad prompts like "Tell me more". Be specific and situational.
11. Avoid robotic tutor tone. Sound like a real person in this role.
''';

    final model = GenerativeModel(
      model: _chatModels.first, // Prefer stable chat model
      apiKey: apiKey,
      systemInstruction: Content.system(systemPrompt),
      generationConfig: GenerationConfig(
        maxOutputTokens: 120, // Keep responses compact for speed/cost
        temperature: 0.55,
      ),
    );

    return model.startChat();
  }

  /// Generates a random daily-life conversation scenario.
  static Future<ConversationScenario?> generateRandomScenario({
    required String apiKey,
    required String difficulty,
    required List<String> terms,
  }) async {
    final prompt =
        '''
Create one realistic daily-life English roleplay scenario for speaking practice.
Difficulty: $difficulty
Target words (use these later in dialogue): ${terms.take(8).join(', ')}
Requirements:
- scenario must be practical and specific in real life
- include clear context: place + concrete goal + at least one constraint (time/budget/urgency)
- keep roles clear and useful for language learners
- return ONLY JSON object with keys:
  title, titleZh, setting, settingZh, aiRole, aiRoleZh, userRole, userRoleZh, stages, stagesZh
- stages must be an array of 5 short step strings
- stagesZh must be Traditional Chinese and aligned with stages
''';
    final text = await _generateLightweightJsonText(
      apiKey: apiKey,
      prompt: prompt,
    );
    if (text == null || text.trim().isEmpty) return null;
    final parsed = _parseScenario(text);
    if (parsed != null) {
      return parsed;
    }
    return null;
  }

  /// Generates short suggested replies to keep conversation going.
  static Future<List<ConversationReplySuggestion>> generateSuggestedReplies({
    required String apiKey,
    required String difficulty,
    required String scenarioTitle,
    required String aiRole,
    required String userRole,
    required String latestQuestion,
    required List<String> priorityTerms,
  }) async {
    final prompt =
        '''
Generate 4 short reply suggestions for the student.
Context:
- Scenario: $scenarioTitle
- AI role: $aiRole
- Student role: $userRole
- Difficulty: $difficulty
- Latest question: $latestQuestion
- Try to include these target words naturally when possible: ${priorityTerms.join(', ')}
Rules:
- Generate only 3 suggestions.
- Each suggestion must be 1 sentence, 5-10 words, practical, and easy to say out loud.
- Easy: simpler patterns. Hard: richer phrasing.
- Avoid generic lines like "I don't know" or "Can you explain?".
- Return ONLY JSON array of objects with keys:
  reply, zhHint, focusWord
- zhHint must be short Traditional Chinese guidance (max 16 chars).
''';
    final text = await _generateLightweightJsonText(
      apiKey: apiKey,
      prompt: prompt,
    );
    if (text == null || text.trim().isEmpty) {
      return const <ConversationReplySuggestion>[];
    }
        final suggestions = _parseReplySuggestions(text);
        if (suggestions.isNotEmpty) {
          return suggestions.take(3).toList();
        }
    return const <ConversationReplySuggestion>[];
  }

  static Future<String?> _generateLightweightJsonText({
    required String apiKey,
    required String prompt,
  }) async {
    final content = Content.text(prompt);
    for (final modelName in _lightweightModels) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.4,
            maxOutputTokens: 512,
            responseMimeType: 'application/json',
          ),
        );
        final response = await model.generateContent([content]).timeout(_timeout);
        final text = response.text?.trim() ?? '';
        if (text.isNotEmpty) return text;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static ConversationScenario? _parseScenario(String raw) {
    try {
      var cleaned = raw.trim();
      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        cleaned = cleaned.substring(start, end + 1);
      }
      final decoded = jsonDecode(cleaned);
      if (decoded is! Map) return null;
      final title = (decoded['title'] ?? '').toString().trim();
      final titleZh = (decoded['titleZh'] ?? '').toString().trim();
      final setting = (decoded['setting'] ?? '').toString().trim();
      final settingZh = (decoded['settingZh'] ?? '').toString().trim();
      final aiRole = (decoded['aiRole'] ?? '').toString().trim();
      final aiRoleZh = (decoded['aiRoleZh'] ?? '').toString().trim();
      final userRole = (decoded['userRole'] ?? '').toString().trim();
      final userRoleZh = (decoded['userRoleZh'] ?? '').toString().trim();
      final stagesRaw = decoded['stages'];
      final stagesZhRaw = decoded['stagesZh'];
      final stages = stagesRaw is List
          ? stagesRaw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
          : <String>[];
      final stagesZh = stagesZhRaw is List
          ? stagesZhRaw
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : <String>[];
      if (title.isEmpty || setting.isEmpty || aiRole.isEmpty || userRole.isEmpty) {
        return null;
      }
      return ConversationScenario(
        title: title,
        titleZh: titleZh.isEmpty ? title : titleZh,
        setting: setting,
        settingZh: settingZh.isEmpty ? setting : settingZh,
        aiRole: aiRole,
        aiRoleZh: aiRoleZh.isEmpty ? aiRole : aiRoleZh,
        userRole: userRole,
        userRoleZh: userRoleZh.isEmpty ? userRole : userRoleZh,
        stages: stages.take(5).toList(),
        stagesZh: stagesZh.take(5).toList(),
      );
    } catch (_) {
      return null;
    }
  }

  static List<String> _parseStringArray(String raw) {
    try {
      var cleaned = raw.trim();
      final start = cleaned.indexOf('[');
      final end = cleaned.lastIndexOf(']');
      if (start != -1 && end != -1 && end > start) {
        cleaned = cleaned.substring(start, end + 1);
      }
      final decoded = jsonDecode(cleaned);
      if (decoded is! List) return const <String>[];
      return decoded
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      return const <String>[];
    }
  }

  static List<ConversationReplySuggestion> _parseReplySuggestions(String raw) {
    try {
      var cleaned = raw.trim();
      final start = cleaned.indexOf('[');
      final end = cleaned.lastIndexOf(']');
      if (start != -1 && end != -1 && end > start) {
        cleaned = cleaned.substring(start, end + 1);
      }
      final decoded = jsonDecode(cleaned);
      if (decoded is! List) return const <ConversationReplySuggestion>[];
      final results = <ConversationReplySuggestion>[];
      for (final item in decoded) {
        if (item is Map) {
          final reply = (item['reply'] ?? '').toString().trim();
          final zhHint = (item['zhHint'] ?? '').toString().trim();
          final focusWord = (item['focusWord'] ?? '').toString().trim();
          if (reply.isEmpty) continue;
          results.add(
            ConversationReplySuggestion(
              reply: reply,
              zhHint: zhHint,
              focusWord: focusWord,
            ),
          );
          continue;
        }
        final fallback = item.toString().trim();
        if (fallback.isEmpty) continue;
        results.add(
          ConversationReplySuggestion(
            reply: fallback,
            zhHint: '',
            focusWord: '',
          ),
        );
      }
      return results;
    } catch (_) {
      final fallback = _parseStringArray(raw);
      return fallback
          .map(
            (line) => ConversationReplySuggestion(
              reply: line,
              zhHint: '',
              focusWord: '',
            ),
          )
          .toList();
    }
  }
}


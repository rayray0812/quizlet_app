import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/widgets/app_back_button.dart';
import 'package:recall_app/providers/gemini_key_provider.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/services/ai_tts_service.dart';
import 'package:recall_app/services/gemini_service.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ConversationPracticeScreen extends ConsumerStatefulWidget {
  final String setId;
  final int turns;
  final String difficulty;

  const ConversationPracticeScreen({
    super.key,
    required this.setId,
    required this.turns,
    required this.difficulty,
  });

  @override
  ConsumerState<ConversationPracticeScreen> createState() =>
      _ConversationPracticeScreenState();
}

enum Sender { user, ai }

enum _ApiIssueType { none, hardQuota, rateLimit, auth, other }

class ChatMessage {
  final Sender sender;
  final String text;

  ChatMessage({
    required this.sender,
    required this.text,
  });
}

class AiTurnContent {
  final String question;
  final String replyHint;

  const AiTurnContent({required this.question, required this.replyHint});
}

class _ConversationPracticeScreenState
    extends ConsumerState<ConversationPracticeScreen> {
  static final RegExp _latinOrDigit = RegExp(r'[a-z0-9]');
  static final RegExp _nonWordChars = RegExp(
    r'[^a-z0-9\u4e00-\u9fff\u3400-\u4dbf\u3040-\u30ff\s]',
  );

  late FlutterTts _tts;
  late Future<void> _ttsInitFuture;
  late SpeechToText _stt;
  bool _sttAvailable = false;
  bool _isListening = false;

  ChatSession? _chatSession;
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isAiTyping = false;
  bool _isQuotaExhausted = false;
  bool _useLocalCoachOnly = false;
  int _consecutiveApiFailures = 0;
  DateTime? _lastApiErrorNoticeAt;
  DateTime? _lastChatApiCallAt;
  DateTime? _lastSuggestionApiCallAt;
  String _lastAiQuestionText = '';
  int _chatApiCalls = 0;
  int _suggestionApiCalls = 0;
  DateTime? _rateLimitCooldownUntil;
  int _chatMinGapMs = 900;
  int _focusCursor = 0;
  int _lastScenarioIndex = -1;
  int _currentTurn = 0;
  bool _isSessionEnded = false;
  bool _sessionStarted = false;
  bool _isDisposed = false;
  List<String> _targetTerms = <String>[];
  final Map<String, String> _targetTermDefinitions = <String, String>{};
  final Set<String> _practicedTerms = <String>{};
  String _latestReplyHint = '';
  List<ConversationReplySuggestion> _suggestedReplies =
      <ConversationReplySuggestion>[];
  bool _isGeneratingSuggestions = false;
  bool _didPlayFirstAiLine = false;
  String _firstAiQuestionText = '';
  bool _isShowingSummary = false;
  bool _isSpeechBusy = false;
  DateTime? _lastSpeechAt;
  List<Map<String, String>>? _ttsVoices;
  String? _aiLikeVoiceName;
  String? _aiLikeVoiceLocale;
  final Map<String, List<ConversationReplySuggestion>> _suggestionCache =
      <String, List<ConversationReplySuggestion>>{};
  ConversationScenario _scenario = const ConversationScenario(
    title: 'Everyday Errands',
    titleZh: '日常辦事',
    setting:
        'You are in a common daily-life conversation. Keep it practical and realistic.',
    settingZh: '你正在進行日常生活對話，請以實用情境為主。',
    aiRole: 'Local Staff',
    aiRoleZh: '店員/服務人員',
    userRole: 'Customer',
    userRoleZh: '顧客',
    stages: <String>[
      'State your need clearly',
      'Ask one follow-up detail',
      'Confirm options and price',
      'Decide and confirm action',
      'Close the conversation politely',
    ],
    stagesZh: <String>[
      '清楚說出你的需求',
      '追問一個細節',
      '確認選項與價格',
      '做決定並確認',
      '禮貌收尾',
    ],
  );

  static const List<ConversationScenario> _localScenarioPool = <ConversationScenario>[
    ConversationScenario(
      title: 'Pharmacy Pickup',
      titleZh: '藥局領藥',
      setting:
          'You are at a neighborhood pharmacy to pick up medicine before it closes in 20 minutes.',
      settingZh: '你在社區藥局領藥，距離打烊只剩20分鐘。',
      aiRole: 'Pharmacist',
      aiRoleZh: '藥師',
      userRole: 'Customer',
      userRoleZh: '顧客',
      stages: <String>[
        'State what you need to pick up',
        'Confirm your name and prescription details',
        'Ask dosage and timing',
        'Check side effects and precautions',
        'Confirm payment and leave',
      ],
      stagesZh: <String>[
        '說明你要領的藥',
        '確認姓名與處方資訊',
        '詢問劑量與服用時間',
        '確認副作用與注意事項',
        '確認付款後離開',
      ],
    ),
    ConversationScenario(
      title: 'Train Ticket Change',
      titleZh: '改高鐵票',
      setting:
          'You need to change your train ticket because your meeting was moved earlier.',
      settingZh: '你要改高鐵票，因為會議提前了。',
      aiRole: 'Ticket Staff',
      aiRoleZh: '售票人員',
      userRole: 'Passenger',
      userRoleZh: '乘客',
      stages: <String>[
        'Explain why you need a ticket change',
        'Ask for an earlier departure',
        'Confirm seat availability',
        'Check fare difference and policy',
        'Complete payment and confirm platform',
      ],
      stagesZh: <String>[
        '說明要改票的原因',
        '詢問更早班次',
        '確認座位是否有空',
        '確認價差與規則',
        '完成付款並確認月台',
      ],
    ),
    ConversationScenario(
      title: 'Cafe Mobile Order Fix',
      titleZh: '咖啡訂單修正',
      setting:
          'Your mobile coffee order is wrong, and you only have 10 minutes before class.',
      settingZh: '你的咖啡外送單有誤，且上課前只剩10分鐘。',
      aiRole: 'Barista',
      aiRoleZh: '咖啡店員',
      userRole: 'Student Customer',
      userRoleZh: '學生顧客',
      stages: <String>[
        'Describe the order problem clearly',
        'Ask for a quick remake option',
        'Confirm drink details and add-ons',
        'Ask waiting time',
        'Confirm pickup and thank politely',
      ],
      stagesZh: <String>[
        '清楚描述訂單問題',
        '詢問快速重做方案',
        '確認飲料細節與加料',
        '詢問等待時間',
        '確認取餐並禮貌致謝',
      ],
    ),
    ConversationScenario(
      title: 'Supermarket Shopping',
      titleZh: '超市買菜',
      setting:
          'You are shopping for dinner ingredients at a supermarket with a fixed budget.',
      settingZh: '你在超市買晚餐食材，且有固定預算。',
      aiRole: 'Store Assistant',
      aiRoleZh: '超市店員',
      userRole: 'Shopper',
      userRoleZh: '購物顧客',
      stages: <String>[
        'Ask where to find an item',
        'Compare brands or prices',
        'Ask about discounts',
        'Decide quantity',
        'Confirm checkout choice',
      ],
      stagesZh: <String>[
        '詢問商品在哪裡',
        '比較品牌或價格',
        '詢問是否有折扣',
        '決定購買數量',
        '確認結帳方式',
      ],
    ),
    ConversationScenario(
      title: 'Library Service Desk',
      titleZh: '圖書館櫃台',
      setting:
          'You are at a library service desk to borrow, renew, or reserve books.',
      settingZh: '你在圖書館櫃台借書、續借或預約書。',
      aiRole: 'Librarian',
      aiRoleZh: '圖書館員',
      userRole: 'Student',
      userRoleZh: '學生',
      stages: <String>[
        'Explain what book you need',
        'Ask loan period and due date',
        'Ask about renewal rules',
        'Ask about reservation wait time',
        'Confirm next action',
      ],
      stagesZh: <String>[
        '說明你要找的書',
        '詢問借閱期限與到期日',
        '詢問續借規則',
        '詢問預約等待時間',
        '確認下一步',
      ],
    ),
    ConversationScenario(
      title: 'Clinic Appointment',
      titleZh: '診所掛號',
      setting:
          'You are calling a clinic to schedule an appointment and ask preparation details.',
      settingZh: '你打電話到診所掛號，並詢問看診前準備事項。',
      aiRole: 'Receptionist',
      aiRoleZh: '櫃台人員',
      userRole: 'Patient',
      userRoleZh: '病人',
      stages: <String>[
        'Describe your main symptom',
        'Ask available time slots',
        'Confirm doctor and department',
        'Ask what to bring',
        'Confirm appointment details',
      ],
      stagesZh: <String>[
        '描述主要症狀',
        '詢問可預約時段',
        '確認醫師與科別',
        '詢問需攜帶文件',
        '確認預約細節',
      ],
    ),
    ConversationScenario(
      title: 'Restaurant Reservation',
      titleZh: '餐廳訂位',
      setting:
          'You are booking a restaurant table for a small group with seating preferences.',
      settingZh: '你要為小團體訂位，並有座位偏好。',
      aiRole: 'Restaurant Host',
      aiRoleZh: '餐廳接待',
      userRole: 'Guest',
      userRoleZh: '訂位客人',
      stages: <String>[
        'Request date and time',
        'Confirm number of people',
        'Ask for seating preference',
        'Check special requests',
        'Confirm booking name and contact',
      ],
      stagesZh: <String>[
        '提出日期與時間需求',
        '確認用餐人數',
        '詢問座位偏好',
        '確認特殊需求',
        '確認訂位姓名與聯絡方式',
      ],
    ),
    ConversationScenario(
      title: 'Phone Plan Advice',
      titleZh: '手機方案諮詢',
      setting:
          'You are asking a telecom staff to choose a mobile plan that fits your usage.',
      settingZh: '你向電信人員詢問適合自己使用習慣的手機方案。',
      aiRole: 'Telecom Staff',
      aiRoleZh: '電信客服',
      userRole: 'Customer',
      userRoleZh: '客戶',
      stages: <String>[
        'Describe your monthly usage',
        'Compare plan options',
        'Ask about hidden fees',
        'Check contract length',
        'Choose and confirm plan',
      ],
      stagesZh: <String>[
        '說明每月使用需求',
        '比較方案內容',
        '詢問額外費用',
        '確認合約期間',
        '選擇並確認方案',
      ],
    ),
    ConversationScenario(
      title: 'Landlord Maintenance Request',
      titleZh: '房東維修聯絡',
      setting:
          'You are messaging your landlord about a home maintenance problem.',
      settingZh: '你正在聯絡房東處理家中維修問題。',
      aiRole: 'Landlord',
      aiRoleZh: '房東',
      userRole: 'Tenant',
      userRoleZh: '房客',
      stages: <String>[
        'Describe the issue clearly',
        'Explain urgency and impact',
        'Ask available repair time',
        'Confirm who pays for repair',
        'Confirm appointment details',
      ],
      stagesZh: <String>[
        '清楚描述問題',
        '說明急迫性與影響',
        '詢問可維修時段',
        '確認費用由誰負擔',
        '確認到府時間',
      ],
    ),
    ConversationScenario(
      title: 'Class Registration Help',
      titleZh: '課程加退選諮詢',
      setting:
          'You are asking academic staff about adding a class and schedule conflicts.',
      settingZh: '你向教務人員詢問加選課程與時段衝突問題。',
      aiRole: 'Academic Staff',
      aiRoleZh: '教務人員',
      userRole: 'Student',
      userRoleZh: '學生',
      stages: <String>[
        'State the class you want',
        'Explain your schedule conflict',
        'Ask alternative sections',
        'Check registration deadline',
        'Confirm required steps',
      ],
      stagesZh: <String>[
        '說明想加選的課程',
        '解釋時段衝突',
        '詢問替代班別',
        '確認加退選期限',
        '確認辦理流程',
      ],
    ),
  ];

  void _showSnackBarSafe(String message) {
    if (!mounted || _isDisposed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposed) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger.showSnackBar(SnackBar(content: Text(message)));
    });
  }

  @override
  void initState() {
    super.initState();
    _ttsInitFuture = _initTts();
    _initStt();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionStarted) return;
    _sessionStarted = true;
    _startSession();
  }

  Future<void> _initTts() async {
    _tts = FlutterTts();
    await _tts.setLanguage("en-US"); // Default to English for now
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _ensureTtsReady() async {
    try {
      await _ttsInitFuture;
    } catch (_) {}
  }

  Future<void> _loadTtsVoices() async {
    await _ensureTtsReady();
    if (_ttsVoices != null) return;
    try {
      final raw = await _tts.getVoices;
      final voices = <Map<String, String>>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            final name = (item['name'] ?? '').toString().trim();
            final locale = (item['locale'] ?? '').toString().trim();
            if (name.isNotEmpty && locale.isNotEmpty) {
              voices.add({'name': name, 'locale': locale});
            }
          }
        }
      }
      _ttsVoices = voices;
    } catch (_) {
      _ttsVoices = const <Map<String, String>>[];
    }
  }

  Future<void> _setAiLikeVoiceIfAvailable() async {
    await _loadTtsVoices();
    final voices = _ttsVoices ?? const <Map<String, String>>[];
    if (voices.isEmpty) return;
    Map<String, String>? picked;
    for (final v in voices) {
      final name = (v['name'] ?? '').toLowerCase();
      final locale = (v['locale'] ?? '').toLowerCase();
      final isEnglish = locale.startsWith('en');
      if (!isEnglish) continue;
      if (name.contains('neural') ||
          name.contains('enhanced') ||
          name.contains('premium') ||
          name.contains('wavenet')) {
        picked = v;
        break;
      }
    }
    if (picked == null) {
      for (final v in voices) {
        final locale = (v['locale'] ?? '').toLowerCase();
        if (locale.startsWith('en-us') || locale.startsWith('en')) {
          picked = v;
          break;
        }
      }
    }
    if (picked == null) return;
    _aiLikeVoiceName = picked['name'];
    _aiLikeVoiceLocale = picked['locale'];
    try {
      await _tts.setVoice(<String, String>{
        'name': _aiLikeVoiceName!,
        'locale': _aiLikeVoiceLocale!,
      });
    } catch (_) {}
  }

  Future<void> _setDefaultVoice() async {
    await _ensureTtsReady();
    try {
      await _tts.setLanguage('en-US');
    } catch (_) {}
  }

  Future<void> _speakQuestion(String text, {bool preferAiLikeVoice = false}) async {
    final value = text.trim();
    if (value.isEmpty) return;
    try {
      await _ensureTtsReady();
      if (preferAiLikeVoice) {
        await _setAiLikeVoiceIfAvailable().timeout(
          const Duration(milliseconds: 800),
          onTimeout: () async {
            await _setDefaultVoice();
          },
        );
      } else {
        await _setDefaultVoice();
      }
      await AiTtsService.stop();
      await _tts.stop();
      await _tts.speak(value);
    } catch (_) {}
  }

  Future<void> _initStt() async {
    _stt = SpeechToText();
    try {
      _sttAvailable = await _stt.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("STT init error: $e");
    }
  }

  Future<void> _startSession() async {
    final l10n = AppLocalizations.of(context);
    final apiKey = ref.read(geminiKeyProvider);
    if (apiKey.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBarSafe(l10n.geminiApiKeyNotSet);
      }
      return;
    }

    final studySet = ref.read(studySetsProvider.notifier).getById(widget.setId);
    if (studySet == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    final terms = studySet.cards
        .map((c) => c.term)
        .where((t) => t.isNotEmpty)
        .toList();
    final termToDefinition = <String, String>{};
    for (final card in studySet.cards) {
      final term = card.term.trim();
      final definition = card.definition.trim();
      if (term.isEmpty || definition.isEmpty) continue;
      termToDefinition.putIfAbsent(term, () => definition);
    }
    terms.shuffle();
    final targetCount = min(terms.length, max(8, widget.turns * 2));
    final targetTerms = terms.take(targetCount).toList();
    final dedupedTargetTerms = <String>[];
    final seenNormalizedTerms = <String>{};
    for (final term in targetTerms) {
      final normalized = _normalizeForMatch(term);
      if (normalized.isEmpty || seenNormalizedTerms.contains(normalized)) {
        continue;
      }
      seenNormalizedTerms.add(normalized);
      dedupedTargetTerms.add(term);
    }
    _targetTerms = dedupedTargetTerms;
    _targetTermDefinitions
      ..clear()
      ..addEntries(
        dedupedTargetTerms.map(
          (t) => MapEntry(t, termToDefinition[t] ?? ''),
        ),
      );
    _practicedTerms.clear();
    _suggestedReplies = <ConversationReplySuggestion>[];
    _suggestionCache.clear();
    _latestReplyHint = '';
    _didPlayFirstAiLine = false;
    _focusCursor = 0;
    _chatMinGapMs = 900;
    _chatApiCalls = 0;
    _suggestionApiCalls = 0;
    _rateLimitCooldownUntil = null;
    _useLocalCoachOnly = false;
    _isQuotaExhausted = false;
    _consecutiveApiFailures = 0;
    _lastApiErrorNoticeAt = null;
    _lastAiQuestionText = '';
    _firstAiQuestionText = '';

    final random = Random();
    var picked = random.nextInt(_localScenarioPool.length);
    if (_localScenarioPool.length > 1 && picked == _lastScenarioIndex) {
      picked = (picked + 1 + random.nextInt(_localScenarioPool.length - 1)) %
          _localScenarioPool.length;
    }
    _lastScenarioIndex = picked;
    _scenario = _localScenarioPool[picked];

    _chatSession = GeminiService.startConversation(
      apiKey: apiKey,
      terms: dedupedTargetTerms,
      difficulty: widget.difficulty,
      scenarioTitle: _scenario.title,
      scenarioSetting: _scenario.setting,
      aiRole: _scenario.aiRole,
      userRole: _scenario.userRole,
    );

    setState(() => _isLoading = true);
    await _sendMessageToAi(
      '',
      addToUi: false,
      isFirstTurn: true,
      speakOutLoud: false,
    );
    await _prepareFirstAiLineAudioBeforeEntering().timeout(
      const Duration(milliseconds: 1200),
      onTimeout: () async {},
    );
    if (mounted) {
      setState(() => _isLoading = false);
      _speakLatestAiQuestionOnce();
    }
  }

  Future<void> _prepareFirstAiLineAudioBeforeEntering() async {
    if (!mounted || _isDisposed || _messages.isEmpty) return;
    final last = _messages.last;
    if (last.sender != Sender.ai) return;
    final text = last.text.trim();
    if (text.isEmpty) return;
    _firstAiQuestionText = text;
    final apiKey = ref.read(geminiKeyProvider);
    if (apiKey.isEmpty || _useLocalCoachOnly) return;
    try {
      await AiTtsService.prepareFirstLineAudio(
        apiKey: apiKey,
        text: text,
      );
    } catch (_) {}
  }

  Future<void> _sendMessageToAi(
    String text, {
    required bool addToUi,
    bool isFirstTurn = false,
    bool allowRateLimitRetry = true,
    bool speakOutLoud = true,
  }) async {
    if (_chatSession == null || _isAiTyping || _isSessionEnded) return;
    if (_isQuotaExhausted || _useLocalCoachOnly) {
      if (addToUi) {
        setState(() {
          _messages.add(ChatMessage(sender: Sender.user, text: text));
          _clearInputText();
          _suggestedReplies = <ConversationReplySuggestion>[];
        });
      }
      _appendLocalCoachTurn(userText: text);
      return;
    }
    if (_isInRateCooldown() || !_canUseRemoteChat()) {
      _appendLocalCoachTurn(userText: text);
      return;
    }
    final usedNow = addToUi ? _extractUsedTargetTerms(text) : <String>{};
    if (usedNow.isNotEmpty) {
      _practicedTerms.addAll(usedNow);
    }
    final turnWordCount = _targetTermsPerTurn();
    final turnStartCursor = _focusCursor;
    _advanceFocusCursor(turnWordCount);
    final payload = _buildPromptWithCoverageHint(
      text,
      addToUi: addToUi,
      isFirstTurn: isFirstTurn,
      fixedPriorityTerms: _nextPriorityTerms(
        count: turnWordCount,
        startOffset: turnStartCursor,
      ),
    );

    if (addToUi) {
      setState(() {
        _messages.add(ChatMessage(sender: Sender.user, text: text));
        _clearInputText();
        _isAiTyping = true;
        _suggestedReplies = <ConversationReplySuggestion>[];
      });
      _scrollToBottom();
    } else {
      setState(() => _isAiTyping = true);
    }

    try {
      await _respectChatRateLimit();
      _chatApiCalls++;
      final stopwatch = Stopwatch()..start();
      final response = await _chatSession!.sendMessage(Content.text(payload));
      stopwatch.stop();
      _logApiUsage(
        endpoint: 'chat_turn',
        phase: 'success',
        requestChars: payload.length,
        responseChars: (response.text ?? '').length,
        elapsed: stopwatch.elapsed,
      );
      final parsed = _parseAiTurnContent(response.text ?? '');
      final aiText = parsed.question;

      if (!mounted) return;

      setState(() {
        _isAiTyping = false;
        _latestReplyHint = parsed.replyHint;
        _suggestedReplies = <ConversationReplySuggestion>[];
        _consecutiveApiFailures = 0;
        _chatMinGapMs = 900;
        if (aiText.isNotEmpty) {
          _messages.add(ChatMessage(sender: Sender.ai, text: aiText));
          _lastAiQuestionText = aiText;
          _currentTurn++;
        }
      });
      _scrollToBottom();

      // Speak question only; don't block UI transition.
      if (aiText.isNotEmpty && speakOutLoud) {
        _speakWithLock(() => _speakQuestion(aiText));
      }

      // Check turn limit
      if (_currentTurn >= widget.turns) {
        // End session
        setState(() => _isSessionEnded = true);
        _showSummary();
      }
    } on GenerativeAIException catch (e) {
      if (!mounted) return;
      final rawError = e.toString();
      _logApiUsage(
        endpoint: 'chat_turn',
        phase: 'error',
        requestChars: payload.length,
        responseChars: 0,
        elapsed: Duration.zero,
        note: _shortApiError(rawError),
      );
      final issueType = _classifyApiIssue(rawError);
      setState(() => _isAiTyping = false);
      final l10n = AppLocalizations.of(context);
      if (issueType == _ApiIssueType.hardQuota) {
        _isQuotaExhausted = true;
        _showSnackBarSafe(l10n.scanQuotaExceeded);
        _appendLocalCoachTurn(userText: text);
      } else if (issueType == _ApiIssueType.rateLimit) {
        _startRateCooldown();
        _useLocalCoachOnly = true;
        _noticeLocalCoachFallback();
        _showSnackBarSafe('Rate limited. Switched to local coach for this session.');
        _appendLocalCoachTurn(userText: text);
      } else if (issueType == _ApiIssueType.auth) {
        _consecutiveApiFailures++;
        if (_consecutiveApiFailures >= 2) {
          _useLocalCoachOnly = true;
          _noticeLocalCoachFallback();
        }
        _showSnackBarSafe('API auth error: check API key/project permission.');
      } else {
        _consecutiveApiFailures++;
        if (_consecutiveApiFailures >= 2) {
          _useLocalCoachOnly = true;
          _noticeLocalCoachFallback();
          _appendLocalCoachTurn(userText: text);
          return;
        }
        _showSnackBarSafe(_shortApiError(rawError));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAiTyping = false);
      final l10n = AppLocalizations.of(context);
      _consecutiveApiFailures++;
      if (_consecutiveApiFailures >= 2) {
        _useLocalCoachOnly = true;
        _noticeLocalCoachFallback();
        _appendLocalCoachTurn(userText: text);
        return;
      }
      _showSnackBarSafe(l10n.scanNetworkError);
    }
  }

  void _speakLatestAiQuestionOnce() {
    if (!mounted || _messages.isEmpty) return;
    if (_didPlayFirstAiLine) return;
    final last = _messages.last;
    if (last.sender != Sender.ai || last.text.trim().isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _didPlayFirstAiLine = true;
      _firstAiQuestionText = last.text.trim();
      _speakWithLock(() => _speakQuestion(last.text));
      _prepareFirstAiLineAudioInBackground(last.text);
    });
  }

  Future<void> _speakAiMessage(String text) async {
    final value = text.trim();
    if (value.isEmpty) return;
    final isFirstLine =
        _firstAiQuestionText.isNotEmpty && value == _firstAiQuestionText;
    try {
      if (isFirstLine) {
        final playedFromCache = await AiTtsService.speakCached(text: value);
        if (playedFromCache) return;
        await _speakQuestion(value);
        return;
      }
      await _speakQuestion(value);
    } catch (_) {
      await _speakQuestion(value);
    }
  }

  Future<void> _speakFirstLineWithAiTtsFallback(String text) async {
    final value = text.trim();
    if (value.isEmpty) return;
    var spokeWithAiTts = false;
    final apiKey = ref.read(geminiKeyProvider);
    if (apiKey.isNotEmpty && !_useLocalCoachOnly) {
      try {
        await _ensureTtsReady();
        await _tts.stop();
        spokeWithAiTts = await AiTtsService.speakFirstLine(
          apiKey: apiKey,
          text: value,
        ).timeout(
          const Duration(milliseconds: 1800),
          onTimeout: () => false,
        );
      } catch (_) {
        spokeWithAiTts = false;
      }
    }
    if (!spokeWithAiTts) {
      await _speakQuestion(value);
    }
  }

  Future<void> _speakWithLock(Future<void> Function() task) async {
    if (_isDisposed) return;
    final now = DateTime.now();
    final last = _lastSpeechAt;
    if (last != null && now.difference(last).inMilliseconds < 250) return;
    if (_isSpeechBusy) return;
    _isSpeechBusy = true;
    _lastSpeechAt = now;
    try {
      await task().timeout(const Duration(seconds: 6), onTimeout: () async {});
    } finally {
      _isSpeechBusy = false;
    }
  }

  void _prepareFirstAiLineAudioInBackground(String text) {
    final value = text.trim();
    if (value.isEmpty || _isDisposed) return;
    final apiKey = ref.read(geminiKeyProvider);
    if (apiKey.isEmpty || _useLocalCoachOnly) return;
    AiTtsService.prepareFirstLineAudio(apiKey: apiKey, text: value).catchError((_) {});
  }

  int _estimateTokensFromChars(int chars) {
    if (chars <= 0) return 0;
    return (chars / 4).ceil();
  }

  void _logApiUsage({
    required String endpoint,
    required String phase,
    required int requestChars,
    required int responseChars,
    required Duration elapsed,
    String note = '',
  }) {
    final reqTok = _estimateTokensFromChars(requestChars);
    final respTok = _estimateTokensFromChars(responseChars);
    final totalTok = reqTok + respTok;
    debugPrint(
      '[AI_USAGE] endpoint=$endpoint phase=$phase '
      'reqChars=$requestChars respChars=$responseChars '
      'reqTok~$reqTok respTok~$respTok totalTok~$totalTok '
      'elapsedMs=${elapsed.inMilliseconds} note="$note"',
    );
  }

  void _noticeLocalCoachFallback() {
    final now = DateTime.now();
    final last = _lastApiErrorNoticeAt;
    if (last != null && now.difference(last).inSeconds < 8) return;
    _lastApiErrorNoticeAt = now;
    _showSnackBarSafe('AI service unstable. Switched to local coach mode for this session.');
  }

  void _handleUserSubmit() {
    if (_isAiTyping || _isSessionEnded) return;
    final text = _currentInputText().trim();
    if (text.isEmpty) return;
    _sendMessageToAi(text, addToUi: true);
  }

  String _currentInputText() {
    if (_isDisposed) return '';
    try {
      return _textController.text;
    } catch (_) {
      return '';
    }
  }

  void _clearInputText() {
    if (_isDisposed) return;
    try {
      _textController.clear();
    } catch (_) {}
  }

  void _setInputText(String value) {
    if (_isDisposed) return;
    try {
      _textController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    } catch (_) {}
  }

  _ApiIssueType _classifyApiIssue(String raw) {
    final msg = raw.toLowerCase();
    final rateLimited = msg.contains('429') ||
        msg.contains('rate limit') ||
        msg.contains('rate_limit') ||
        msg.contains('too many requests') ||
        msg.contains('per minute') ||
        msg.contains('requests per minute');
    if (rateLimited) return _ApiIssueType.rateLimit;

    final hardQuota = msg.contains('resource_exhausted') ||
        msg.contains('resource has been exhausted') ||
        (msg.contains('quota') && msg.contains('per day'));
    if (hardQuota) return _ApiIssueType.hardQuota;

    if (_isAuthError(raw)) return _ApiIssueType.auth;
    if (msg.contains('api')) return _ApiIssueType.other;
    return _ApiIssueType.none;
  }

  Future<void> _respectChatRateLimit() async {
    final now = DateTime.now();
    final last = _lastChatApiCallAt;
    if (last != null) {
      final gapMs = now.difference(last).inMilliseconds;
      if (gapMs < _chatMinGapMs) {
        await Future<void>.delayed(Duration(milliseconds: _chatMinGapMs - gapMs));
      }
    }
    _lastChatApiCallAt = DateTime.now();
  }

  Future<void> _respectSuggestionRateLimit() async {
    final now = DateTime.now();
    final last = _lastSuggestionApiCallAt;
    if (last != null) {
      final gapMs = now.difference(last).inMilliseconds;
      if (gapMs < 1800) {
        await Future<void>.delayed(Duration(milliseconds: 1800 - gapMs));
      }
    }
    _lastSuggestionApiCallAt = DateTime.now();
  }

  bool _isAuthError(String raw) {
    final msg = raw.toLowerCase();
    return msg.contains('api key not valid') ||
        msg.contains('permission denied') ||
        msg.contains('unauthenticated') ||
        msg.contains('401') ||
        msg.contains('403');
  }

  String _shortApiError(String raw) {
    final compact = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 110) return 'API error: $compact';
    return 'API error: ${compact.substring(0, 110)}...';
  }

  void _appendLocalCoachTurn({required String userText}) {
    if (!mounted || _isSessionEnded) return;
    final step = _scenario.stages.isEmpty
        ? 'continue the conversation'
        : _scenario.stages[_currentTurn % _scenario.stages.length];
    final wordCount = _targetTermsPerTurn();
    final focus = _nextPriorityTerms(count: wordCount);
    _advanceFocusCursor(wordCount);
    final lead = focus.isEmpty ? 'this situation' : focus.first;
    final extra = focus.length > 1 ? focus[1] : '';

    final easyTemplates = <String>[
      'At this point, what $lead do you want?',
      'What would you say about $lead now?',
      'How would you ask for $lead politely?',
    ];
    final mediumTemplates = <String>[
      'In this moment, what do you want to ask about $lead?',
      'How would you continue with $lead in this situation?',
      'What would your next sentence about $lead be?',
    ];
    final hardTemplates = <String>[
      'Given this step, how would you justify your choice about $lead?',
      'How would you ask about $lead while mentioning ${extra.isEmpty ? 'one concern' : extra}?',
      'What would you say next to move this conversation forward about $lead?',
    ];

    final templates = switch (widget.difficulty.toLowerCase().trim()) {
      'easy' => easyTemplates,
      'hard' => hardTemplates,
      _ => mediumTemplates,
    };
    var question = templates[_currentTurn % templates.length];
    question = '$question ($step)';
    if (userText.trim().isNotEmpty) {
      final clippedUser = userText.trim().length > 36
          ? '${userText.trim().substring(0, 36)}...'
          : userText.trim();
      question = 'You said "$clippedUser". Nice. $question';
    }
    if (question == _lastAiQuestionText) {
      question = '$question Also add ${extra.isEmpty ? 'one detail' : extra}.';
    }

    final hint = switch (widget.difficulty.toLowerCase().trim()) {
      'easy' => 'Start with "I need $lead because ..."',
      'hard' =>
        'Start with "I\'d choose $lead because ..., and ${extra.isEmpty ? 'it' : extra} ..."',
      _ => 'Start with "I want $lead because ..."',
    };

    setState(() {
      _latestReplyHint = hint;
      _messages.add(ChatMessage(sender: Sender.ai, text: question));
      _lastAiQuestionText = question;
      _currentTurn++;
      _isAiTyping = false;
    });
    _scrollToBottom();
    _tts.speak(question);

    if (_currentTurn >= widget.turns) {
      setState(() => _isSessionEnded = true);
      _showSummary();
    }
  }

  String _latestAiQuestion() {
    for (var i = _messages.length - 1; i >= 0; i--) {
      final message = _messages[i];
      if (message.sender == Sender.ai) return message.text;
    }
    return 'Could you answer based on this scenario?';
  }

  String _latestUserMessage() {
    for (var i = _messages.length - 1; i >= 0; i--) {
      final message = _messages[i];
      if (message.sender == Sender.user) return message.text;
    }
    return '';
  }

  Future<void> _generateSuggestedReplies() async {
    if (_isAiTyping || _isSessionEnded || _isGeneratingSuggestions) return;
    if (_isQuotaExhausted || _useLocalCoachOnly) {
      setState(() {
        _suggestedReplies = _buildLocalSuggestedReplies();
      });
      return;
    }
    if (_isInRateCooldown() || !_canUseRemoteSuggestion()) {
      setState(() {
        _suggestedReplies = _buildLocalSuggestedReplies();
      });
      return;
    }
    final cacheKey = _suggestionCacheKey();
    final cached = _suggestionCache[cacheKey];
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _suggestedReplies = cached;
      });
      return;
    }
    final apiKey = ref.read(geminiKeyProvider);
    if (apiKey.isEmpty) return;
    setState(() => _isGeneratingSuggestions = true);
    try {
      await _respectSuggestionRateLimit();
      _suggestionApiCalls++;
      final latestQuestion = _latestAiQuestion();
      final priorityTerms = _nextPriorityTerms();
      final stopwatch = Stopwatch()..start();
      final suggestions = await GeminiService.generateSuggestedReplies(
        apiKey: apiKey,
        difficulty: widget.difficulty,
        scenarioTitle: _scenario.title,
        aiRole: _scenario.aiRole,
        userRole: _scenario.userRole,
        latestQuestion: latestQuestion,
        priorityTerms: priorityTerms,
      );
      stopwatch.stop();
      _logApiUsage(
        endpoint: 'reply_suggestions',
        phase: 'success',
        requestChars:
            '${_scenario.title}|${widget.difficulty}|$latestQuestion|${priorityTerms.join(",")}'.length,
        responseChars: suggestions.map((e) => e.reply).join('\n').length,
        elapsed: stopwatch.elapsed,
      );
      if (!mounted) return;
      setState(() {
        _suggestedReplies = suggestions;
        _suggestionCache[cacheKey] = suggestions;
        _isGeneratingSuggestions = false;
      });
    } catch (_) {
      _logApiUsage(
        endpoint: 'reply_suggestions',
        phase: 'error',
        requestChars: 0,
        responseChars: 0,
        elapsed: Duration.zero,
      );
      if (!mounted) return;
      setState(() => _isGeneratingSuggestions = false);
    }
  }

  bool _isInRateCooldown() {
    final until = _rateLimitCooldownUntil;
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  bool _canUseRemoteChat() {
    final maxCalls = max(widget.turns + 2, 8);
    return _chatApiCalls < maxCalls;
  }

  bool _canUseRemoteSuggestion() {
    return _suggestionApiCalls < 3;
  }

  String _suggestionCacheKey() {
    final q = _latestAiQuestion().toLowerCase().trim();
    final focus = _nextPriorityTerms(count: _targetTermsPerTurn()).join('|');
    return '$q::$focus::${widget.difficulty}';
  }

  void _startRateCooldown() {
    _rateLimitCooldownUntil = DateTime.now().add(const Duration(seconds: 20));
    _chatMinGapMs = 2800;
  }

  List<ConversationReplySuggestion> _buildLocalSuggestedReplies() {
    final focus = _nextPriorityTerms(count: _targetTermsPerTurn());
    final first = focus.isEmpty ? 'this option' : focus.first;
    final second = focus.length > 1 ? focus[1] : 'the details';
    return <ConversationReplySuggestion>[
      ConversationReplySuggestion(
        reply: 'Could you help me with $first?',
        zhHint: '先禮貌開場',
        focusWord: first,
      ),
      ConversationReplySuggestion(
        reply: 'I\'d go with $first because it fits me better.',
        zhHint: '補一個簡短原因',
        focusWord: first,
      ),
      ConversationReplySuggestion(
        reply: 'Do you also have $second, by any chance?',
        zhHint: '自然追問延伸',
        focusWord: second,
      ),
      ConversationReplySuggestion(
        reply: 'Sounds good, I\'ll take $first.',
        zhHint: '用一句話收尾',
        focusWord: first,
      ),
    ];
  }

  Future<void> _toggleListening() async {
    if (!_sttAvailable || _isDisposed) return;

    if (_isListening) {
      await _stt.stop();
      if (!mounted || _isDisposed) return;
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _stt.listen(
        onResult: (result) {
          if (!mounted || _isDisposed) return;
          setState(() {
            _setInputText(result.recognizedWords);
          });
          if (result.finalResult) {
            if (!mounted || _isDisposed) return;
            setState(() => _isListening = false);
          }
        },
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposed) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showSummary() async {
    if (!mounted || _isDisposed || _isShowingSummary) return;
    _isShowingSummary = true;
    final l10n = AppLocalizations.of(context);
    final practicedCount = _practicedTerms.length;
    final totalTarget = _targetTerms.length;
    final coverage = totalTarget == 0
        ? 0
        : (practicedCount / totalTarget * 100).round().clamp(0, 100);
    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.practiceComplete),
          content: Text(
            '${l10n.completedNTurns(widget.turns)}\nCoverage: $coverage% ($practicedCount/$totalTarget)',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.done),
            ),
          ],
        ),
      );
      if (!mounted || _isDisposed) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _isDisposed) return;
        if (context.canPop()) {
          context.pop();
        }
      });
    } finally {
      _isShowingSummary = false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tts.stop();
    AiTtsService.stop();
    _stt.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardInset > 0;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text('${l10n.conversationPractice} ($_currentTurn/${widget.turns})'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (!isKeyboardOpen) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: _buildScenarioPanel(theme),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _buildApiGuardPanel(theme),
                  ),
                  if (_targetTerms.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _buildCoveragePanel(theme),
                    ),
                ],
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isAiTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Center(child: CircularProgressIndicator()),
                        ); // Typing indicator
                      }
                      final msg = _messages[index];
                      return _buildMessageBubble(msg, theme);
                    },
                  ),
                ),
                if (!_isSessionEnded)
                  Container(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        isKeyboardOpen ? 8 : 16,
                        16,
                        isKeyboardOpen ? 8 : 16,
                      ),
                      color: theme.colorScheme.surface,
                      child: SafeArea(
                        top: false,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: isKeyboardOpen ? 120 : 340,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isKeyboardOpen &&
                                    _latestReplyHint.trim().isNotEmpty)
                                  _buildReplyHintPanel(theme),
                                if (!isKeyboardOpen)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          _isAiTyping ||
                                              _isSessionEnded ||
                                              _isGeneratingSuggestions
                                          ? null
                                          : _generateSuggestedReplies,
                                      icon: _isGeneratingSuggestions
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.auto_awesome_rounded,
                                              size: 18,
                                            ),
                                      label: const Text('Help me reply'),
                                    ),
                                  ),
                                if (!isKeyboardOpen &&
                                    _suggestedReplies.isNotEmpty)
                                  _buildSuggestedRepliesPanel(theme),
                                Row(
                                  children: [
                                    if (_sttAvailable)
                                      IconButton.filledTonal(
                                        onPressed: _toggleListening,
                                        icon: Icon(
                                          _isListening
                                              ? Icons.mic
                                              : Icons.mic_none,
                                        ),
                                        color: _isListening
                                            ? theme.colorScheme.error
                                            : null,
                                      ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: _textController,
                                        decoration: InputDecoration(
                                          hintText: 'Type your answer...',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(24),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                        ),
                                        onSubmitted: (_) => _handleUserSubmit(),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton.filled(
                                      onPressed:
                                          _isAiTyping ||
                                              _isSessionEnded ||
                                              _currentInputText()
                                                  .trim()
                                                  .isEmpty
                                          ? null
                                          : _handleUserSubmit,
                                      icon: const Icon(Icons.send_rounded),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, ThemeData theme) {
    final isAi = msg.sender == Sender.ai;
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isAi
              ? theme.colorScheme.secondaryContainer
              : theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAi ? _scenario.aiRole : 'You',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isAi
                    ? theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.7)
                    : theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.text,
              style: TextStyle(
                color: isAi
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onPrimaryContainer,
              ),
            ),
            if (isAi)
              GestureDetector(
                onTap: () => _speakWithLock(() => _speakAiMessage(msg.text)),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.volume_up_rounded,
                    size: 16,
                    color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioPanel(ThemeData theme) {
    final step = _scenario.stages.isEmpty
        ? 'Continue the conversation.'
        : _scenario.stages[_currentTurn % _scenario.stages.length];
    final stepZh = _scenario.stagesZh.isEmpty
        ? ''
        : _scenario.stagesZh[_currentTurn % _scenario.stagesZh.length];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scenario: ${_scenario.title}',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            '情境：${_scenario.titleZh}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text('AI Role: ${_scenario.aiRole}', style: theme.textTheme.bodySmall),
          Text('AI 角色：${_scenario.aiRoleZh}', style: theme.textTheme.bodySmall),
          Text('Your Role: ${_scenario.userRole}', style: theme.textTheme.bodySmall),
          Text('你的角色：${_scenario.userRoleZh}', style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            _scenario.setting,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            _scenario.settingZh,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text('Current Step: $step', style: theme.textTheme.bodySmall),
          if (stepZh.isNotEmpty)
            Text('目前步驟：$stepZh', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildReplyHintPanel(ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_rounded,
            size: 18,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _latestReplyHint,
              style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _setInputText(_latestReplyHint);
              });
            },
            child: const Text('Use'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedRepliesPanel(ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Try one of these replies',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 170),
            child: SingleChildScrollView(
              child: Column(
                children: _suggestedReplies.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final suggestion = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$index.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                suggestion.reply,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (suggestion.zhHint.isNotEmpty)
                                Text(
                                  suggestion.zhHint,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              if (suggestion.focusWord.isNotEmpty)
                                Text(
                                  'Focus: ${suggestion.focusWord}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _setInputText(suggestion.reply);
                            });
                          },
                          child: const Text('Use'),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoveragePanel(ThemeData theme) {
    final practiced = _practicedTerms.length;
    final total = _targetTerms.length;
    final progress = total == 0 ? 0.0 : practiced / total;
    final remaining = _targetTerms.where((t) => !_practicedTerms.contains(t)).take(4).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Target Coverage',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$practiced / $total',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress.clamp(0.0, 1.0),
            ),
          ),
          if (remaining.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: remaining
                  .map(
                    (w) => Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(w),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  int _targetTermsPerTurn() {
    switch (widget.difficulty.toLowerCase().trim()) {
      case 'easy':
        return 1;
      case 'hard':
        return 3;
      default:
        return 2;
    }
  }

  int _remainingCooldownSeconds() {
    final until = _rateLimitCooldownUntil;
    if (until == null) return 0;
    final seconds = until.difference(DateTime.now()).inSeconds;
    return seconds > 0 ? seconds : 0;
  }

  Widget _buildApiGuardPanel(ThemeData theme) {
    final inCooldown = _isInRateCooldown();
    final cooldownLeft = _remainingCooldownSeconds();
    final mode = _useLocalCoachOnly
        ? 'Local Coach'
        : (_isQuotaExhausted ? 'Quota Limited' : 'Remote AI');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _tinyBadge(theme, 'Mode: $mode'),
          _tinyBadge(theme, 'Chat API: $_chatApiCalls'),
          _tinyBadge(theme, 'Ideas API: $_suggestionApiCalls'),
          if (inCooldown)
            _tinyBadge(theme, 'Cooldown: ${cooldownLeft}s'),
        ],
      ),
    );
  }

  Widget _tinyBadge(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(text, style: theme.textTheme.labelSmall),
    );
  }

  List<String> _nextPriorityTerms({int? count, int? startOffset}) {
    final targetCount = count ?? _targetTermsPerTurn();
    if (_targetTerms.isEmpty) return <String>[];
    final result = <String>[];
    var idx = startOffset ?? _focusCursor;
    var guard = 0;
    while (result.length < targetCount && guard < _targetTerms.length * 2) {
      final term = _targetTerms[idx % _targetTerms.length];
      if (!result.contains(term)) {
        result.add(term);
      }
      idx++;
      guard++;
    }
    return result;
  }

  void _advanceFocusCursor(int by) {
    if (_targetTerms.isEmpty) return;
    _focusCursor = (_focusCursor + by) % _targetTerms.length;
  }

  String _buildPromptWithCoverageHint(
    String userText, {
    required bool addToUi,
    required bool isFirstTurn,
    List<String>? fixedPriorityTerms,
  }) {
    final normalizedDifficulty = widget.difficulty.toLowerCase().trim();
    final difficultyPrompt = switch (normalizedDifficulty) {
      'easy' =>
        'EASY: 1 target word, very simple concrete question, highly guided hint.',
      'hard' =>
        'HARD: 2-3 target words, specific scenario question, shorter hint.',
      _ =>
        'MEDIUM: 1-2 target words, practical question, moderately guided hint.',
    };

    final priorityTerms = fixedPriorityTerms ?? _nextPriorityTerms();
    final fallbackCount = _targetTermsPerTurn();
    final focusTerms = priorityTerms.isEmpty
        ? _targetTerms.take(fallbackCount).toList()
        : priorityTerms;
    final focusText = focusTerms.isEmpty ? '' : focusTerms.join(', ');
    final meaningHints = focusTerms
        .map((t) {
          final def = (_targetTermDefinitions[t] ?? '').trim();
          if (def.isEmpty) return '';
          final shortDef = def.length > 14 ? '${def.substring(0, 14)}...' : def;
          return '$t:$shortDef';
        })
        .where((line) => line.isNotEmpty)
        .join(';');
    final studentInput = addToUi ? userText : '';
    final latestRaw = addToUi ? userText : _latestUserMessage();
    final latestUser = latestRaw.length > 160
        ? '${latestRaw.substring(0, 160)}...'
        : latestRaw;
    final stage = _scenario.stages.isEmpty
        ? 'Continue the conversation naturally.'
        : _scenario.stages[_currentTurn % _scenario.stages.length];

    final studentLine = isFirstTurn
        ? '(first turn)'
        : (studentInput.isEmpty ? '(empty)' : studentInput);
    return '''
Scenario: ${_scenario.title}
Roles: ${_scenario.aiRole} and ${_scenario.userRole}
Current step: $stage
Student message now: $studentLine
Latest student sentence: ${latestUser.isEmpty ? '(none)' : latestUser}
Use these target words: $focusText
Word notes: ${meaningHints.isEmpty ? 'N/A' : meaningHints}
Difficulty: ${widget.difficulty}
Style: $difficultyPrompt
Ask one natural follow-up question tied to the student's sentence.
Keep it short and practical.
Output exactly two lines:
Question: ...
Reply hint: Start with "..."
''';
  }

  AiTurnContent _parseAiTurnContent(String text) {
    var cleaned = text.trim();
    cleaned = cleaned.replaceFirst(
      RegExp(r'^(hi|hello|hey)\b[^\n]*\n?', caseSensitive: false),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'^\s*[-*]\s*', multiLine: true), '');

    String question = '';
    String hint = '';
    for (final line in cleaned.split('\n')) {
      final trimmed = line.trim();
      final lower = trimmed.toLowerCase();
      if (lower.startsWith('question:')) {
        question = trimmed.substring('question:'.length).trim();
      } else if (lower.startsWith('reply hint:')) {
        hint = trimmed.substring('reply hint:'.length).trim();
      }
    }

    if (question.isEmpty) {
      final lines = cleaned
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      question = lines.isEmpty
          ? 'What do you need in this situation?'
          : lines.first;
    }
    question = question.replaceFirst(RegExp(r'^(question:)\s*', caseSensitive: false), '').trim();

    if (hint.isEmpty) {
      final starterTerms = _nextPriorityTerms(count: 1);
      final starter = starterTerms.isEmpty ? 'I would like' : starterTerms.first;
      hint = 'Start with "$starter ..."';
    }
    hint = hint.replaceFirst(RegExp(r'^(reply hint:)\s*', caseSensitive: false), '').trim();

    return AiTurnContent(question: question, replyHint: hint);
  }

  Set<String> _extractUsedTargetTerms(String text) {
    final normalizedText = _normalizeForMatch(text);
    if (normalizedText.isEmpty || _targetTerms.isEmpty) return <String>{};
    final hits = <String>{};
    for (final term in _targetTerms) {
      final normalizedTerm = _normalizeForMatch(term);
      if (normalizedTerm.isEmpty) continue;
      if (_looksLatin(normalizedTerm)) {
        if (' $normalizedText '.contains(' $normalizedTerm ')) {
          hits.add(term);
        }
      } else if (normalizedText.contains(normalizedTerm)) {
        hits.add(term);
      }
    }
    return hits;
  }

  String _normalizeForMatch(String input) {
    final lower = input.toLowerCase().trim();
    if (lower.isEmpty) return '';
    return lower.replaceAll(_nonWordChars, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _looksLatin(String value) => _latinOrDigit.hasMatch(value);
}


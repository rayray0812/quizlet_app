import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/models/review_log.dart';
import 'package:recall_app/providers/stats_provider.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:uuid/uuid.dart';

class SpeakingPracticeScreen extends ConsumerStatefulWidget {
  final String setId;

  const SpeakingPracticeScreen({super.key, required this.setId});

  @override
  ConsumerState<SpeakingPracticeScreen> createState() =>
      _SpeakingPracticeScreenState();
}

class _SpeakingPracticeScreenState extends ConsumerState<SpeakingPracticeScreen> {
  late final FlutterTts _tts;
  late final SpeechToText _speech;
  bool _isTtsReady = false;
  bool _speechReady = false;
  bool _isListening = false;
  bool _isScoring = false;
  String _recognizedText = '';
  int? _lastAutoScore;
  Set<String>? _supportedLanguages;
  List<Map<String, String>>? _availableVoices;
  String? _activeLanguage;
  String? _activeVoiceKey;
  bool _isSpeaking = false;
  DateTime? _lastSpeakRequestedAt;
  bool _isPlaying = false;
  Future<void> _speakQueue = Future<void>.value();
  int _index = 0;
  String _lastAutoPlayedCardId = '';
  final Map<String, int> _scoresByCardId = {};

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();
  }

  @override
  void dispose() {
    if (_isTtsReady) {
      _isSpeaking = false;
      _tts.stop();
    }
    if (_isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  Future<void> _initTts() async {
    _tts = FlutterTts();
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      _isTtsReady = true;
    } catch (_) {
      _isTtsReady = false;
    }
  }

  Future<void> _initSpeech() async {
    _speech = SpeechToText();
    _speechReady = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _isListening = false);
      },
    );
  }

  String _pickLanguage(String text) {
    final hasJapaneseKana = RegExp(r'[\u3040-\u30FF]').hasMatch(text);
    if (hasJapaneseKana) return 'ja-JP';
    final hasChinese = RegExp(r'[\u3400-\u9FFF]').hasMatch(text);
    return hasChinese ? 'zh-TW' : 'en-US';
  }

  String _pickSpeechLanguage(Flashcard card) {
    final term = card.term.trim();
    final sentence = _buildSentence(card);
    final target = sentence.isNotEmpty ? sentence : term;
    final hasLatin = RegExp(r'[A-Za-z]').hasMatch(target);
    if (hasLatin) {
      return 'en-US';
    }
    return _pickLanguage('$term $sentence');
  }

  String _normalizeLocaleCode(String code) {
    return code.replaceAll('_', '-').toLowerCase();
  }

  Future<Set<String>> _loadSupportedLanguages() async {
    if (_supportedLanguages != null) return _supportedLanguages!;
    try {
      final langs = await _tts.getLanguages;
      final normalized = langs
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet();
      _supportedLanguages = normalized;
      return normalized;
    } catch (_) {
      _supportedLanguages = <String>{};
      return _supportedLanguages!;
    }
  }

  Future<List<Map<String, String>>> _loadAvailableVoices() async {
    if (_availableVoices != null) return _availableVoices!;
    try {
      final voices = await _tts.getVoices;
      final normalized = <Map<String, String>>[];
      for (final voice in voices) {
        if (voice is Map) {
          final name = voice['name']?.toString().trim() ?? '';
          final locale = voice['locale']?.toString().trim() ?? '';
          if (name.isNotEmpty && locale.isNotEmpty) {
            normalized.add({'name': name, 'locale': locale});
          }
        }
      }
      _availableVoices = normalized;
      return normalized;
    } catch (_) {
      _availableVoices = const <Map<String, String>>[];
      return _availableVoices!;
    }
  }

  Future<String?> _resolveLanguage(String preferred) async {
    final available = await _loadSupportedLanguages();
    if (available.isEmpty) return null;
    final lowerMap = <String, String>{
      for (final lang in available) _normalizeLocaleCode(lang): lang,
    };
    final normalizedPreferred = _normalizeLocaleCode(preferred);
    final candidates = preferred.startsWith('zh')
        ? <String>[preferred, 'zh-TW', 'zh-CN', 'zh']
        : preferred.startsWith('ja')
        ? <String>[preferred, 'ja-JP', 'ja']
        : <String>[preferred, 'en-US', 'en-GB', 'en'];
    for (final candidate in candidates) {
      final normalizedCandidate = _normalizeLocaleCode(candidate);
      final exact = lowerMap[normalizedCandidate];
      if (exact != null) return exact;
      final prefix = '$normalizedCandidate-';
      for (final entry in lowerMap.entries) {
        if (entry.key == normalizedCandidate || entry.key.startsWith(prefix)) {
          return entry.value;
        }
      }
    }
    if (normalizedPreferred.startsWith('en')) {
      for (final entry in lowerMap.entries) {
        if (entry.key.startsWith('en')) return entry.value;
      }
    }
    if (normalizedPreferred.startsWith('ja')) {
      for (final entry in lowerMap.entries) {
        if (entry.key.startsWith('ja')) return entry.value;
      }
    }
    return null;
  }

  Future<Map<String, String>?> _resolveVoice(String preferred) async {
    final voices = await _loadAvailableVoices();
    if (voices.isEmpty) return null;
    final localeCandidates = preferred.startsWith('zh')
        ? <String>['zh-tw', 'zh-cn', 'zh']
        : preferred.startsWith('ja')
        ? <String>['ja-jp', 'ja']
        : <String>['en-us', 'en-gb', 'en-au', 'en'];
    for (final candidate in localeCandidates) {
      for (final voice in voices) {
        final locale = _normalizeLocaleCode(voice['locale']!);
        if (locale == candidate || locale.startsWith('$candidate-')) {
          return voice;
        }
      }
    }
    if (preferred.startsWith('en')) {
      for (final voice in voices) {
        final locale = _normalizeLocaleCode(voice['locale']!);
        if (locale.startsWith('en')) return voice;
      }
    }
    if (preferred.startsWith('ja')) {
      for (final voice in voices) {
        final locale = _normalizeLocaleCode(voice['locale']!);
        if (locale.startsWith('ja')) return voice;
      }
    }
    return null;
  }

  Future<void> _speak(String text, {bool userInitiated = false}) async {
    _speakQueue = _speakQueue.then(
      (_) => _speakInternal(text, userInitiated: userInitiated),
    );
    return _speakQueue;
  }

  Future<void> _speakInternal(String text, {bool userInitiated = false}) async {
    if (!_isTtsReady) {
      await _initTts();
      if (!_isTtsReady) return;
    }
    final value = text.trim();
    if (value.isEmpty) return;
    final now = DateTime.now();
    final lastAt = _lastSpeakRequestedAt;
    if (!userInitiated &&
        lastAt != null &&
        now.difference(lastAt).inMilliseconds < 120) {
      return;
    }
    _lastSpeakRequestedAt = now;
    try {
      if (_isSpeaking) {
        await _tts.stop();
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
      final resolved = await _resolveLanguage(_pickLanguage(value));
      if (resolved != null && resolved != _activeLanguage) {
        try {
          await _tts.setLanguage(resolved);
          _activeLanguage = resolved;
        } catch (_) {}
      }
      final voice = await _resolveVoice(_pickLanguage(value));
      if (voice != null) {
        final voiceKey = '${voice['name']}|${voice['locale']}';
        if (voiceKey != _activeVoiceKey) {
          try {
            await _tts.setVoice(voice);
            _activeVoiceKey = voiceKey;
          } catch (_) {}
        }
      }
      _isSpeaking = true;
      await _tts.speak(value);
    } catch (_) {
    } finally {
      _isSpeaking = false;
    }
  }

  String _buildSentence(Flashcard card) {
    final example = card.exampleSentence.trim();
    if (example.isNotEmpty) {
      return example;
    }
    final term = card.term.trim();
    if (term.isEmpty) return '';
    final language = _pickLanguage(term);
    if (language.startsWith('ja')) {
      return '$termを毎日使います。';
    }
    if (language.startsWith('zh')) {
      return '我每天都會用$term。';
    }
    return 'I use $term every day.';
  }

  bool _hasCustomExample(Flashcard card) {
    return card.exampleSentence.trim().isNotEmpty;
  }

  bool _isAutoGeneratedExample(Flashcard card) {
    return card.exampleSentence.trim().isEmpty;
  }

  String _buildAutoScoreTarget(Flashcard card) {
    final sentence = _buildSentence(card).trim();
    if (sentence.isEmpty) {
      return card.term.trim();
    }
    return '${card.term.trim()} $sentence';
  }

  String _normalizeForCompare(String input) {
    final lower = input.toLowerCase();
    final cleaned = lower.replaceAll(
      RegExp(r'[^a-z0-9\u3040-\u30FF\u3400-\u9FFF\s]'),
      ' ',
    );
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  int _levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final rows = a.length + 1;
    final cols = b.length + 1;
    final dp = List.generate(rows, (_) => List<int>.filled(cols, 0));
    for (var i = 0; i < rows; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j < cols; j++) {
      dp[0][j] = j;
    }
    for (var i = 1; i < rows; i++) {
      for (var j = 1; j < cols; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = min(
          min(dp[i - 1][j] + 1, dp[i][j - 1] + 1),
          dp[i - 1][j - 1] + cost,
        );
      }
    }
    return dp[a.length][b.length];
  }

  double _similarity(String target, String spoken) {
    final t = _normalizeForCompare(target);
    final s = _normalizeForCompare(spoken);
    if (t.isEmpty || s.isEmpty) return 0;
    final dist = _levenshtein(t, s);
    final charSim = 1 - (dist / max(t.length, s.length));
    final targetWords = t.split(' ').where((e) => e.isNotEmpty).toSet();
    final spokenWords = s.split(' ').where((e) => e.isNotEmpty).toSet();
    final hasWordLevel = targetWords.length > 1 || spokenWords.length > 1;
    if (!hasWordLevel) return charSim.clamp(0.0, 1.0);
    final overlap = targetWords.intersection(spokenWords).length;
    final wordSim = targetWords.isEmpty ? 0.0 : overlap / targetWords.length;
    return ((charSim * 0.55) + (wordSim * 0.45)).clamp(0.0, 1.0);
  }

  int _scoreFromSimilarity(double sim) {
    if (sim >= 0.92) return 5;
    if (sim >= 0.78) return 4;
    if (sim >= 0.62) return 3;
    if (sim >= 0.45) return 2;
    if (sim > 0) return 1;
    return 0;
  }

  Future<String?> _resolveSpeechLocale(String preferred) async {
    final locales = await _speech.locales();
    if (locales.isEmpty) return null;
    final byNormalized = <String, String>{
      for (final locale in locales)
        _normalizeLocaleCode(locale.localeId): locale.localeId,
    };
    final normalizedPreferred = _normalizeLocaleCode(preferred);
    final candidates = preferred.startsWith('zh')
        ? <String>[preferred, 'zh-TW', 'zh-CN', 'zh']
        : preferred.startsWith('ja')
        ? <String>[preferred, 'ja-JP', 'ja']
        : <String>[preferred, 'en-US', 'en-GB', 'en'];
    for (final candidate in candidates) {
      final normalized = _normalizeLocaleCode(candidate);
      final exact = byNormalized[normalized];
      if (exact != null) return exact;
      final prefix = '$normalized-';
      for (final entry in byNormalized.entries) {
        if (entry.key == normalized || entry.key.startsWith(prefix)) {
          return entry.value;
        }
      }
    }
    if (normalizedPreferred.startsWith('en')) {
      for (final entry in byNormalized.entries) {
        if (entry.key.startsWith('en')) return entry.value;
      }
    }
    if (normalizedPreferred.startsWith('ja')) {
      for (final entry in byNormalized.entries) {
        if (entry.key.startsWith('ja')) return entry.value;
      }
    }
    if (normalizedPreferred.startsWith('zh')) {
      for (final entry in byNormalized.entries) {
        if (entry.key.startsWith('zh')) return entry.value;
      }
    }
    return null;
  }

  Future<void> _startAutoScore(Flashcard card, List<Flashcard> cards) async {
    if (_isListening || _isScoring) return;
    if (!_speechReady) {
      await _initSpeech();
    }
    if (!_speechReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).speechRecognitionUnavailable),
        ),
      );
      return;
    }
    final localeId = await _resolveSpeechLocale(_pickSpeechLanguage(card));
    setState(() {
      _recognizedText = '';
      _lastAutoScore = null;
      _isListening = true;
    });
    await _speech.listen(
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
      ),
      pauseFor: const Duration(seconds: 2),
      listenFor: const Duration(seconds: 10),
      onResult: (result) async {
        if (!mounted) return;
        setState(() => _recognizedText = result.recognizedWords);
        if (result.finalResult) {
          await _finishAutoScore(card, cards);
        }
      },
    );
  }

  Future<void> _finishAutoScore(Flashcard card, List<Flashcard> cards) async {
    if (_isScoring) return;
    _isScoring = true;
    if (_isListening) {
      await _speech.stop();
    }
    final spoken = _recognizedText.trim();
    final sentence = _buildSentence(card);
    var score = 0;
    if (spoken.isNotEmpty) {
      final simTerm = _similarity(card.term, spoken);
      final simSentence = sentence.isEmpty ? 0.0 : _similarity(sentence, spoken);
      final simCombined = _similarity(_buildAutoScoreTarget(card), spoken);
      final targetSim = sentence.isEmpty
          ? max(simTerm, simCombined)
          : max(simSentence, simCombined);
      score = _scoreFromSimilarity(targetSim);
      if (score == 0) {
        score = 1;
      }
    }
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _lastAutoScore = score > 0 ? score : null;
    });
    if (score > 0) {
      await _rateCurrent(score, cards);
    }
    _isScoring = false;
  }

  Future<void> _playSequence(Flashcard card) async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    await _speak(card.term);
    final sentence = _buildSentence(card);
    if (sentence.isNotEmpty) {
      await _speak(sentence);
    }
    if (!mounted) return;
    setState(() => _isPlaying = false);
  }

  Future<void> _rateCurrent(int score, List<Flashcard> cards) async {
    final card = cards[_index];
    final localStorage = ref.read(localStorageServiceProvider);
    await localStorage.saveReviewLog(
      ReviewLog(
        id: const Uuid().v4(),
        cardId: card.id,
        setId: widget.setId,
        rating: 0,
        state: 0,
        reviewedAt: DateTime.now().toUtc(),
        reviewType: 'speaking',
        speakingScore: score,
      ),
    );
    ref.invalidate(allReviewLogsProvider);
    setState(() {
      _scoresByCardId[card.id] = score;
      _lastAutoScore = score;
      _recognizedText = '';
    });
    if (_index >= cards.length - 1) return;
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final studySet = ref
        .watch(studySetsProvider)
        .where((s) => s.id == widget.setId)
        .firstOrNull;

    if (studySet == null || studySet.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.speakingPractice)),
        body: Center(child: Text(l10n.noCardsAvailable)),
      );
    }

    final cards = studySet.cards;
    final done = _scoresByCardId.length == cards.length;

    if (done) {
      final values = _scoresByCardId.values.toList();
      final avg = values.isEmpty
          ? 0.0
          : values.reduce((a, b) => a + b) / values.length;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.speakingPractice)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.record_voice_over_rounded,
                  size: 54,
                  color: AppTheme.green,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.speakingComplete,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.averageScore(double.parse(avg.toStringAsFixed(1))),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.done),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final current = cards[_index.clamp(0, cards.length - 1)];
    final hasExample = _hasCustomExample(current);
    final sentence = _buildSentence(current);
    final hasSentence = sentence.isNotEmpty;
    final isAutoGenerated = _isAutoGeneratedExample(current);
    if (_lastAutoPlayedCardId != current.id) {
      _lastAutoPlayedCardId = current.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _playSequence(current);
        }
      });
    }

    final progress = (_scoresByCardId.length) / cards.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_index + 1} / ${cards.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    current.term,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (hasSentence) ...[
                    Text(
                      l10n.exampleLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!hasExample && isAutoGenerated) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.autoGeneratedLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.72),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      sentence,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ] else
                    Text(
                      l10n.noExampleSentence,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.72),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _speak(current.term, userInitiated: true),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: Text(l10n.speakWord),
                ),
                OutlinedButton.icon(
                  onPressed: hasSentence
                      ? () => _speak(
                            sentence,
                            userInitiated: true,
                          )
                      : null,
                  icon: const Icon(Icons.record_voice_over_rounded),
                  label: Text(l10n.speakSentence),
                ),
                OutlinedButton.icon(
                  onPressed: () => _playSequence(current),
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(l10n.replaySequence),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.rateSpeaking,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isListening
                        ? () => _finishAutoScore(current, cards)
                        : () => _startAutoScore(current, cards),
                    icon: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    ),
                    label: Text(
                      _isListening ? l10n.stopListening : l10n.autoScore,
                    ),
                  ),
                ),
              ],
            ),
            if (_lastAutoScore != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.useScore(_lastAutoScore!),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (_recognizedText.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l10n.recognizedSpeech(_recognizedText),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

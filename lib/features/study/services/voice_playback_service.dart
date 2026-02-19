import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:recall_app/services/ai_tts_service.dart';

/// Manages TTS playback for conversation practice and SRS review.
/// Extracts voice selection and speech logic from screen widgets.
class VoicePlaybackService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeechBusy = false;
  DateTime? _lastSpeechAt;
  List<Map<String, String>>? _ttsVoices;
  String? _aiLikeVoiceName;
  String? _aiLikeVoiceLocale;
  bool _isDisposed = false;

  // Multi-lingual TTS state
  Set<String>? _supportedLanguages;
  List<Map<String, String>>? _availableVoices;
  String? _activeLanguage;
  String? _activeVoiceKey;
  bool _isSpeaking = false;
  DateTime? _lastSpeakRequestedAt;

  /// Track which card was last spoken (for SRS review dedup).
  String lastSpokenCardId = '';

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
  }

  Future<void> dispose() async {
    _isDisposed = true;
    _isSpeaking = false;
    await _tts.stop();
    await AiTtsService.stop();
  }

  // ---------------------------------------------------------------------------
  // Static utilities (usable without an instance, e.g. for STT locale picking)
  // ---------------------------------------------------------------------------

  /// Detect language from text using CJK regex heuristics.
  static String pickLanguage(String text) {
    final hasJapaneseKana = RegExp(r'[\u3040-\u30FF]').hasMatch(text);
    if (hasJapaneseKana) return 'ja-JP';
    final hasChinese = RegExp(r'[\u3400-\u9FFF]').hasMatch(text);
    return hasChinese ? 'zh-TW' : 'en-US';
  }

  /// Normalize locale code: underscore→dash, lowercase.
  static String normalizeLocaleCode(String code) {
    return code.replaceAll('_', '-').toLowerCase();
  }

  // ---------------------------------------------------------------------------
  // Multi-lingual TTS (extracted from srs_review_screen / speaking_practice)
  // ---------------------------------------------------------------------------

  /// Speak text with automatic CJK language detection and best-voice selection.
  /// [userInitiated] skips the 120ms debounce.
  Future<void> speakMultiLingual(String text,
      {bool userInitiated = false}) async {
    if (_isDisposed) return;
    if (!_isInitialized) {
      await _initMultiLingual();
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
      final resolved = await _resolveLanguage(pickLanguage(value));
      if (resolved != null && resolved != _activeLanguage) {
        try {
          await _tts.setLanguage(resolved);
          _activeLanguage = resolved;
        } catch (_) {}
      }
      if (defaultTargetPlatform != TargetPlatform.iOS) {
        final voice = await _resolveVoice(pickLanguage(value));
        if (voice != null) {
          final voiceKey = '${voice['name']}|${voice['locale']}';
          if (voiceKey != _activeVoiceKey) {
            try {
              await _tts.setVoice({
                'name': voice['name'] ?? '',
                'locale': voice['locale'] ?? '',
              });
              _activeVoiceKey = voiceKey;
            } catch (_) {}
          }
        }
      }
      _isSpeaking = true;
      await _tts.speak(value);
    } catch (_) {
    } finally {
      _isSpeaking = false;
    }
  }

  /// Speak a card's term and track [lastSpokenCardId] for dedup.
  Future<void> speakCardTerm(String cardId, String term) async {
    lastSpokenCardId = cardId;
    await speakMultiLingual(term);
  }

  Future<void> _initMultiLingual() async {
    if (_isInitialized) return;
    _isInitialized = true;
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
    } catch (_) {}
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
            normalized.add({
              'name': name,
              'locale': locale,
              'quality':
                  voice['quality']?.toString().trim().toLowerCase() ?? '',
              'identifier':
                  voice['identifier']?.toString().trim().toLowerCase() ?? '',
            });
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

  int _voiceNaturalnessScore(Map<String, String> voice, String preferred) {
    final name = (voice['name'] ?? '').toLowerCase();
    final quality = (voice['quality'] ?? '').toLowerCase();
    final identifier = (voice['identifier'] ?? '').toLowerCase();
    var score = 0;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      if (quality.contains('premium') || quality.contains('enhanced')) {
        score += 40;
      }
      if (quality == '2' || quality == '300') score += 24;
      if (name.contains('compact') || identifier.contains('compact')) {
        score -= 24;
      }
    }

    if (name.contains('novelty') ||
        name.contains('zarvox') ||
        name.contains('boing') ||
        name.contains('bubbles') ||
        name.contains('bad news')) {
      score -= 20;
    }

    if (preferred.startsWith('en')) {
      if (name.contains('samantha') || name.contains('alex')) score += 8;
    }

    return score;
  }

  Map<String, String>? _pickBestVoiceForLocale(
    List<Map<String, String>> voices,
    String preferred,
    String localePrefix,
  ) {
    final matches = voices.where((voice) {
      final locale = normalizeLocaleCode(voice['locale'] ?? '');
      return locale == localePrefix || locale.startsWith('$localePrefix-');
    }).toList();
    if (matches.isEmpty) return null;
    matches.sort(
      (a, b) => _voiceNaturalnessScore(b, preferred)
          .compareTo(_voiceNaturalnessScore(a, preferred)),
    );
    return matches.first;
  }

  Future<String?> _resolveLanguage(String preferred) async {
    final available = await _loadSupportedLanguages();
    if (available.isEmpty) return null;
    final lowerMap = <String, String>{
      for (final lang in available) normalizeLocaleCode(lang): lang,
    };
    final normalizedPreferred = normalizeLocaleCode(preferred);
    final candidates = preferred.startsWith('zh')
        ? <String>[preferred, 'zh-TW', 'zh-CN', 'zh']
        : preferred.startsWith('ja')
            ? <String>[preferred, 'ja-JP', 'ja']
            : <String>[preferred, 'en-US', 'en-GB', 'en'];
    for (final candidate in candidates) {
      final normalizedCandidate = normalizeLocaleCode(candidate);
      final exact = lowerMap[normalizedCandidate];
      if (exact != null) return exact;
      final prefix = '$normalizedCandidate-';
      for (final entry in lowerMap.entries) {
        if (entry.key == normalizedCandidate ||
            entry.key.startsWith(prefix)) {
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
      final best = _pickBestVoiceForLocale(voices, preferred, candidate);
      if (best != null) return best;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Existing conversation-practice API (unchanged)
  // ---------------------------------------------------------------------------

  Future<void> _loadTtsVoices() async {
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
      if (!locale.startsWith('en')) continue;
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
    try {
      await _tts.setLanguage('en-US');
    } catch (_) {}
  }

  /// Speak text using local TTS, optionally preferring an AI-like voice.
  Future<bool> speakLocal(String text, {bool preferAiLikeVoice = false}) async {
    final value = text.trim();
    if (value.isEmpty) return false;
    try {
      await init();
      if (preferAiLikeVoice) {
        await _setAiLikeVoiceIfAvailable().timeout(
          const Duration(milliseconds: 800),
          onTimeout: () async => await _setDefaultVoice(),
        );
      } else {
        await _setDefaultVoice();
      }
      await AiTtsService.stop();
      await _tts.stop();
      await _tts.speak(value);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Play AI message with remote TTS cache fallback to local TTS.
  /// Returns true if playback started.
  Future<bool> playAiMessage(
    String text, {
    required String firstAiQuestionText,
    required bool isReplay,
    required bool allowRemoteGenerateForFirstLine,
    required bool useLocalCoachOnly,
    required String apiKey,
    void Function(VoiceState state, String diagnostic)? onStateChanged,
  }) async {
    final value = text.trim();
    if (value.isEmpty) return false;
    return _speakWithLock(() async {
      onStateChanged?.call(VoiceState.preparing, 'Preparing');
      final isFirstLine =
          firstAiQuestionText.isNotEmpty && value == firstAiQuestionText;

      if (isFirstLine) {
        final playedFromCache = await AiTtsService.speakCached(text: value);
        if (playedFromCache) {
          onStateChanged?.call(VoiceState.completed, 'AI cache hit');
          return;
        }
        if (allowRemoteGenerateForFirstLine && !useLocalCoachOnly) {
          if (apiKey.isNotEmpty) {
            final prepared = await AiTtsService.prepareFirstLineAudio(
              apiKey: apiKey,
              text: value,
            ).timeout(
              const Duration(milliseconds: 1800),
              onTimeout: () => false,
            );
            if (prepared) {
              final playedPrepared =
                  await AiTtsService.speakCached(text: value);
              if (playedPrepared) {
                onStateChanged?.call(
                    VoiceState.completed, 'AI fetched + played');
                return;
              }
            }
          }
        }
        final ttsOk = await speakLocal(value, preferAiLikeVoice: true);
        onStateChanged?.call(
          ttsOk ? VoiceState.completed : VoiceState.error,
          ttsOk
              ? (isReplay ? 'Replay fallback TTS' : 'Fallback TTS')
              : 'Fallback TTS failed',
        );
        return;
      }
      final ttsOk = await speakLocal(value);
      onStateChanged?.call(
        ttsOk ? VoiceState.completed : VoiceState.error,
        ttsOk ? 'Local TTS' : 'Local TTS failed',
      );
    });
  }

  Future<bool> _speakWithLock(Future<void> Function() task) async {
    if (_isDisposed) return false;
    final now = DateTime.now();
    final last = _lastSpeechAt;
    if (last != null && now.difference(last).inMilliseconds < 250) {
      return false;
    }
    if (_isSpeechBusy) return false;
    _isSpeechBusy = true;
    _lastSpeechAt = now;
    try {
      await task()
          .timeout(const Duration(seconds: 6), onTimeout: () async {});
      return true;
    } finally {
      _isSpeechBusy = false;
    }
  }
}

enum VoiceState { idle, preparing, playing, completed, error }

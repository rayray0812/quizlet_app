import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class _CloudTtsVoice {
  final String languageCode;
  final String name;

  const _CloudTtsVoice({required this.languageCode, required this.name});
}

/// Supported TTS engine backends.
enum TtsBackend { cloudTts, geminiTts }

class AiTtsService {
  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxCacheEntries = 5;
  static final RegExp _hanChars = RegExp(r'[\u4e00-\u9fff]');
  static final RegExp _kanaChars = RegExp(r'[\u3040-\u30ff]');
  static final RegExp _markdownBold = RegExp(r'\*\*(.+?)\*\*');
  static final RegExp _markdownItalic = RegExp(r'\*(.+?)\*');
  static final RegExp _markdownStars = RegExp(r'\*+');

  static final AudioPlayer _player = AudioPlayer(playerId: 'ai-first-line');
  static String _lastError = '';
  static TtsBackend _backend = TtsBackend.cloudTts;
  static final Map<String, Uint8List> _audioBytesCacheByText =
      <String, Uint8List>{};
  static final List<String> _cacheInsertionOrder = <String>[];
  static File? _lastTempFile;

  /// Set which TTS backend to use. Clears cache on change.
  static void setBackend(TtsBackend backend) {
    if (backend != _backend) {
      _backend = backend;
      clearCache();
    }
  }

  static TtsBackend get backend => _backend;

  static Future<bool> speakFirstLine({
    required String apiKey,
    required String text,
  }) async {
    final value = text.trim();
    if (apiKey.isEmpty || value.isEmpty) return false;

    final key = _clipKey(value);
    if (await speakCached(text: key)) return true;
    final prepared = await prepareFirstLineAudio(apiKey: apiKey, text: key);
    if (!prepared) return false;
    return speakCached(text: key);
  }

  static Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  static Future<void> dispose() async {
    try {
      await _player.stop();
    } catch (_) {}
    _audioBytesCacheByText.clear();
    _cacheInsertionOrder.clear();
    await _cleanupLastTempFile();
  }

  static void clearCache() {
    _audioBytesCacheByText.clear();
    _cacheInsertionOrder.clear();
  }

  static Future<bool> prepareFirstLineAudio({
    required String apiKey,
    required String text,
  }) async {
    final value = text.trim();
    if (apiKey.isEmpty || value.isEmpty) return false;
    final key = _clipKey(value);
    if (_audioBytesCacheByText.containsKey(key)) return true;

    try {
      final bytes = await _requestAudioBytes(apiKey: apiKey, text: key);
      if (bytes.isEmpty) return false;
      _putCache(key, bytes);
      _lastError = '';
      return true;
    } catch (e) {
      _lastError = 'error=$e';
      if (kDebugMode) {
        debugPrint('[AI_TTS] $_lastError');
      }
      return false;
    }
  }

  static Future<bool> speakCached({required String text}) async {
    final value = text.trim();
    if (value.isEmpty) return false;
    final key = _clipKey(value);
    final bytes = _audioBytesCacheByText[key];
    if (bytes == null || bytes.isEmpty) return false;
    try {
      await _cleanupLastTempFile();
      final ext = _backend == TtsBackend.geminiTts ? 'wav' : 'mp3';
      final cachedFile = await _writeTempAudio(bytes, ext);
      _lastTempFile = cachedFile;
      await _player.stop();
      return await _playFileAndConfirmStarted(cachedFile);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AI_TTS] speakCached failed: $e');
      }
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static String _clipKey(String text) {
    return text.length > 220 ? text.substring(0, 220) : text;
  }

  static void _putCache(String key, Uint8List bytes) {
    while (_cacheInsertionOrder.length >= _maxCacheEntries) {
      final oldest = _cacheInsertionOrder.removeAt(0);
      _audioBytesCacheByText.remove(oldest);
    }
    _audioBytesCacheByText[key] = bytes;
    _cacheInsertionOrder.add(key);
  }

  static Future<void> _cleanupLastTempFile() async {
    final file = _lastTempFile;
    _lastTempFile = null;
    if (file == null) return;
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AI_TTS] cleanup temp file failed: $e');
      }
    }
  }

  static Future<bool> _playFileAndConfirmStarted(File file) async {
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(1.0);
    final completer = Completer<bool>();
    late final StreamSubscription<PlayerState> sub;
    sub = _player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing || state == PlayerState.completed) {
        if (!completer.isCompleted) completer.complete(true);
      }
    });
    try {
      await _player.play(DeviceFileSource(file.path));
      final ok = await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
      if (!ok) {
        await _player.stop();
      }
      return ok;
    } finally {
      await sub.cancel();
    }
  }

  static Future<Uint8List> _requestAudioBytes({
    required String apiKey,
    required String text,
  }) async {
    if (_backend == TtsBackend.geminiTts) {
      return _requestGeminiTts(apiKey: apiKey, text: text);
    }
    return _requestCloudTts(apiKey: apiKey, text: text);
  }

  // ---------------------------------------------------------------------------
  // Cloud TTS (Google Cloud Text-to-Speech API)
  // ---------------------------------------------------------------------------

  static Future<Uint8List> _requestCloudTts({
    required String apiKey,
    required String text,
  }) async {
    final voices = _cloudVoiceCandidatesForText(text);
    Object? lastVoiceError;
    for (final voice in voices) {
      try {
        return await _requestCloudTtsWithVoice(
          apiKey: apiKey,
          text: text,
          voice: voice,
        );
      } catch (e) {
        lastVoiceError = e;
        if (kDebugMode) {
          debugPrint('[AI_TTS] cloud voice=${voice.name} failed: $e');
        }
        if (_isRateLimitError(e)) break;
      }
    }
    throw Exception('Cloud TTS all voices failed: $lastVoiceError');
  }

  static Future<Uint8List> _requestCloudTtsWithVoice({
    required String apiKey,
    required String text,
    required _CloudTtsVoice voice,
  }) async {
    final uri = Uri.parse(
      'https://texttospeech.googleapis.com/v1/text:synthesize',
    );
    final payload = <String, dynamic>{
      'input': <String, String>{'text': _stripMarkdown(text)},
      'voice': <String, String>{
        'languageCode': voice.languageCode,
        'name': voice.name,
      },
      'audioConfig': <String, dynamic>{
        'audioEncoding': 'MP3',
        'sampleRateHertz': 24000,
      },
    };
    final response = await http
        .post(
          uri,
          headers: <String, String>{
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: jsonEncode(payload),
        )
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = response.body.length > 240
          ? response.body.substring(0, 240)
          : response.body;
      throw Exception('status=${response.statusCode} body=$body');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final audioContent = decoded['audioContent'];
    if (audioContent is! String || audioContent.isEmpty) {
      throw Exception('missing audioContent in response');
    }
    return base64Decode(audioContent);
  }

  static List<_CloudTtsVoice> _cloudVoiceCandidatesForText(String text) {
    final lang = _detectLanguage(text);
    if (lang == 'zh') {
      return const <_CloudTtsVoice>[
        _CloudTtsVoice(languageCode: 'cmn-TW', name: 'cmn-TW-Wavenet-A'),
        _CloudTtsVoice(languageCode: 'cmn-TW', name: 'cmn-TW-Wavenet-B'),
        _CloudTtsVoice(languageCode: 'cmn-TW', name: 'cmn-TW-Wavenet-C'),
      ];
    }
    if (lang == 'ja') {
      return const <_CloudTtsVoice>[
        _CloudTtsVoice(languageCode: 'ja-JP', name: 'ja-JP-Neural2-B'),
        _CloudTtsVoice(languageCode: 'ja-JP', name: 'ja-JP-Neural2-C'),
        _CloudTtsVoice(languageCode: 'ja-JP', name: 'ja-JP-Neural2-D'),
      ];
    }
    return const <_CloudTtsVoice>[
      _CloudTtsVoice(languageCode: 'en-US', name: 'en-US-Journey-O'),
      _CloudTtsVoice(languageCode: 'en-US', name: 'en-US-Journey-D'),
      _CloudTtsVoice(languageCode: 'en-US', name: 'en-US-Journey-F'),
    ];
  }

  // ---------------------------------------------------------------------------
  // Gemini TTS (Generative Language API)
  // ---------------------------------------------------------------------------

  static Future<Uint8List> _requestGeminiTts({
    required String apiKey,
    required String text,
  }) async {
    final voices = _geminiVoiceCandidatesForText(text);
    Object? lastVoiceError;
    for (final voiceName in voices) {
      try {
        return await _requestGeminiTtsWithVoice(
          apiKey: apiKey,
          text: text,
          voiceName: voiceName,
        );
      } catch (e) {
        lastVoiceError = e;
        if (kDebugMode) {
          debugPrint('[AI_TTS] gemini voice=$voiceName failed: $e');
        }
        if (_isRateLimitError(e)) break;
      }
    }
    throw Exception('Gemini TTS all voices failed: $lastVoiceError');
  }

  static Future<Uint8List> _requestGeminiTtsWithVoice({
    required String apiKey,
    required String text,
    required String voiceName,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent',
    );
    final payload = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'parts': <Map<String, String>>[
            <String, String>{'text': _stripMarkdown(text)},
          ],
        },
      ],
      'generationConfig': <String, dynamic>{
        'responseModalities': <String>['AUDIO'],
        'speechConfig': <String, dynamic>{
          'voiceConfig': <String, dynamic>{
            'prebuiltVoiceConfig': <String, String>{'voiceName': voiceName},
          },
        },
      },
    };
    final response = await http
        .post(
          uri,
          headers: <String, String>{
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: jsonEncode(payload),
        )
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = response.body.length > 240
          ? response.body.substring(0, 240)
          : response.body;
      throw Exception('status=${response.statusCode} body=$body');
    }

    final decoded = jsonDecode(response.body);
    final audio = _extractGeminiAudioPayload(decoded);
    if (audio == null || audio.isEmpty) {
      throw Exception('missing audio payload');
    }
    final bytes = base64Decode(audio);
    // Gemini returns raw PCM, wrap in WAV header
    return _pcm16Mono24kToWav(bytes);
  }

  static List<String> _geminiVoiceCandidatesForText(String text) {
    final lang = _detectLanguage(text);
    if (lang == 'zh') {
      return const <String>['Leda', 'Aoede', 'Kore'];
    }
    if (lang == 'ja') {
      return const <String>['Aoede', 'Leda', 'Kore'];
    }
    return const <String>['Kore', 'Aoede', 'Leda'];
  }

  static String? _extractGeminiAudioPayload(dynamic decoded) {
    if (decoded is! Map) return null;
    final candidates = decoded['candidates'];
    if (candidates is! List) return null;
    for (final candidate in candidates) {
      if (candidate is! Map) continue;
      final content = candidate['content'];
      if (content is! Map) continue;
      final parts = content['parts'];
      if (parts is! List) continue;
      for (final part in parts) {
        if (part is! Map) continue;
        final inlineData = part['inlineData'] ?? part['inline_data'];
        if (inlineData is! Map) continue;
        final data = inlineData['data'];
        if (data is String && data.isNotEmpty) return data;
      }
    }
    return null;
  }

  static Uint8List _pcm16Mono24kToWav(Uint8List pcmBytes) {
    const int sampleRate = 24000;
    const int channels = 1;
    const int bitsPerSample = 16;
    final int byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final int blockAlign = channels * (bitsPerSample ~/ 8);
    final int dataLength = pcmBytes.length;
    final int chunkSize = 36 + dataLength;
    final builder = BytesBuilder(copy: false);

    void writeString(String v) {
      builder.add(ascii.encode(v));
    }

    void writeUint32LE(int v) {
      builder.add(<int>[
        v & 0xFF,
        (v >> 8) & 0xFF,
        (v >> 16) & 0xFF,
        (v >> 24) & 0xFF,
      ]);
    }

    void writeUint16LE(int v) {
      builder.add(<int>[
        v & 0xFF,
        (v >> 8) & 0xFF,
      ]);
    }

    writeString('RIFF');
    writeUint32LE(max(0, chunkSize));
    writeString('WAVE');
    writeString('fmt ');
    writeUint32LE(16);
    writeUint16LE(1);
    writeUint16LE(channels);
    writeUint32LE(sampleRate);
    writeUint32LE(byteRate);
    writeUint16LE(blockAlign);
    writeUint16LE(bitsPerSample);
    writeString('data');
    writeUint32LE(dataLength);
    builder.add(pcmBytes);

    return builder.toBytes();
  }

  // ---------------------------------------------------------------------------
  // Shared utilities
  // ---------------------------------------------------------------------------

  static bool _isRateLimitError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('429') ||
        msg.contains('rate limit') ||
        msg.contains('rate_limit') ||
        msg.contains('too many requests');
  }

  static String _stripMarkdown(String text) {
    return text
        .replaceAll(_markdownBold, r'$1')
        .replaceAll(_markdownItalic, r'$1')
        .replaceAll(_markdownStars, '');
  }

  static String _detectLanguage(String text) {
    if (_hanChars.hasMatch(text)) return 'zh';
    if (_kanaChars.hasMatch(text)) return 'ja';
    return 'en';
  }

  static Future<File> _writeTempAudio(Uint8List bytes, String ext) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}${Platform.pathSeparator}ai_first_line_${DateTime.now().microsecondsSinceEpoch}.$ext',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}

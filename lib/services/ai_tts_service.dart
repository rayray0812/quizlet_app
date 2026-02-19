import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AiTtsService {
  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxCacheEntries = 5;
  static final RegExp _hanChars = RegExp(r'[\u4e00-\u9fff]');
  static final RegExp _kanaChars = RegExp(r'[\u3040-\u30ff]');
  static const List<String> _ttsModels = <String>[
    'gemini-2.5-flash-preview-tts',
    'gemini-2.5-pro-preview-tts',
  ];

  static final AudioPlayer _player = AudioPlayer(playerId: 'ai-first-line');
  static String _lastError = '';
  static final Map<String, Uint8List> _audioBytesCacheByText =
      <String, Uint8List>{};
  static final List<String> _cacheInsertionOrder = <String>[];
  static File? _lastTempFile;

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

  static Future<void> stop() => _player.stop();

  /// Release static resources. Call from app lifecycle dispose.
  static Future<void> dispose() async {
    await _player.stop();
    await _player.dispose();
    _audioBytesCacheByText.clear();
    _cacheInsertionOrder.clear();
    await _cleanupLastTempFile();
  }

  /// Clear audio cache (call on session end to free memory).
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

    for (final model in _ttsModels) {
      try {
        final bytes = await _requestAudioBytes(
          apiKey: apiKey,
          model: model,
          text: key,
        );
        if (bytes.isEmpty) continue;
        _putCache(key, bytes);
        _lastError = '';
        return true;
      } catch (e) {
        _lastError = 'model=$model error=$e';
        if (kDebugMode) {
          debugPrint('[AI_TTS] $_lastError');
        }
        continue;
      }
    }
    if (kDebugMode) {
      debugPrint('[AI_TTS] all models failed: $_lastError');
    }
    return false;
  }

  static Future<bool> speakCached({required String text}) async {
    final value = text.trim();
    if (value.isEmpty) return false;
    final key = _clipKey(value);
    final bytes = _audioBytesCacheByText[key];
    if (bytes == null || bytes.isEmpty) return false;
    try {
      await _cleanupLastTempFile();
      final cachedFile = await _writeTempWav(bytes);
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

  static String _clipKey(String text) {
    return text.length > 220 ? text.substring(0, 220) : text;
  }

  static void _putCache(String key, Uint8List bytes) {
    // Evict oldest entries when cache exceeds limit
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
    required String model,
    required String text,
  }) async {
    final voices = _voiceCandidatesForText(text);
    Object? lastVoiceError;
    for (final voiceName in voices) {
      try {
        return await _requestAudioBytesWithVoice(
          apiKey: apiKey,
          model: model,
          text: text,
          voiceName: voiceName,
        );
      } catch (e) {
        lastVoiceError = e;
        if (kDebugMode) {
          debugPrint('[AI_TTS] voice=$voiceName failed: $e');
        }
      }
    }
    throw Exception('all voice candidates failed: $lastVoiceError');
  }

  static Future<Uint8List> _requestAudioBytesWithVoice({
    required String apiKey,
    required String model,
    required String text,
    required String voiceName,
  }) async {
    // Use path-only URL; pass API key via header to avoid logging exposure
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
    );
    final payload = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'parts': <Map<String, String>>[
            <String, String>{'text': text},
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
    final audio = _extractAudioPayload(decoded);
    if (audio == null || audio.base64Data.isEmpty) {
      throw Exception('missing audio payload');
    }
    final bytes = base64Decode(audio.base64Data);
    final mime = audio.mimeType.toLowerCase();
    if (mime.contains('wav') || mime.contains('wave')) {
      return bytes;
    }
    return _pcm16Mono24kToWav(bytes);
  }

  static List<String> _voiceCandidatesForText(String text) {
    final lang = _detectLanguage(text);
    if (lang == 'zh') {
      return const <String>['Leda', 'Aoede', 'Kore'];
    }
    if (lang == 'ja') {
      return const <String>['Aoede', 'Leda', 'Kore'];
    }
    return const <String>['Kore', 'Aoede', 'Leda'];
  }

  static String _detectLanguage(String text) {
    if (_hanChars.hasMatch(text)) return 'zh';
    if (_kanaChars.hasMatch(text)) return 'ja';
    return 'en';
  }

  static _AudioPayload? _extractAudioPayload(dynamic decoded) {
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
        if (data is String && data.isNotEmpty) {
          final mimeType = (inlineData['mimeType'] ?? inlineData['mime_type'] ?? '')
              .toString();
          return _AudioPayload(base64Data: data, mimeType: mimeType);
        }
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

  static Future<File> _writeTempWav(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}${Platform.pathSeparator}ai_first_line_${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}

class _AudioPayload {
  final String base64Data;
  final String mimeType;

  const _AudioPayload({required this.base64Data, required this.mimeType});
}

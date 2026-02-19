import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/features/study/services/voice_playback_service.dart';

void main() {
  group('VoicePlaybackService.pickLanguage', () {
    test('returns en-US for English text', () {
      expect(VoicePlaybackService.pickLanguage('hello world'), 'en-US');
    });

    test('returns en-US for mixed latin/numbers', () {
      expect(VoicePlaybackService.pickLanguage('Flutter 3.0'), 'en-US');
    });

    test('returns ja-JP for Japanese kana', () {
      expect(VoicePlaybackService.pickLanguage('\u3053\u3093\u306B\u3061\u306F'), 'ja-JP');
    });

    test('returns ja-JP for katakana', () {
      expect(VoicePlaybackService.pickLanguage('\u30D5\u30E9\u30C3\u30BF\u30FC'), 'ja-JP');
    });

    test('returns zh-TW for Chinese characters', () {
      expect(VoicePlaybackService.pickLanguage('\u4F60\u597D\u4E16\u754C'), 'zh-TW');
    });

    test('returns zh-TW for CJK unified ideographs', () {
      expect(VoicePlaybackService.pickLanguage('\u5B78\u7FD2'), 'zh-TW');
    });

    test('returns en-US for empty string', () {
      expect(VoicePlaybackService.pickLanguage(''), 'en-US');
    });

    test('prioritizes Japanese kana over Chinese characters', () {
      // Text with both Japanese kana and Chinese characters
      expect(
        VoicePlaybackService.pickLanguage('\u65E5\u672C\u8A9E\u306E\u52C9\u5F37'),
        'ja-JP',
      );
    });
  });

  group('VoicePlaybackService.normalizeLocaleCode', () {
    test('converts underscore to dash', () {
      expect(VoicePlaybackService.normalizeLocaleCode('en_US'), 'en-us');
    });

    test('lowercases the code', () {
      expect(VoicePlaybackService.normalizeLocaleCode('zh-TW'), 'zh-tw');
    });

    test('handles already normalized code', () {
      expect(VoicePlaybackService.normalizeLocaleCode('en-us'), 'en-us');
    });

    test('handles complex locale codes', () {
      expect(
        VoicePlaybackService.normalizeLocaleCode('zh_Hant_TW'),
        'zh-hant-tw',
      );
    });
  });
}

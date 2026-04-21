import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/features/study/utils/part_of_speech.dart';

void main() {
  test('extractPartOfSpeechTags keeps supported tags in order', () {
    expect(extractPartOfSpeechTags(['deck', 'n.', 'v.', 'topic']), [
      'n.',
      'v.',
    ]);
  });

  test('extractPartOfSpeechTags normalizes case and removes duplicates', () {
    expect(extractPartOfSpeechTags(['N.', 'adj.', 'adj.', 'ADV.']), [
      'n.',
      'adj.',
      'adv.',
    ]);
  });

  test('extractPartOfSpeechTags ignores non pos tags', () {
    expect(extractPartOfSpeechTags(['toeic', 'history', 'chapter-1']), isEmpty);
  });
}

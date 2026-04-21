const Set<String> kPartOfSpeechTags = {
  'n.',
  'v.',
  'adj.',
  'adv.',
  'prep.',
  'conj.',
  'phr.',
};

List<String> extractPartOfSpeechTags(List<String> tags) {
  final found = <String>[];
  final seen = <String>{};
  for (final tag in tags) {
    final normalized = tag.trim().toLowerCase();
    if (!kPartOfSpeechTags.contains(normalized)) continue;
    if (seen.add(normalized)) {
      found.add(normalized);
    }
  }
  return found;
}

/// Levenshtein-distance based fuzzy matching for quiz text input.
///
/// Returns `true` when [input] is close enough to [expected].
///
/// **English / Latin rules:**
/// - Strings of length <= 3 require an exact match (case-insensitive).
/// - Longer strings allow up to 20 % edit distance (minimum 1).
///
/// **CJK rules (Chinese / Japanese / Korean):**
/// - 2-character words allow 1 edit distance (e.g. one wrong character).
/// - 3+ character words allow ~33 % edit distance (minimum 1).
/// - Single characters require exact match.
bool isFuzzyMatch(String input, String expected) {
  final a = _normalizeForFuzzy(input);
  final b = _normalizeForFuzzy(expected);

  if (a == b) return true;
  if (a.isEmpty || b.isEmpty) return false;

  final cjk = _hasCjk(b);

  if (cjk) {
    // Single CJK character: exact match only
    if (b.length <= 1) return false;
    // 2-char CJK: allow 1 edit (e.g. 蘋果 → 苹果)
    // 3+ char CJK: allow ~33% edit distance (min 1)
    final maxDist = b.length <= 2 ? 1 : (b.length * 0.33).ceil().clamp(1, b.length);
    return _levenshtein(a, b) <= maxDist;
  }

  // Latin / short strings: exact match only
  if (b.length <= 3) return false;

  final maxDist = (b.length * 0.2).ceil().clamp(1, b.length);
  return _levenshtein(a, b) <= maxDist;
}

/// Returns true if the string contains any CJK Unified Ideographs,
/// Hiragana, or Katakana characters.
bool _hasCjk(String s) {
  return RegExp(r'[\u3040-\u30FF\u3400-\u9FFF\uF900-\uFAFF]').hasMatch(s);
}

String _normalizeForFuzzy(String value) {
  final normalized = _stripPartOfSpeechTags(value.trim().toLowerCase());
  // Common transliteration variant in English words (e.g. photo -> foto).
  // Only apply to non-CJK text to avoid mangling Chinese characters.
  if (!_hasCjk(normalized)) {
    return normalized.replaceAll('ph', 'f');
  }
  return normalized;
}

String _stripPartOfSpeechTags(String value) {
  if (value.isEmpty) return value;

  // Remove bracketed POS tags: "(n.)", "[adj]", "（動詞）"...
  final withoutBracketPos = value.replaceAll(
    RegExp(
      r'[\(\[（【]\s*(?:n|v|vt|vi|adj|adv|prep|pron|conj|int|num|art|aux|det|abbr|phr|pl|sing|past|pp|noun|verb|adjective|adverb|名詞|動詞|形容詞|副詞)\.?\s*[\)\]）】]',
      caseSensitive: false,
    ),
    ' ',
  );

  final pieces = withoutBracketPos
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .where((part) => !_isPosToken(part))
      .toList();

  return pieces.join(' ').trim();
}

bool _isPosToken(String token) {
  final normalized = token
      .toLowerCase()
      .replaceAll(RegExp(r'^[\.,;:!?/\\]+|[\.,;:!?/\\]+$'), '');
  if (normalized.isEmpty) return false;

  const pos = <String>{
    'n',
    'v',
    'vt',
    'vi',
    'adj',
    'adv',
    'prep',
    'pron',
    'conj',
    'int',
    'num',
    'art',
    'aux',
    'det',
    'abbr',
    'phr',
    'pl',
    'sing',
    'past',
    'pp',
    'noun',
    'verb',
    'adjective',
    'adverb',
    '名詞',
    '動詞',
    '形容詞',
    '副詞',
  };

  if (pos.contains(normalized)) return true;

  // Handle combined forms like "adj./adv." or "n/v".
  final slashParts = normalized.split('/');
  return slashParts.isNotEmpty && slashParts.every(pos.contains);
}

int _levenshtein(String s, String t) {
  final m = s.length;
  final n = t.length;

  // Single-row optimisation
  var prev = List<int>.generate(n + 1, (i) => i);
  var curr = List<int>.filled(n + 1, 0);

  for (var i = 1; i <= m; i++) {
    curr[0] = i;
    for (var j = 1; j <= n; j++) {
      final cost = s[i - 1] == t[j - 1] ? 0 : 1;
      curr[j] = [
        prev[j] + 1, // deletion
        curr[j - 1] + 1, // insertion
        prev[j - 1] + cost, // substitution
      ].reduce((a, b) => a < b ? a : b);
    }
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }
  return prev[n];
}

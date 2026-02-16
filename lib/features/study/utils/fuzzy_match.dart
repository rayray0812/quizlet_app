/// Levenshtein-distance based fuzzy matching for quiz text input.
///
/// Returns `true` when [input] is close enough to [expected].
/// - Strings of length <= 3 require an exact match (case-insensitive).
/// - Longer strings allow up to 20 % edit distance (minimum 1).
bool isFuzzyMatch(String input, String expected) {
  final a = _normalizeForFuzzy(input);
  final b = _normalizeForFuzzy(expected);

  if (a == b) return true;
  if (a.isEmpty || b.isEmpty) return false;

  // Short strings: exact match only
  if (b.length <= 3) return false;

  final maxDist = (b.length * 0.2).ceil().clamp(1, b.length);
  return _levenshtein(a, b) <= maxDist;
}

String _normalizeForFuzzy(String value) {
  final normalized = value.trim().toLowerCase();
  // Common transliteration variant in English words (e.g. photo -> foto).
  return normalized.replaceAll('ph', 'f');
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

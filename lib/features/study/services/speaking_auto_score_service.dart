import 'dart:math';

class SpeakingAutoScoreService {
  static String normalizeLocaleCode(String code) {
    return code.replaceAll('_', '-').toLowerCase();
  }

  static bool isCjkLanguage(String languageCode) {
    final normalized = normalizeLocaleCode(languageCode);
    return normalized.startsWith('zh') || normalized.startsWith('ja');
  }

  static int scoreFromSimilarity(double sim) {
    if (sim >= 0.92) return 5;
    if (sim >= 0.78) return 4;
    if (sim >= 0.62) return 3;
    if (sim >= 0.45) return 2;
    if (sim > 0) return 1;
    return 0;
  }

  static int computeScore({
    required String term,
    required String sentence,
    required String combinedTarget,
    required String spoken,
    required String languageCode,
    double? confidence,
  }) {
    final trimmed = spoken.trim();
    if (trimmed.isEmpty) return 0;
    final cjk = isCjkLanguage(languageCode);
    final normalizedSpoken = _normalizeForCompareByLanguage(trimmed, isCjk: cjk);
    final minLength = cjk ? 2 : 3;
    if (normalizedSpoken.length < minLength) return 0;
    final similarity = computeSimilarity(
      term: term,
      sentence: sentence,
      combinedTarget: combinedTarget,
      spoken: trimmed,
      languageCode: languageCode,
      confidence: confidence,
    );
    return scoreFromSimilarity(similarity);
  }

  static double computeSimilarity({
    required String term,
    required String sentence,
    required String combinedTarget,
    required String spoken,
    required String languageCode,
    double? confidence,
  }) {
    final cjk = isCjkLanguage(languageCode);
    final cleanTerm = term.trim();
    final cleanSentence = sentence.trim();
    final cleanCombined = combinedTarget.trim();
    final cleanSpoken = spoken.trim();

    final simTerm = _similarity(cleanTerm, cleanSpoken, isCjk: cjk);
    final simSentence = cleanSentence.isEmpty
        ? 0.0
        : _similarity(cleanSentence, cleanSpoken, isCjk: cjk);
    final simCombined = _similarity(cleanCombined, cleanSpoken, isCjk: cjk);
    var scoreSim = max(simTerm, max(simSentence, simCombined));

    final coverageTerm = _coverageRatio(cleanTerm, cleanSpoken, isCjk: cjk);
    final coverageSentence = cleanSentence.isEmpty
        ? 0.0
        : _coverageRatio(cleanSentence, cleanSpoken, isCjk: cjk);
    final coverageCombined = _coverageRatio(
      cleanCombined,
      cleanSpoken,
      isCjk: cjk,
    );
    final bestCoverage = max(coverageTerm, max(coverageSentence, coverageCombined));

    final lengthTerm = _lengthRatio(cleanTerm, cleanSpoken, isCjk: cjk);
    final lengthSentence = cleanSentence.isEmpty
        ? 0.0
        : _lengthRatio(cleanSentence, cleanSpoken, isCjk: cjk);
    final lengthCombined = _lengthRatio(cleanCombined, cleanSpoken, isCjk: cjk);
    final bestLength = max(lengthTerm, max(lengthSentence, lengthCombined));

    if (bestCoverage < 0.25 || bestLength < 0.2) {
      scoreSim = min(scoreSim, 0.44);
    } else if (bestCoverage < 0.4 || bestLength < 0.35) {
      scoreSim = min(scoreSim, 0.61);
    } else if (bestCoverage < 0.55 || bestLength < 0.5) {
      scoreSim = min(scoreSim, 0.77);
    }

    if (confidence != null && confidence >= 0) {
      if (confidence < 0.3) {
        scoreSim *= 0.72;
      } else if (confidence < 0.45) {
        scoreSim *= 0.85;
      }
    }

    return scoreSim.clamp(0.0, 1.0);
  }

  static String _normalizeForCompare(String input) {
    final lower = input.toLowerCase();
    final cleaned = lower.replaceAll(
      RegExp(r'[^a-z0-9\u3040-\u30FF\u3400-\u9FFF\s]'),
      ' ',
    );
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _normalizeForCompareByLanguage(
    String input, {
    required bool isCjk,
  }) {
    final normalized = _normalizeForCompare(input);
    if (!isCjk) return normalized;
    return normalized.replaceAll(' ', '');
  }

  static Set<String> _tokensForCoverage(String input, {required bool isCjk}) {
    final normalized = _normalizeForCompareByLanguage(input, isCjk: isCjk);
    if (normalized.isEmpty) return <String>{};
    if (!isCjk) {
      return normalized
          .split(' ')
          .where((token) => token.isNotEmpty)
          .toSet();
    }
    return normalized.runes.map((rune) => String.fromCharCode(rune)).toSet();
  }

  static int _levenshtein(String a, String b) {
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

  static double _similarity(String target, String spoken, {required bool isCjk}) {
    final t = _normalizeForCompareByLanguage(target, isCjk: isCjk);
    final s = _normalizeForCompareByLanguage(spoken, isCjk: isCjk);
    if (t.isEmpty || s.isEmpty) return 0;
    final dist = _levenshtein(t, s);
    final charSim = 1 - (dist / max(t.length, s.length));
    final targetWords = _tokensForCoverage(t, isCjk: isCjk);
    final spokenWords = _tokensForCoverage(s, isCjk: isCjk);
    final hasWordLevel = targetWords.isNotEmpty && spokenWords.isNotEmpty;
    if (!hasWordLevel) return charSim.clamp(0.0, 1.0);
    final overlap = targetWords.intersection(spokenWords).length;
    final wordSim = targetWords.isEmpty ? 0.0 : overlap / targetWords.length;
    final charWeight = isCjk ? 0.62 : 0.55;
    final tokenWeight = 1 - charWeight;
    return ((charSim * charWeight) + (wordSim * tokenWeight)).clamp(0.0, 1.0);
  }

  static double _coverageRatio(
    String target,
    String spoken, {
    required bool isCjk,
  }) {
    final targetTokens = _tokensForCoverage(target, isCjk: isCjk);
    final spokenTokens = _tokensForCoverage(spoken, isCjk: isCjk);
    if (targetTokens.isEmpty || spokenTokens.isEmpty) return 0.0;
    final overlap = targetTokens.intersection(spokenTokens).length;
    return (overlap / targetTokens.length).clamp(0.0, 1.0);
  }

  static double _lengthRatio(String target, String spoken, {required bool isCjk}) {
    final targetNorm = _normalizeForCompareByLanguage(target, isCjk: isCjk);
    final spokenNorm = _normalizeForCompareByLanguage(spoken, isCjk: isCjk);
    if (targetNorm.isEmpty || spokenNorm.isEmpty) return 0.0;
    final shorter = min(targetNorm.length, spokenNorm.length).toDouble();
    final longer = max(targetNorm.length, spokenNorm.length).toDouble();
    return (shorter / longer).clamp(0.0, 1.0);
  }
}

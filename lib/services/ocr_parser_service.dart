import 'package:flutter/foundation.dart';

import 'ocr_service.dart';

/// Extracts term-definition pairs from OCR results using layout heuristics.
class OcrParserService {
  static final List<RegExp> _separatorPatterns = <RegExp>[
    RegExp(r'\s{2,}'),
    RegExp(r'\t+'),
    RegExp(r'\s[-:=-]\s'),
    RegExp(r'\s->\s'),
    RegExp(r':\s+'), // colon-space: handles "term: definition" (no space before colon)
  ];

  static final RegExp _noisePattern = RegExp(
    r'^(unit|lesson|chapter|page|vocabulary|word\s*list|exercise|'
    r'name|class|date|score|total|answer|section|review|practice|test|quiz'
    r'|\(?\d+\)?[\.\)]?|[\d\s\.\-/:]+)$',
    caseSensitive: false,
  );

  /// Public validity check — same rule as the internal [_isValidTextCandidate].
  /// Used by other services to filter OCR noise before processing.
  static bool isValidVocabLine(String text) => _isValidTextCandidate(text);

  /// True when Latin characters outnumber CJK characters in [text].
  static bool isLatinDominated(String text) {
    final latin = RegExp(r'[A-Za-z]').allMatches(text).length;
    final cjk = RegExp(r'[\u4E00-\u9FFF\u3040-\u309F\u30A0-\u30FF]').allMatches(text).length;
    return latin >= cjk;
  }

  /// Detects and parses vocabulary lists where terms and definitions alternate
  /// on consecutive lines (e.g., English line → Chinese line → repeat).
  ///
  /// This is the most common format in Taiwan high-school vocabulary books.
  /// Because we pair lines by detected language, the result is deterministic
  /// and immune to the meaning-drift problem of small local models.
  ///
  /// Returns an empty list when the alternating pattern is not clearly present.
  static List<Map<String, String>> parseAlternatingLines(OcrResult ocrResult) {
    if (ocrResult.lines.isEmpty) return [];

    // Strip leading numbers/bullets and remove noise lines.
    final lines = ocrResult.lines
        .map((l) => _stripLeadingNumbering(l.text.trim()))
        .where(_isValidTextCandidate)
        .toList();

    if (lines.length < 4) return [];

    // Confirm alternating pattern: check first several pairs.
    final checkPairs = (lines.length / 2).floor().clamp(2, 10);
    var alternating = 0;
    for (var i = 0; i < checkPairs * 2 - 1; i += 2) {
      final aLatin = isLatinDominated(lines[i]);
      final bLatin = isLatinDominated(lines[i + 1]);
      if (aLatin != bLatin) alternating++;
    }

    // Need at least 60% of sampled pairs to alternate languages.
    if (alternating < (checkPairs * 0.6).ceil()) return [];

    // Pair the lines, using _normalizePair to orient term/definition correctly.
    final results = <Map<String, String>>[];
    for (var i = 0; i + 1 < lines.length; i += 2) {
      final pair = _normalizePair(lines[i], lines[i + 1]);
      if (pair != null) results.add(pair);
    }

    if (kDebugMode) {
      debugPrint('OCR Parser: alternating-lang -> ${results.length} pairs');
    }
    return _dedupe(results);
  }

  /// Returns the spatial row groupings and estimated column divider X position.
  ///
  /// Used by [OnDeviceAiService] to pre-structure prompts so the local model
  /// never has to reason about spatial layout itself.
  static ({List<List<OcrTextLine>> rows, double? dividerX}) analyzeLayout(
    OcrResult ocrResult,
  ) {
    final lines = List<OcrTextLine>.from(ocrResult.lines)
      ..sort((a, b) => a.centerY.compareTo(b.centerY));
    final rows = _clusterIntoRows(lines);
    final dividerX = _findColumnDivider(rows, ocrResult.imageSize.width);
    return (rows: rows, dividerX: dividerX);
  }

  static List<Map<String, String>> parseVocabularyTable(OcrResult ocrResult) {
    if (ocrResult.lines.isEmpty) return <Map<String, String>>[];

    final twoColumn = _parseTwoColumnLayout(ocrResult);
    if (twoColumn.length >= 2) {
      if (kDebugMode) {
        debugPrint('OCR Parser: two-column -> ${twoColumn.length} pairs');
      }
      return twoColumn;
    }

    final separatorPairs = _parseSeparatorLines(ocrResult);
    if (separatorPairs.length >= 2) {
      if (kDebugMode) {
        debugPrint('OCR Parser: separator -> ${separatorPairs.length} pairs');
      }
      return separatorPairs;
    }

    final consecutivePairs = _parseConsecutiveLinePairs(ocrResult);
    if (kDebugMode) {
      debugPrint('OCR Parser: consecutive -> ${consecutivePairs.length} pairs');
    }

    if (twoColumn.isNotEmpty) return twoColumn;
    if (separatorPairs.isNotEmpty) return separatorPairs;
    return consecutivePairs;
  }

  static List<Map<String, String>> _parseTwoColumnLayout(OcrResult ocrResult) {
    final lines = List<OcrTextLine>.from(ocrResult.lines)
      ..sort((a, b) => a.centerY.compareTo(b.centerY));
    if (lines.length < 2) return <Map<String, String>>[];

    final rows = _clusterIntoRows(lines);
    final dividerX = _findColumnDivider(rows, ocrResult.imageSize.width);
    if (dividerX == null) return <Map<String, String>>[];

    final rawPairs = <_Pair>[];
    for (final row in rows) {
      final leftParts = <OcrTextLine>[];
      final rightParts = <OcrTextLine>[];

      for (final line in row) {
        if (line.centerX < dividerX) {
          leftParts.add(line);
        } else {
          rightParts.add(line);
        }
      }

      if (leftParts.isEmpty || rightParts.isEmpty) continue;

      leftParts.sort((a, b) => a.left.compareTo(b.left));
      rightParts.sort((a, b) => a.left.compareTo(b.left));

      final leftText = leftParts.map((line) => line.text.trim()).join(' ').trim();
      final rightText =
          rightParts.map((line) => line.text.trim()).join(' ').trim();
      if (!_isValidTextCandidate(leftText) || !_isValidTextCandidate(rightText)) {
        continue;
      }

      rawPairs.add(_Pair(left: _cleanText(leftText), right: _cleanText(rightText)));
    }

    if (rawPairs.length < 2) return _pairMapsFromRaw(rawPairs);

    final leftScore =
        rawPairs.fold<double>(0, (sum, pair) => sum + _termLikelihood(pair.left));
    final rightScore =
        rawPairs.fold<double>(0, (sum, pair) => sum + _termLikelihood(pair.right));
    final leftIsTerm = leftScore >= rightScore;

    final normalized = <Map<String, String>>[];
    for (final pair in rawPairs) {
      final first = leftIsTerm ? pair.left : pair.right;
      final second = leftIsTerm ? pair.right : pair.left;
      final oriented = _normalizePair(first, second);
      if (oriented != null) normalized.add(oriented);
    }

    return _dedupe(normalized);
  }

  static List<List<OcrTextLine>> _clusterIntoRows(List<OcrTextLine> sortedLines) {
    if (sortedLines.isEmpty) return <List<OcrTextLine>>[];

    final rows = <List<OcrTextLine>>[];
    var currentRow = <OcrTextLine>[sortedLines.first];

    for (var i = 1; i < sortedLines.length; i++) {
      final line = sortedLines[i];
      final reference = currentRow.last;
      final threshold = (reference.height > 0 ? reference.height : 24) * 0.75;

      if ((line.centerY - reference.centerY).abs() <= threshold) {
        currentRow.add(line);
      } else {
        rows.add(currentRow);
        currentRow = <OcrTextLine>[line];
      }
    }

    rows.add(currentRow);
    return rows;
  }

  static double? _findColumnDivider(
    List<List<OcrTextLine>> rows,
    double imageWidth,
  ) {
    final gaps = <double>[];

    for (final row in rows) {
      if (row.length < 2) continue;
      final sorted = List<OcrTextLine>.from(row)
        ..sort((a, b) => a.left.compareTo(b.left));

      var bestGap = 0.0;
      var bestMid = 0.0;
      for (var i = 0; i < sorted.length - 1; i++) {
        final gap = sorted[i + 1].left - sorted[i].right;
        if (gap > bestGap) {
          bestGap = gap;
          bestMid = (sorted[i].right + sorted[i + 1].left) / 2;
        }
      }

      if (bestGap >= imageWidth * 0.06 || bestGap >= 24) {
        gaps.add(bestMid);
      }
    }

    if (gaps.length < 2) return null;
    gaps.sort();
    return gaps[gaps.length ~/ 2];
  }

  static List<Map<String, String>> _parseSeparatorLines(OcrResult ocrResult) {
    final results = <Map<String, String>>[];

    for (final line in ocrResult.lines) {
      final text = line.text.trim();
      if (!_isValidTextCandidate(text)) continue;

      final pair = _trySplitBySeparator(text);
      if (pair != null) results.add(pair);
    }

    return _dedupe(results);
  }

  static Map<String, String>? _trySplitBySeparator(String text) {
    final stripped = _stripLeadingNumbering(text);
    if (stripped.length < 4) return null;

    for (final pattern in _separatorPatterns) {
      final match = pattern.firstMatch(stripped);
      if (match == null) continue;

      final a = stripped.substring(0, match.start).trim();
      final b = stripped.substring(match.end).trim();
      final normalized = _normalizePair(a, b);
      if (normalized != null) return normalized;
    }

    return null;
  }

  static List<Map<String, String>> _parseConsecutiveLinePairs(OcrResult ocrResult) {
    final lines = ocrResult.lines
        .map((line) => _stripLeadingNumbering(line.text.trim()))
        .where(_isValidTextCandidate)
        .toList();

    final results = <Map<String, String>>[];
    for (var i = 0; i + 1 < lines.length; i += 2) {
      final normalized = _normalizePair(lines[i], lines[i + 1]);
      if (normalized != null) results.add(normalized);
    }

    return _dedupe(results);
  }

  static bool _isValidTextCandidate(String text) {
    final value = text.trim();
    if (value.length <= 1) return false;
    if (_noisePattern.hasMatch(value.toLowerCase())) return false;
    return RegExp(r'\p{L}', unicode: true).hasMatch(value);
  }

  static Map<String, String>? _normalizePair(String first, String second) {
    final a = _cleanText(first);
    final b = _cleanText(second);
    if (!_isValidPair(a, b)) return null;

    if (_shouldSwap(a, b)) {
      return <String, String>{'term': b, 'definition': a};
    }
    return <String, String>{'term': a, 'definition': b};
  }

  static bool _isValidPair(String term, String definition) {
    if (!_isValidTextCandidate(term) || !_isValidTextCandidate(definition)) {
      return false;
    }
    if (term.length > 120 || definition.length > 260) return false;
    if (term.toLowerCase() == definition.toLowerCase()) return false;
    return true;
  }

  static bool _shouldSwap(String term, String definition) {
    final termScore = _termLikelihood(term);
    final definitionScore = _termLikelihood(definition);
    return definitionScore > termScore + 0.8;
  }

  static double _termLikelihood(String text) {
    final value = text.trim();
    if (value.isEmpty) return 0;

    var score = 0.0;
    final latinChars = RegExp(r'[A-Za-z]').allMatches(value).length;
    final cjkChars = RegExp(r'[\u4E00-\u9FFF]').allMatches(value).length;
    final words = value.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).length;

    if (latinChars > 0 && cjkChars == 0) score += 2.2;
    if (cjkChars > 0 && latinChars == 0) score -= 1.4;
    if (latinChars > cjkChars && latinChars > 2) score += 0.8;
    if (words <= 3) score += 0.9;
    if (words >= 6) score -= 0.9;
    if (value.length <= 18) score += 0.6;
    if (value.length >= 40) score -= 0.8;
    if (RegExp(r'^[A-Za-z][A-Za-z\s\-/()]*$').hasMatch(value)) score += 1.0;
    if (RegExp(r'[，。；：、]').hasMatch(value)) score -= 0.6;

    return score;
  }

  static String _stripLeadingNumbering(String text) {
    return text.replaceFirst(RegExp(r'^\(?\d+[\)\.\-:]?\s*'), '').trim();
  }

  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'^[\s\-\u2022\.\)\(]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<Map<String, String>> _pairMapsFromRaw(List<_Pair> rawPairs) {
    return _dedupe(rawPairs
        .map((pair) => _normalizePair(pair.left, pair.right))
        .whereType<Map<String, String>>()
        .toList());
  }

  static List<Map<String, String>> _dedupe(List<Map<String, String>> pairs) {
    final seen = <String>{};
    final deduped = <Map<String, String>>[];

    for (final pair in pairs) {
      final term = (pair['term'] ?? '').trim();
      final definition = (pair['definition'] ?? '').trim();
      if (term.isEmpty || definition.isEmpty) continue;

      final key = '${term.toLowerCase()}|${definition.toLowerCase()}';
      if (seen.add(key)) {
        deduped.add(<String, String>{
          'term': term,
          'definition': definition,
        });
      }
    }

    return deduped;
  }
}

class _Pair {
  const _Pair({required this.left, required this.right});

  final String left;
  final String right;
}

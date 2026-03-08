import 'package:flutter/foundation.dart';

import 'ocr_service.dart';

/// Extracts term-definition pairs from OCR results using spatial analysis.
///
/// No API required — runs entirely on-device.
/// Works best with structured vocabulary lists (two-column tables,
/// separator-delimited lists, numbered entries).
class OcrParserService {
  /// Common separators between term and definition in a single line.
  static final _separatorPatterns = [
    RegExp(r'\s{3,}'),         // 3+ spaces (tab-like gap)
    RegExp(r'\t+'),            // actual tabs
    RegExp(r'\s*[—–\-]{1,3}\s+'), // dashes: — – - (with surrounding space)
    RegExp(r'\s*[:：]\s+'),    // colon separators
    RegExp(r'\s*[=＝]\s+'),    // equals sign
  ];

  /// Noise patterns to skip (headers, page numbers, labels).
  static final _noisePattern = RegExp(
    r'^(unit|lesson|chapter|page|vocabulary|word\s*list|exercise|'
    r'name|class|date|score|total|answer|題號|姓名|班級|座號|'
    r'日期|分數|單元|課次|第\s*\d+\s*[課單頁章]|'
    r'[\d\s\.\-/]+)$',
    caseSensitive: false,
  );

  /// Parse OCR result into flashcard pairs using spatial analysis.
  ///
  /// Strategy priority:
  /// 1. Two-column layout detection (most common for vocab tables)
  /// 2. Single-line separator splitting (dash/colon/tab separated)
  /// 3. Consecutive-line pairing (term on one line, definition on next)
  static List<Map<String, String>> parseVocabularyTable(OcrResult ocrResult) {
    if (ocrResult.lines.isEmpty) return [];

    // Strategy 1: Try two-column spatial parsing.
    final twoColResults = _parseTwoColumnLayout(ocrResult);
    if (twoColResults.length >= 2) {
      if (kDebugMode) {
        debugPrint('OCR Parser: two-column layout → ${twoColResults.length} pairs');
      }
      return twoColResults;
    }

    // Strategy 2: Try separator-based single-line parsing.
    final sepResults = _parseSeparatorLines(ocrResult);
    if (sepResults.length >= 2) {
      if (kDebugMode) {
        debugPrint('OCR Parser: separator-based → ${sepResults.length} pairs');
      }
      return sepResults;
    }

    // Strategy 3: Try consecutive-line pairing (odd=term, even=definition).
    final pairResults = _parseConsecutiveLinePairs(ocrResult);
    if (pairResults.length >= 2) {
      if (kDebugMode) {
        debugPrint('OCR Parser: consecutive pairs → ${pairResults.length} pairs');
      }
      return pairResults;
    }

    // If all strategies yield fewer than 2 pairs, return best result.
    if (twoColResults.isNotEmpty) return twoColResults;
    if (sepResults.isNotEmpty) return sepResults;
    return pairResults;
  }

  // ─── Strategy 1: Two-Column Layout ─────────────────────────────

  static List<Map<String, String>> _parseTwoColumnLayout(OcrResult ocrResult) {
    final lines = List<OcrTextLine>.from(ocrResult.lines);
    if (lines.length < 2) return [];

    // Sort by Y position (top to bottom).
    lines.sort((a, b) => a.centerY.compareTo(b.centerY));

    // Group into rows: lines whose Y centers are close together.
    final rows = _clusterIntoRows(lines);

    // Check if we have a columnar layout: most rows should have 2+ segments.
    final multiSegRows = rows.where((r) => r.length >= 2).length;
    if (multiSegRows < 2) return [];

    // Find the column divider X position.
    final dividerX = _findColumnDivider(rows, ocrResult.imageSize.width);
    if (dividerX == null) return [];

    final results = <Map<String, String>>[];

    for (final row in rows) {
      if (row.length < 2) continue;

      // Split row into left (term) and right (definition) groups.
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

      // Sort each side by X for correct reading order.
      leftParts.sort((a, b) => a.left.compareTo(b.left));
      rightParts.sort((a, b) => a.left.compareTo(b.left));

      final term = leftParts.map((l) => l.text.trim()).join(' ').trim();
      final definition = rightParts.map((l) => l.text.trim()).join(' ').trim();

      if (_isValidPair(term, definition)) {
        results.add({'term': _cleanText(term), 'definition': _cleanText(definition)});
      }
    }

    return results;
  }

  /// Cluster lines into rows based on Y-coordinate proximity.
  static List<List<OcrTextLine>> _clusterIntoRows(List<OcrTextLine> sortedLines) {
    if (sortedLines.isEmpty) return [];

    final rows = <List<OcrTextLine>>[];
    var currentRow = <OcrTextLine>[sortedLines.first];

    for (var i = 1; i < sortedLines.length; i++) {
      final line = sortedLines[i];
      final prevLine = currentRow.last;

      // If this line's center Y is close to the previous line's,
      // they're in the same row.
      final threshold = prevLine.height * 0.6;
      if ((line.centerY - prevLine.centerY).abs() <= threshold) {
        currentRow.add(line);
      } else {
        rows.add(currentRow);
        currentRow = <OcrTextLine>[line];
      }
    }
    rows.add(currentRow);

    return rows;
  }

  /// Find the X coordinate that best divides left and right columns.
  static double? _findColumnDivider(
    List<List<OcrTextLine>> rows,
    double imageWidth,
  ) {
    // Collect all gap midpoints from multi-segment rows.
    final gaps = <double>[];

    for (final row in rows) {
      if (row.length < 2) continue;
      final sorted = List<OcrTextLine>.from(row)
        ..sort((a, b) => a.left.compareTo(b.left));

      // Find the largest horizontal gap in this row.
      var maxGap = 0.0;
      var maxGapMid = 0.0;
      for (var i = 0; i < sorted.length - 1; i++) {
        final gap = sorted[i + 1].left - sorted[i].right;
        if (gap > maxGap) {
          maxGap = gap;
          maxGapMid = (sorted[i].right + sorted[i + 1].left) / 2;
        }
      }
      if (maxGap > 10) {
        gaps.add(maxGapMid);
      }
    }

    if (gaps.isEmpty) return null;

    // Use median gap position as the divider.
    gaps.sort();
    return gaps[gaps.length ~/ 2];
  }

  // ─── Strategy 2: Separator-Based Lines ─────────────────────────

  static List<Map<String, String>> _parseSeparatorLines(OcrResult ocrResult) {
    final results = <Map<String, String>>[];

    for (final line in ocrResult.lines) {
      final text = line.text.trim();
      if (text.isEmpty || _isNoise(text)) continue;

      final pair = _trySplitBySeparator(text);
      if (pair != null) {
        results.add(pair);
      }
    }

    return results;
  }

  /// Try to split a single line into term-definition by separator.
  static Map<String, String>? _trySplitBySeparator(String text) {
    // Strip leading numbering: "1. ", "1) ", "(1) ", "① "
    final stripped = text.replaceFirst(
      RegExp(r'^[\(\（]?\d+[\)\）\.\、\s]*\s*'),
      '',
    ).trim();
    if (stripped.length < 3) return null;

    for (final pattern in _separatorPatterns) {
      final match = pattern.firstMatch(stripped);
      if (match == null) continue;

      final term = stripped.substring(0, match.start).trim();
      final definition = stripped.substring(match.end).trim();

      if (_isValidPair(term, definition)) {
        return {'term': _cleanText(term), 'definition': _cleanText(definition)};
      }
    }

    return null;
  }

  // ─── Strategy 3: Consecutive Line Pairing ──────────────────────

  static List<Map<String, String>> _parseConsecutiveLinePairs(OcrResult ocrResult) {
    // Filter out noise lines first.
    final cleanLines = ocrResult.lines
        .map((l) => l.text.trim())
        .where((t) => t.isNotEmpty && !_isNoise(t))
        .map((t) => t.replaceFirst(RegExp(r'^[\(\（]?\d+[\)\）\.\、\s]*\s*'), '').trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (cleanLines.length < 2) return [];

    // Check if alternating lines look like different languages
    // (e.g., English then Chinese, or vice versa).
    final results = <Map<String, String>>[];

    for (var i = 0; i + 1 < cleanLines.length; i += 2) {
      final a = cleanLines[i];
      final b = cleanLines[i + 1];

      if (_isValidPair(a, b)) {
        results.add({'term': _cleanText(a), 'definition': _cleanText(b)});
      }
    }

    return results;
  }

  // ─── Helpers ───────────────────────────────────────────────────

  static bool _isNoise(String text) {
    final t = text.trim().toLowerCase();
    if (t.length <= 1) return true;
    // Only noise if no letters at all (handles CJK correctly).
    if (!RegExp(r'\p{L}', unicode: true).hasMatch(t)) return true;
    if (_noisePattern.hasMatch(t)) return true;
    return false;
  }

  static bool _isValidPair(String term, String definition) {
    final t = term.trim();
    final d = definition.trim();
    if (t.isEmpty || d.isEmpty) return false;
    if (t.length > 200 || d.length > 500) return false;
    if (t.toLowerCase() == d.toLowerCase()) return false;
    if (_isNoise(t) || _isNoise(d)) return false;
    return true;
  }

  /// Remove common OCR artifacts.
  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'^\s*[\-\–\—•·]\s*'), '')  // leading bullets
        .replaceAll(RegExp(r'\s+'), ' ')                 // normalize whitespace
        .trim();
  }
}

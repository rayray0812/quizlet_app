import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/services/ocr_parser_service.dart';
import 'package:recall_app/services/ocr_service.dart';

OcrResult _makeOcrResult(List<OcrTextLine> lines) {
  var maxR = 0.0;
  var maxB = 0.0;
  for (final l in lines) {
    if (l.right > maxR) maxR = l.right;
    if (l.bottom > maxB) maxB = l.bottom;
  }
  return OcrResult(
    fullText: lines.map((l) => l.text).join('\n'),
    blockCount: lines.length,
    lineCount: lines.length,
    lines: lines,
    imageSize: Size(maxR + 50, maxB + 50),
  );
}

void main() {
  group('OcrParserService', () {
    test('parses two-column vocabulary table', () {
      // Simulate a two-column layout:
      // Left column (terms)         Right column (definitions)
      // apple                       蘋果
      // banana                      香蕉
      // grateful                    感激的
      final lines = [
        const OcrTextLine(text: 'apple', left: 10, top: 10, right: 100, bottom: 30),
        const OcrTextLine(text: '蘋果', left: 300, top: 10, right: 370, bottom: 30),
        const OcrTextLine(text: 'banana', left: 10, top: 50, right: 110, bottom: 70),
        const OcrTextLine(text: '香蕉', left: 300, top: 50, right: 370, bottom: 70),
        const OcrTextLine(text: 'grateful', left: 10, top: 90, right: 130, bottom: 110),
        const OcrTextLine(text: '感激的', left: 300, top: 90, right: 390, bottom: 110),
      ];

      final result = OcrParserService.parseVocabularyTable(_makeOcrResult(lines));

      expect(result.length, 3);
      expect(result[0]['term'], 'apple');
      expect(result[0]['definition'], '蘋果');
      expect(result[1]['term'], 'banana');
      expect(result[1]['definition'], '香蕉');
      expect(result[2]['term'], 'grateful');
      expect(result[2]['definition'], '感激的');
    });

    test('parses separator-based lines (dash)', () {
      final lines = [
        const OcrTextLine(text: 'apple - 蘋果', left: 10, top: 10, right: 400, bottom: 30),
        const OcrTextLine(text: 'banana - 香蕉', left: 10, top: 50, right: 400, bottom: 70),
        const OcrTextLine(text: 'cherry - 櫻桃', left: 10, top: 90, right: 400, bottom: 110),
      ];

      final result = OcrParserService.parseVocabularyTable(_makeOcrResult(lines));

      expect(result.length, 3);
      expect(result[0]['term'], 'apple');
      expect(result[0]['definition'], '蘋果');
    });

    test('parses separator-based lines (colon)', () {
      final lines = [
        const OcrTextLine(text: 'apple: 蘋果', left: 10, top: 10, right: 400, bottom: 30),
        const OcrTextLine(text: 'banana: 香蕉', left: 10, top: 50, right: 400, bottom: 70),
      ];

      final result = OcrParserService.parseVocabularyTable(_makeOcrResult(lines));

      expect(result.length, 2);
      expect(result[0]['term'], 'apple');
      expect(result[0]['definition'], '蘋果');
    });

    test('parses numbered list with separators', () {
      final lines = [
        const OcrTextLine(text: '1. apple - 蘋果', left: 10, top: 10, right: 400, bottom: 30),
        const OcrTextLine(text: '2. banana - 香蕉', left: 10, top: 50, right: 400, bottom: 70),
        const OcrTextLine(text: '3) cherry - 櫻桃', left: 10, top: 90, right: 400, bottom: 110),
      ];

      final result = OcrParserService.parseVocabularyTable(_makeOcrResult(lines));

      expect(result.length, 3);
      expect(result[0]['term'], 'apple');
      expect(result[1]['term'], 'banana');
      expect(result[2]['term'], 'cherry');
    });

    test('skips noise lines (headers, page numbers)', () {
      final lines = [
        const OcrTextLine(text: 'Unit 1', left: 10, top: 10, right: 100, bottom: 30),
        const OcrTextLine(text: 'Vocabulary', left: 10, top: 40, right: 150, bottom: 60),
        const OcrTextLine(text: 'apple - 蘋果', left: 10, top: 80, right: 400, bottom: 100),
        const OcrTextLine(text: 'banana - 香蕉', left: 10, top: 120, right: 400, bottom: 140),
        const OcrTextLine(text: '42', left: 300, top: 500, right: 320, bottom: 520),
      ];

      final result = OcrParserService.parseVocabularyTable(_makeOcrResult(lines));

      expect(result.length, 2);
      expect(result[0]['term'], 'apple');
      expect(result[1]['term'], 'banana');
    });

    test('skips duplicate term-definition pairs', () {
      final lines = [
        const OcrTextLine(text: 'apple', left: 10, top: 10, right: 100, bottom: 30),
        const OcrTextLine(text: 'apple', left: 300, top: 10, right: 400, bottom: 30),
      ];

      final result = OcrParserService.parseVocabularyTable(_makeOcrResult(lines));

      // term == definition → should be filtered
      expect(result.length, 0);
    });

    test('parses consecutive line pairs', () {
      // When neither two-column nor separator works, try alternating lines
      final lines = [
        const OcrTextLine(text: 'apple', left: 10, top: 10, right: 100, bottom: 30),
        const OcrTextLine(text: '蘋果', left: 10, top: 40, right: 80, bottom: 60),
        const OcrTextLine(text: 'banana', left: 10, top: 70, right: 120, bottom: 90),
        const OcrTextLine(text: '香蕉', left: 10, top: 100, right: 80, bottom: 120),
      ];

      final result = OcrParserService.parseVocabularyTable(_makeOcrResult(lines));

      expect(result.length, 2);
      expect(result[0]['term'], 'apple');
      expect(result[0]['definition'], '蘋果');
      expect(result[1]['term'], 'banana');
      expect(result[1]['definition'], '香蕉');
    });

    test('handles empty OCR result', () {
      final result = OcrParserService.parseVocabularyTable(
        const OcrResult(
          fullText: '',
          blockCount: 0,
          lineCount: 0,
          lines: [],
          imageSize: Size(100, 100),
        ),
      );
      expect(result, isEmpty);
    });

    test('parses lines with wide space separator', () {
      final lines = [
        const OcrTextLine(text: 'apple       蘋果', left: 10, top: 10, right: 400, bottom: 30),
        const OcrTextLine(text: 'banana      香蕉', left: 10, top: 50, right: 400, bottom: 70),
      ];

      final result = OcrParserService.parseVocabularyTable(_makeOcrResult(lines));

      expect(result.length, 2);
      expect(result[0]['term'], 'apple');
      expect(result[0]['definition'], '蘋果');
    });
  });
}

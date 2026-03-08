import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// A single line of text with its spatial position in the image.
class OcrTextLine {
  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  const OcrTextLine({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  double get centerY => (top + bottom) / 2;
  double get centerX => (left + right) / 2;
  double get height => bottom - top;
  double get width => right - left;
}

class OcrResult {
  final String fullText;
  final int blockCount;
  final int lineCount;
  final List<OcrTextLine> lines;
  final Size imageSize;

  const OcrResult({
    required this.fullText,
    required this.blockCount,
    required this.lineCount,
    required this.lines,
    required this.imageSize,
  });

  /// Whether enough text was detected to be useful.
  bool get hasEnoughText => lineCount >= 2;
}

class OcrService {
  /// Recognizes text from an image file using on-device ML Kit.
  ///
  /// Uses Chinese script recognizer (handles CJK + Latin).
  /// Falls back to Latin-only recognizer if Chinese model unavailable.
  /// Returns null if all OCR attempts fail (graceful degradation).
  static Future<OcrResult?> recognizeFromPath(String path) async {
    if (kIsWeb) return null;

    // Try Chinese recognizer first (handles both CJK and Latin text).
    final result = await _tryRecognize(path, TextRecognitionScript.chinese);
    if (result != null) return result;

    // Fall back to Latin-only if Chinese model not available.
    return _tryRecognize(path, TextRecognitionScript.latin);
  }

  static Future<OcrResult?> _tryRecognize(
    String path,
    TextRecognitionScript script,
  ) async {
    final recognizer = TextRecognizer(script: script);
    try {
      final inputImage = InputImage.fromFilePath(path);
      final recognized = await recognizer.processImage(inputImage);

      final lines = <OcrTextLine>[];
      var lineCount = 0;

      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          lineCount++;
          final box = line.boundingBox;
          lines.add(OcrTextLine(
            text: line.text,
            left: box.left,
            top: box.top,
            right: box.right,
            bottom: box.bottom,
          ));
        }
      }

      // Estimate image size from the outermost bounding boxes.
      var imgW = 0.0;
      var imgH = 0.0;
      for (final l in lines) {
        if (l.right > imgW) imgW = l.right;
        if (l.bottom > imgH) imgH = l.bottom;
      }

      return OcrResult(
        fullText: recognized.text,
        blockCount: recognized.blocks.length,
        lineCount: lineCount,
        lines: lines,
        imageSize: Size(imgW, imgH),
      );
    } catch (e) {
      debugPrint('OCR ($script) failed: $e');
      return null;
    } finally {
      recognizer.close();
    }
  }
}

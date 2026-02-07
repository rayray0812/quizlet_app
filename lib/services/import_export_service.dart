import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' if (dart.library.html) 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/models/flashcard.dart';

class ImportExportService {
  /// Export a study set as JSON and share via system share sheet.
  Future<void> exportAsJson(StudySet studySet) async {
    if (kIsWeb) return; // File export not supported on web
    final data = {
      'title': studySet.title,
      'description': studySet.description,
      'cards': studySet.cards
          .map((c) => {'term': c.term, 'definition': c.definition})
          .toList(),
    };
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/${_sanitizeFilename(studySet.title)}.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([XFile(file.path)],
        text: '${studySet.title} (${studySet.cards.length} cards)');
  }

  /// Export a study set as CSV and share via system share sheet.
  Future<void> exportAsCsv(StudySet studySet) async {
    if (kIsWeb) return; // File export not supported on web
    final buffer = StringBuffer();
    buffer.writeln('term,definition');
    for (final card in studySet.cards) {
      buffer.writeln('${_csvEscape(card.term)},${_csvEscape(card.definition)}');
    }
    final dir = await getTemporaryDirectory();
    final file =
        File('${dir.path}/${_sanitizeFilename(studySet.title)}.csv');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)],
        text: '${studySet.title} (${studySet.cards.length} cards)');
  }

  /// Pick a JSON or CSV file and parse it into a StudySet for preview.
  Future<StudySet?> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv'],
      withData: true, // Ensures bytes are available on web
    );
    if (result == null || result.files.isEmpty) return null;

    final platformFile = result.files.single;
    final String content;
    final String? ext = platformFile.extension?.toLowerCase();

    // On web, path is null ??use bytes instead
    if (kIsWeb || platformFile.path == null) {
      final bytes = platformFile.bytes;
      if (bytes == null) return null;
      content = utf8.decode(bytes);
    } else {
      content = await File(platformFile.path!).readAsString();
    }

    if (ext == 'json') {
      return _parseJson(content);
    } else if (ext == 'csv') {
      return _parseCsv(content);
    }
    return null;
  }

  StudySet? _parseJson(String content) {
    try {
      final data = json.decode(content) as Map<String, dynamic>;
      final title = data['title'] as String? ?? 'Imported Set';
      final description = data['description'] as String? ?? '';
      final cardsData = data['cards'] as List? ?? [];

      final cards = cardsData.map((c) {
        return Flashcard(
          id: const Uuid().v4(),
          term: (c['term'] as String?) ?? '',
          definition: (c['definition'] as String?) ?? '',
        );
      }).toList();

      return StudySet(
        id: const Uuid().v4(),
        title: title,
        description: description,
        createdAt: DateTime.now().toUtc(),
        cards: cards,
      );
    } catch (e) {
      developer.log('JSON import parse error: $e', name: 'ImportExportService');
      return null;
    }
  }

  StudySet? _parseCsv(String content) {
    try {
      final rows = _parseCsvContent(content);
      final cards = <Flashcard>[];

      for (var i = 0; i < rows.length; i++) {
        final parts = rows[i];
        if (parts.isEmpty) continue;

        // Skip header row
        if (i == 0 &&
            parts.first.trim().toLowerCase() == 'term' &&
            parts.length > 1 &&
            parts[1].trim().toLowerCase() == 'definition') {
          continue;
        }

        if (parts.length >= 2) {
          cards.add(Flashcard(
            id: const Uuid().v4(),
            term: parts[0],
            definition: parts[1],
          ));
        }
      }

      if (cards.isEmpty) return null;

      return StudySet(
        id: const Uuid().v4(),
        title: 'Imported Set',
        createdAt: DateTime.now().toUtc(),
        cards: cards,
      );
    } catch (e) {
      developer.log('CSV import parse error: $e', name: 'ImportExportService');
      return null;
    }
  }

  /// Testing hook for CSV parser behavior.
  StudySet? parseCsvForTesting(String content) => _parseCsv(content);

  /// Parse CSV content with support for quoted fields and embedded newlines.
  List<List<String>> _parseCsvContent(String content) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;

    void commitField() {
      row.add(field.toString());
      field.clear();
    }

    void commitRow() {
      if (row.isEmpty) return;
      final hasNonEmpty = row.any((cell) => cell.trim().isNotEmpty);
      if (hasNonEmpty) {
        rows.add(row);
      }
      row = <String>[];
    }

    for (var i = 0; i < content.length; i++) {
      final ch = content[i];

      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < content.length && content[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
        continue;
      }

      if (ch == '"') {
        inQuotes = true;
        continue;
      }

      if (ch == ',') {
        commitField();
        continue;
      }

      if (ch == '\n' || ch == '\r') {
        if (ch == '\r' && i + 1 < content.length && content[i + 1] == '\n') {
          i++;
        }
        commitField();
        commitRow();
        continue;
      }

      field.write(ch);
    }

    commitField();
    commitRow();
    return rows;
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _sanitizeFilename(String name) {
    final sanitized = name.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_');
    return sanitized.isEmpty ? 'export' : sanitized;
  }
}


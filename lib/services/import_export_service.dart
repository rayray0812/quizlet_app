import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:quizlet_app/models/study_set.dart';
import 'package:quizlet_app/models/flashcard.dart';

class ImportExportService {
  /// Export a study set as JSON and share via system share sheet.
  Future<void> exportAsJson(StudySet studySet) async {
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
    );
    if (result == null || result.files.isEmpty) return null;

    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    final ext = result.files.single.extension?.toLowerCase();

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
        createdAt: DateTime.now(),
        cards: cards,
      );
    } catch (_) {
      return null;
    }
  }

  StudySet? _parseCsv(String content) {
    try {
      final lines = const LineSplitter().convert(content);
      final cards = <Flashcard>[];

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        // Skip header row
        if (i == 0 && line.toLowerCase().startsWith('term')) continue;

        final parts = _parseCsvLine(line);
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
        createdAt: DateTime.now(),
        cards: cards,
      );
    } catch (_) {
      return null;
    }
  }

  /// Parse a single CSV line respecting quoted fields.
  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            buffer.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          buffer.write(ch);
        }
      } else {
        if (ch == '"') {
          inQuotes = true;
        } else if (ch == ',') {
          result.add(buffer.toString());
          buffer.clear();
        } else {
          buffer.write(ch);
        }
      }
    }
    result.add(buffer.toString());
    return result;
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_');
  }
}

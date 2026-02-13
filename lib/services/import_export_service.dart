import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' if (dart.library.html) 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:recall_app/models/card_progress.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/models/review_log.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/services/local_storage_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

typedef BackupImportResult = ({
  int setCount,
  int progressCount,
  int reviewLogCount,
});

class ImportExportService {
  static const _backupVersion = 1;

  /// Export a study set as JSON and share via system share sheet.
  Future<void> exportAsJson(StudySet studySet) async {
    if (kIsWeb) return; // File export not supported on web
    final data = {
      'title': studySet.title,
      'description': studySet.description,
      'cards': studySet.cards
          .map(
            (c) => {
              'term': c.term,
              'definition': c.definition,
              'exampleSentence': c.exampleSentence,
            },
          )
          .toList(),
    };
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_sanitizeFilename(studySet.title)}.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([
      XFile(file.path),
    ], text: '${studySet.title} (${studySet.cards.length} cards)');
  }

  /// Export a study set as CSV and share via system share sheet.
  Future<void> exportAsCsv(StudySet studySet) async {
    if (kIsWeb) return; // File export not supported on web
    final buffer = StringBuffer();
    buffer.writeln('term,definition,example_sentence');
    for (final card in studySet.cards) {
      buffer.writeln(
        '${_csvEscape(card.term)},${_csvEscape(card.definition)},${_csvEscape(card.exampleSentence)}',
      );
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_sanitizeFilename(studySet.title)}.csv');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([
      XFile(file.path),
    ], text: '${studySet.title} (${studySet.cards.length} cards)');
  }

  /// Pick a JSON or CSV file and parse it into a StudySet for preview.
  Future<StudySet?> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final platformFile = result.files.single;
    final String content;
    final String? ext = platformFile.extension?.toLowerCase();

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

  Future<void> exportEncryptedBackup({
    required LocalStorageService localStorage,
    required String passphrase,
  }) async {
    if (kIsWeb) return;
    final normalized = passphrase.trim();
    if (normalized.length < 8) {
      throw Exception('Passphrase must be at least 8 characters.');
    }

    final payload = json.encode({
      'version': _backupVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'studySets': localStorage
          .getAllStudySets()
          .map((e) => e.toJson())
          .toList(),
      'cardProgress': localStorage
          .getAllCardProgress()
          .map((e) => e.toJson())
          .toList(),
      'reviewLogs': localStorage
          .getAllReviewLogs()
          .map((e) => e.toJson())
          .toList(),
    });

    final encrypted = await _encryptPayload(utf8.encode(payload), normalized);
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      ':',
      '-',
    );
    final file = File('${dir.path}/recall_backup_$timestamp.recallbak');
    await file.writeAsString(json.encode(encrypted));
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Recall encrypted backup');
  }

  Future<BackupImportResult> importEncryptedBackup({
    required LocalStorageService localStorage,
    required String passphrase,
  }) async {
    final normalized = passphrase.trim();
    if (normalized.length < 8) {
      throw Exception('Passphrase must be at least 8 characters.');
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['recallbak', 'json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      throw Exception('No backup file selected.');
    }

    final platformFile = result.files.single;
    final String content;
    if (kIsWeb || platformFile.path == null) {
      final bytes = platformFile.bytes;
      if (bytes == null) throw Exception('Unable to read backup file bytes.');
      content = utf8.decode(bytes);
    } else {
      content = await File(platformFile.path!).readAsString();
    }

    final envelope = json.decode(content) as Map<String, dynamic>;
    final decrypted = await _decryptPayload(envelope, normalized);
    final data = json.decode(utf8.decode(decrypted)) as Map<String, dynamic>;

    final studySets = ((data['studySets'] as List?) ?? const [])
        .map((e) => StudySet.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final cardProgress = ((data['cardProgress'] as List?) ?? const [])
        .map((e) => CardProgress.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final reviewLogs = ((data['reviewLogs'] as List?) ?? const [])
        .map((e) => ReviewLog.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    await localStorage.restoreAllStudyData(
      sets: studySets,
      progresses: cardProgress,
      logs: reviewLogs,
    );

    return (
      setCount: studySets.length,
      progressCount: cardProgress.length,
      reviewLogCount: reviewLogs.length,
    );
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
          exampleSentence: (c['exampleSentence'] as String?) ?? '',
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

        if (i == 0 &&
            parts.first.trim().toLowerCase() == 'term' &&
            parts.length > 1 &&
            parts[1].trim().toLowerCase() == 'definition') {
          continue;
        }

        if (parts.length >= 2) {
          cards.add(
            Flashcard(
              id: const Uuid().v4(),
              term: parts[0],
              definition: parts[1],
              exampleSentence: parts.length > 2 ? parts[2] : '',
            ),
          );
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

  StudySet? parseCsvForTesting(String content) => _parseCsv(content);

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
    final sanitized = name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(' ', '_');
    return sanitized.isEmpty ? 'export' : sanitized;
  }

  Future<Map<String, dynamic>> _encryptPayload(
    List<int> plainBytes,
    String passphrase,
  ) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final nonce = List<int>.generate(12, (_) => random.nextInt(256));
    final key = await _deriveKey(passphrase, salt);
    final algorithm = AesGcm.with256bits();
    final secretBox = await algorithm.encrypt(
      plainBytes,
      secretKey: key,
      nonce: nonce,
    );

    return {
      'version': _backupVersion,
      'kdf': {
        'name': 'pbkdf2-sha256',
        'iterations': 100000,
        'salt': base64Encode(salt),
      },
      'cipher': {
        'name': 'aes-gcm-256',
        'nonce': base64Encode(secretBox.nonce),
        'mac': base64Encode(secretBox.mac.bytes),
      },
      'payload': base64Encode(secretBox.cipherText),
    };
  }

  Future<List<int>> _decryptPayload(
    Map<String, dynamic> envelope,
    String passphrase,
  ) async {
    final kdf = Map<String, dynamic>.from(envelope['kdf'] as Map? ?? const {});
    final cipher = Map<String, dynamic>.from(
      envelope['cipher'] as Map? ?? const {},
    );
    final payloadBase64 = envelope['payload'] as String? ?? '';
    if (payloadBase64.isEmpty) {
      throw Exception('Invalid backup payload.');
    }

    final iterations = (kdf['iterations'] as num?)?.toInt() ?? 100000;
    final salt = base64Decode(kdf['salt'] as String? ?? '');
    final nonce = base64Decode(cipher['nonce'] as String? ?? '');
    final mac = base64Decode(cipher['mac'] as String? ?? '');
    final cipherText = base64Decode(payloadBase64);

    final key = await _deriveKey(passphrase, salt, iterations: iterations);
    final algorithm = AesGcm.with256bits();
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
    return algorithm.decrypt(secretBox, secretKey: key);
  }

  Future<SecretKey> _deriveKey(
    String passphrase,
    List<int> salt, {
    int iterations = 100000,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    return pbkdf2.deriveKeyFromPassword(password: passphrase, nonce: salt);
  }
}

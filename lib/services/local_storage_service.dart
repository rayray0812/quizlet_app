import 'package:hive/hive.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/features/study/models/conversation_transcript.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/models/card_progress.dart';
import 'package:recall_app/models/review_log.dart';

class LocalStorageService {
  Box get _box => Hive.box(AppConstants.hiveStudySetsBox);
  Box get _progressBox => Hive.box(AppConstants.hiveCardProgressBox);
  Box get _reviewLogBox => Hive.box(AppConstants.hiveReviewLogsBox);
  Box get _settingsBox => Hive.box(AppConstants.hiveSettingsBox);

  // ?? StudySet CRUD ??

  List<StudySet> getAllStudySets() {
    return _box.values.whereType<StudySet>().toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  StudySet? getStudySet(String id) {
    return _box.get(id) as StudySet?;
  }

  Future<void> saveStudySet(StudySet studySet) async {
    await _box.put(studySet.id, studySet);
  }

  Future<void> deleteStudySet(String id) async {
    await _box.delete(id);
  }

  List<String> getDeletedStudySetIds() {
    final raw = (_settingsBox.get(
              AppConstants.settingDeletedStudySetIdsKey,
              defaultValue: <dynamic>[],
            ) as List)
        .cast<dynamic>();
    return raw.map((e) => e.toString()).toList();
  }

  Future<void> markStudySetDeleted(String id) async {
    final ids = getDeletedStudySetIds();
    if (!ids.contains(id)) {
      ids.add(id);
      await _settingsBox.put(AppConstants.settingDeletedStudySetIdsKey, ids);
    }
  }

  Future<void> clearDeletedStudySetId(String id) async {
    final ids = getDeletedStudySetIds()..removeWhere((item) => item == id);
    await _settingsBox.put(AppConstants.settingDeletedStudySetIdsKey, ids);
  }

  List<StudySet> getUnsyncedSets() {
    return _box.values.whereType<StudySet>().where((s) => !s.isSynced).toList();
  }

  Future<void> markAsSynced(String id) async {
    final set = getStudySet(id);
    if (set != null) {
      await saveStudySet(set.copyWith(isSynced: true));
    }
  }

  // ?? CardProgress CRUD ??

  Future<void> saveCardProgress(CardProgress progress) async {
    await _progressBox.put(progress.cardId, progress);
  }

  CardProgress? getCardProgress(String cardId) {
    return _progressBox.get(cardId) as CardProgress?;
  }

  List<CardProgress> getAllCardProgress() {
    return _progressBox.values.whereType<CardProgress>().toList();
  }

  List<CardProgress> getUnsyncedCardProgress() {
    return _progressBox.values
        .whereType<CardProgress>()
        .where((p) => !p.isSynced)
        .toList();
  }

  List<CardProgress> getCardProgressForSet(String setId) {
    return getAllCardProgress().where((p) => p.setId == setId).toList();
  }

  List<CardProgress> getDueCardProgress({DateTime? now}) {
    final cutoff = now ?? DateTime.now().toUtc();
    return getAllCardProgress().where((p) {
      if (p.due == null) return true; // New cards (never reviewed)
      return p.due!.isBefore(cutoff) || p.due!.isAtSameMomentAs(cutoff);
    }).toList();
  }

  Future<void> deleteCardProgressForSet(String setId) async {
    final keys = <dynamic>[];
    for (final entry in _progressBox.toMap().entries) {
      final value = entry.value;
      if (value is CardProgress && value.setId == setId) {
        keys.add(entry.key);
      }
    }
    await _progressBox.deleteAll(keys);
  }

  Future<void> deleteCardProgress(String cardId) async {
    await _progressBox.delete(cardId);
  }

  Future<void> markCardProgressAsSynced(String cardId) async {
    final progress = getCardProgress(cardId);
    if (progress != null && !progress.isSynced) {
      await saveCardProgress(progress.copyWith(isSynced: true));
    }
  }

  // ?? ReviewLog CRUD ??

  Future<void> saveReviewLog(ReviewLog log) async {
    await _reviewLogBox.put(log.id, log);
  }

  ReviewLog? getReviewLog(String id) {
    return _reviewLogBox.get(id) as ReviewLog?;
  }

  List<ReviewLog> getAllReviewLogs() {
    return _reviewLogBox.values.whereType<ReviewLog>().toList();
  }

  List<ReviewLog> getUnsyncedReviewLogs() {
    return _reviewLogBox.values
        .whereType<ReviewLog>()
        .where((log) => !log.isSynced)
        .toList();
  }

  List<ReviewLog> getReviewLogsForDate(DateTime date) {
    final start = DateTime.utc(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return getAllReviewLogs().where((log) {
      return !log.reviewedAt.isBefore(start) && log.reviewedAt.isBefore(end);
    }).toList();
  }

  List<ReviewLog> getReviewLogsInRange(DateTime from, DateTime to) {
    return getAllReviewLogs().where((log) {
      return !log.reviewedAt.isBefore(from) && log.reviewedAt.isBefore(to);
    }).toList();
  }

  List<ReviewLog> getReviewLogsForSet(String setId) {
    return getAllReviewLogs().where((log) => log.setId == setId).toList();
  }

  Future<void> markReviewLogAsSynced(String id) async {
    final log = getReviewLog(id);
    if (log != null && !log.isSynced) {
      await saveReviewLog(log.copyWith(isSynced: true));
    }
  }

  Future<void> deleteReviewLogsForSet(String setId) async {
    final keys = <dynamic>[];
    for (final entry in _reviewLogBox.toMap().entries) {
      final value = entry.value;
      if (value is ReviewLog && value.setId == setId) {
        keys.add(entry.key);
      }
    }
    await _reviewLogBox.deleteAll(keys);
  }

  Future<void> clearAllStudyData() async {
    await _reviewLogBox.clear();
    await _progressBox.clear();
    await _box.clear();
  }

  Future<void> restoreAllStudyData({
    required List<StudySet> sets,
    required List<CardProgress> progresses,
    required List<ReviewLog> logs,
  }) async {
    await clearAllStudyData();
    for (final set in sets) {
      await saveStudySet(set);
    }
    for (final progress in progresses) {
      await saveCardProgress(progress);
    }
    for (final log in logs) {
      await saveReviewLog(log);
    }
  }

  Future<void> saveStudySetsBatch(List<StudySet> sets) async {
    if (sets.isEmpty) return;
    final payload = <String, StudySet>{for (final set in sets) set.id: set};
    await _box.putAll(payload);
  }

  Future<void> saveCardProgressBatch(List<CardProgress> progresses) async {
    if (progresses.isEmpty) return;
    final payload = <String, CardProgress>{
      for (final progress in progresses) progress.cardId: progress,
    };
    await _progressBox.putAll(payload);
  }

  Future<void> saveReviewLogsBatch(List<ReviewLog> logs) async {
    if (logs.isEmpty) return;
    final payload = <String, ReviewLog>{for (final log in logs) log.id: log};
    await _reviewLogBox.putAll(payload);
  }

  Future<void> deleteCardProgressBatch(List<String> cardIds) async {
    if (cardIds.isEmpty) return;
    await _progressBox.deleteAll(cardIds);
  }

  Future<void> markStudySetsAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final payload = <String, StudySet>{};
    for (final id in ids) {
      final set = getStudySet(id);
      if (set != null && !set.isSynced) {
        payload[id] = set.copyWith(isSynced: true);
      }
    }
    if (payload.isNotEmpty) {
      await _box.putAll(payload);
    }
  }

  Future<void> markCardProgressAsSyncedBatch(List<String> cardIds) async {
    if (cardIds.isEmpty) return;
    final payload = <String, CardProgress>{};
    for (final cardId in cardIds) {
      final progress = getCardProgress(cardId);
      if (progress != null && !progress.isSynced) {
        payload[cardId] = progress.copyWith(isSynced: true);
      }
    }
    if (payload.isNotEmpty) {
      await _progressBox.putAll(payload);
    }
  }

  Future<void> markReviewLogsAsSyncedBatch(List<String> ids) async {
    if (ids.isEmpty) return;
    final payload = <String, ReviewLog>{};
    for (final id in ids) {
      final log = getReviewLog(id);
      if (log != null && !log.isSynced) {
        payload[id] = log.copyWith(isSynced: true);
      }
    }
    if (payload.isNotEmpty) {
      await _reviewLogBox.putAll(payload);
    }
  }

  // — Conversation Transcripts —

  static const _transcriptsKey = 'conversation_transcripts';

  Future<void> saveConversationTranscript(
      ConversationTranscript transcript) async {
    final all = getAllConversationTranscripts();
    all.insert(0, transcript);
    // Keep at most 50 transcripts
    final trimmed = all.take(50).toList();
    await _settingsBox.put(
        _transcriptsKey, ConversationTranscript.encodeList(trimmed));
  }

  List<ConversationTranscript> getAllConversationTranscripts() {
    final raw = _settingsBox.get(_transcriptsKey) as String?;
    if (raw == null || raw.isEmpty) return [];
    return ConversationTranscript.decodeList(raw);
  }

  Future<void> deleteConversationTranscript(String id) async {
    final all = getAllConversationTranscripts();
    all.removeWhere((t) => t.id == id);
    await _settingsBox.put(
        _transcriptsKey, ConversationTranscript.encodeList(all));
  }
}

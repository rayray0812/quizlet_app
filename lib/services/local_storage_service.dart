import 'package:hive/hive.dart';
import 'package:quizlet_app/core/constants/app_constants.dart';
import 'package:quizlet_app/models/study_set.dart';
import 'package:quizlet_app/models/card_progress.dart';
import 'package:quizlet_app/models/review_log.dart';

class LocalStorageService {
  Box get _box => Hive.box(AppConstants.hiveStudySetsBox);
  Box get _progressBox => Hive.box(AppConstants.hiveCardProgressBox);
  Box get _reviewLogBox => Hive.box(AppConstants.hiveReviewLogsBox);

  // ── StudySet CRUD ──

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

  List<StudySet> getUnsyncedSets() {
    return getAllStudySets().where((s) => !s.isSynced).toList();
  }

  Future<void> markAsSynced(String id) async {
    final set = getStudySet(id);
    if (set != null) {
      await saveStudySet(set.copyWith(isSynced: true));
    }
  }

  // ── CardProgress CRUD ──

  Future<void> saveCardProgress(CardProgress progress) async {
    await _progressBox.put(progress.cardId, progress);
  }

  CardProgress? getCardProgress(String cardId) {
    return _progressBox.get(cardId) as CardProgress?;
  }

  List<CardProgress> getAllCardProgress() {
    return _progressBox.values.whereType<CardProgress>().toList();
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

  // ── ReviewLog CRUD ──

  Future<void> saveReviewLog(ReviewLog log) async {
    await _reviewLogBox.put(log.id, log);
  }

  List<ReviewLog> getAllReviewLogs() {
    return _reviewLogBox.values.whereType<ReviewLog>().toList();
  }

  List<ReviewLog> getReviewLogsForDate(DateTime date) {
    final start = DateTime.utc(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return getAllReviewLogs().where((log) {
      return log.reviewedAt.isAfter(start) && log.reviewedAt.isBefore(end);
    }).toList();
  }

  List<ReviewLog> getReviewLogsInRange(DateTime from, DateTime to) {
    return getAllReviewLogs().where((log) {
      return log.reviewedAt.isAfter(from) && log.reviewedAt.isBefore(to);
    }).toList();
  }

  List<ReviewLog> getReviewLogsForSet(String setId) {
    return getAllReviewLogs().where((log) => log.setId == setId).toList();
  }
}

import 'package:hive/hive.dart';
import 'package:quizlet_app/core/constants/app_constants.dart';
import 'package:quizlet_app/models/study_set.dart';

class LocalStorageService {
  Box get _box => Hive.box(AppConstants.hiveStudySetsBox);

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
}

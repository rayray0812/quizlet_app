import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizlet_app/models/study_set.dart';
import 'package:quizlet_app/models/card_progress.dart';
import 'package:quizlet_app/services/local_storage_service.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final studySetsProvider =
    StateNotifierProvider<StudySetsNotifier, List<StudySet>>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  return StudySetsNotifier(localStorage);
});

class StudySetsNotifier extends StateNotifier<List<StudySet>> {
  final LocalStorageService _localStorage;

  StudySetsNotifier(this._localStorage) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = _localStorage.getAllStudySets();
    await _ensureCardProgress();
    await _cleanOrphanedCardProgress();
  }

  /// Create CardProgress entries for any cards that don't have one yet.
  Future<void> _ensureCardProgress() async {
    final allProgress = {
      for (final p in _localStorage.getAllCardProgress()) p.cardId: p,
    };
    for (final set in state) {
      for (final card in set.cards) {
        if (!allProgress.containsKey(card.id)) {
          await _localStorage.saveCardProgress(CardProgress(
            cardId: card.id,
            setId: set.id,
          ));
        }
      }
    }
  }

  /// Remove CardProgress entries whose cardId no longer exists in any set.
  Future<void> _cleanOrphanedCardProgress() async {
    final validCardIds = <String>{};
    for (final set in state) {
      for (final card in set.cards) {
        validCardIds.add(card.id);
      }
    }
    final allProgress = _localStorage.getAllCardProgress();
    for (final progress in allProgress) {
      if (!validCardIds.contains(progress.cardId)) {
        await _localStorage.deleteCardProgress(progress.cardId);
      }
    }
  }

  Future<void> add(StudySet studySet) async {
    final stamped = studySet.copyWith(updatedAt: DateTime.now().toUtc());
    await _localStorage.saveStudySet(stamped);
    await _load();
  }

  Future<void> remove(String id) async {
    await _localStorage.deleteCardProgressForSet(id);
    await _localStorage.deleteStudySet(id);
    await _load();
  }

  Future<void> update(StudySet studySet) async {
    final stamped = studySet.copyWith(
      updatedAt: DateTime.now().toUtc(),
      isSynced: false,
    );
    await _localStorage.saveStudySet(stamped);
    await _load();
  }

  void refresh() {
    _load();
  }

  StudySet? getById(String id) {
    return _localStorage.getStudySet(id);
  }
}

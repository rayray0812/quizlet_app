import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/models/card_progress.dart';
import 'package:recall_app/services/local_storage_service.dart';

final LocalStorageService _localStorageSingleton = LocalStorageService();

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return _localStorageSingleton;
});

final studySetsProvider =
    StateNotifierProvider<StudySetsNotifier, List<StudySet>>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  return StudySetsNotifier(localStorage);
});

class StudySetsNotifier extends StateNotifier<List<StudySet>> {
  final LocalStorageService _localStorage;

  StudySetsNotifier(this._localStorage) : super([]) {
    _loadAndReconcile();
  }

  void _reloadFromStorage() {
    state = _sortSets(_localStorage.getAllStudySets());
  }

  Future<void> _loadAndReconcile() async {
    _reloadFromStorage();
    await _ensureCardProgress();
    await _cleanOrphanedCardProgress();
  }

  /// Create CardProgress entries for any cards that don't have one yet.
  Future<void> _ensureCardProgress() async {
    final allProgressIds = {
      for (final p in _localStorage.getAllCardProgress()) p.cardId,
    };
    final missing = <CardProgress>[];
    for (final set in state) {
      for (final card in set.cards) {
        if (!allProgressIds.contains(card.id)) {
          missing.add(CardProgress(cardId: card.id, setId: set.id));
          allProgressIds.add(card.id);
        }
      }
    }
    await _localStorage.saveCardProgressBatch(missing);
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
    final orphanedIds = <String>[];
    for (final progress in allProgress) {
      if (!validCardIds.contains(progress.cardId)) {
        orphanedIds.add(progress.cardId);
      }
    }
    await _localStorage.deleteCardProgressBatch(orphanedIds);
  }

  Future<void> add(StudySet studySet) async {
    final stamped = studySet.copyWith(updatedAt: DateTime.now().toUtc());
    await _localStorage.saveStudySet(stamped);
    await _ensureCardProgressForSet(stamped);
    state = _sortSets(<StudySet>[...state, stamped]);
  }

  Future<void> remove(String id) async {
    await _localStorage.markStudySetDeleted(id);
    await _localStorage.deleteCardProgressForSet(id);
    await _localStorage.deleteReviewLogsForSet(id);
    await _localStorage.deleteStudySet(id);
    state = state.where((set) => set.id != id).toList();
  }

  Future<void> update(StudySet studySet) async {
    final stamped = studySet.copyWith(
      updatedAt: DateTime.now().toUtc(),
      isSynced: false,
    );
    await _localStorage.saveStudySet(stamped);
    await _ensureCardProgressForSet(stamped);
    await _removeStaleProgressForSet(stamped);
    state = _sortSets(
      state
          .map((set) => set.id == stamped.id ? stamped : set)
          .toList(growable: false),
    );
  }

  void refresh() {
    _reloadFromStorage();
  }

  Future<void> togglePin(String id) async {
    final set = _localStorage.getStudySet(id);
    if (set == null) return;
    final updated = set.copyWith(isPinned: !set.isPinned);
    await _localStorage.saveStudySet(updated);
    state = _sortSets(
      state
          .map((item) => item.id == updated.id ? updated : item)
          .toList(growable: false),
    );
  }

  Future<void> updateLastStudied(String id) async {
    final set = _localStorage.getStudySet(id);
    if (set == null) return;
    final updated = set.copyWith(lastStudiedAt: DateTime.now().toUtc());
    await _localStorage.saveStudySet(updated);
    state = _sortSets(
      state
          .map((item) => item.id == updated.id ? updated : item)
          .toList(growable: false),
    );
  }

  Future<void> moveToFolder(String setId, String? folderId) async {
    final set = _localStorage.getStudySet(setId);
    if (set == null) return;
    final updated = set.copyWith(folderId: folderId);
    await _localStorage.saveStudySet(updated);
    state = _sortSets(
      state
          .map((item) => item.id == updated.id ? updated : item)
          .toList(growable: false),
    );
  }

  StudySet? getById(String id) {
    return _localStorage.getStudySet(id);
  }

  Future<void> _ensureCardProgressForSet(StudySet set) async {
    final existingIds =
        _localStorage.getCardProgressForSet(set.id).map((p) => p.cardId).toSet();
    final missing = <CardProgress>[];
    for (final card in set.cards) {
      if (!existingIds.contains(card.id)) {
        missing.add(CardProgress(cardId: card.id, setId: set.id));
        existingIds.add(card.id);
      }
    }
    await _localStorage.saveCardProgressBatch(missing);
  }

  Future<void> _removeStaleProgressForSet(StudySet set) async {
    final currentCardIds = set.cards.map((c) => c.id).toSet();
    final progresses = _localStorage.getCardProgressForSet(set.id);
    final staleIds = <String>[];
    for (final progress in progresses) {
      if (!currentCardIds.contains(progress.cardId)) {
        staleIds.add(progress.cardId);
      }
    }
    await _localStorage.deleteCardProgressBatch(staleIds);
  }

  List<StudySet> _sortSets(List<StudySet> sets) {
    final sorted = List<StudySet>.from(sets);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }
}


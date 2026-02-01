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

  void _load() {
    state = _localStorage.getAllStudySets();
    _ensureCardProgress();
  }

  /// Create CardProgress entries for any cards that don't have one yet.
  void _ensureCardProgress() {
    for (final set in state) {
      for (final card in set.cards) {
        final existing = _localStorage.getCardProgress(card.id);
        if (existing == null) {
          _localStorage.saveCardProgress(CardProgress(
            cardId: card.id,
            setId: set.id,
          ));
        }
      }
    }
  }

  Future<void> add(StudySet studySet) async {
    await _localStorage.saveStudySet(studySet);
    _load();
  }

  Future<void> remove(String id) async {
    await _localStorage.deleteStudySet(id);
    _load();
  }

  Future<void> update(StudySet studySet) async {
    await _localStorage.saveStudySet(studySet);
    _load();
  }

  void refresh() => _load();

  StudySet? getById(String id) {
    return _localStorage.getStudySet(id);
  }
}

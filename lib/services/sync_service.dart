import 'package:quizlet_app/services/local_storage_service.dart';
import 'package:quizlet_app/services/supabase_service.dart';

class SyncService {
  final LocalStorageService _localStorage;
  final SupabaseService _supabaseService;

  SyncService({
    required LocalStorageService localStorage,
    required SupabaseService supabaseService,
  })  : _localStorage = localStorage,
        _supabaseService = supabaseService;

  Future<void> syncAll() async {
    if (_supabaseService.currentUser == null) return;

    await _pushUnsynced();
    await _pullRemote();
  }

  Future<void> _pushUnsynced() async {
    final unsynced = _localStorage.getUnsyncedSets();
    for (final studySet in unsynced) {
      await _supabaseService.upsertStudySet(studySet);
      await _localStorage.markAsSynced(studySet.id);
    }
  }

  Future<void> _pullRemote() async {
    final remoteSets = await _supabaseService.fetchStudySets();
    for (final remoteSet in remoteSets) {
      final localSet = _localStorage.getStudySet(remoteSet.id);
      if (localSet == null) {
        await _localStorage.saveStudySet(remoteSet);
      }
    }
  }
}

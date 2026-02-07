import 'package:flutter/foundation.dart';
import 'package:recall_app/services/local_storage_service.dart';
import 'package:recall_app/services/supabase_service.dart';

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

    try {
      await _pushUnsynced();
    } catch (e) {
      debugPrint('SyncService push failed: $e');
    }
    try {
      await _pullDelta();
    } catch (e) {
      debugPrint('SyncService pull failed: $e');
    }
  }

  /// Push local changes that haven't been synced yet.
  Future<void> _pushUnsynced() async {
    final unsynced = _localStorage.getUnsyncedSets();
    for (final studySet in unsynced) {
      try {
        await _supabaseService.upsertStudySet(studySet);
        await _localStorage.markAsSynced(studySet.id);
      } catch (e) {
        debugPrint('Failed to sync set ${studySet.id}: $e');
      }
    }
  }

  /// Delta pull: fetch lightweight manifest, compare with local data,
  /// only download sets that are new or updated remotely.
  Future<void> _pullDelta() async {
    final manifest = await _supabaseService.fetchStudySetManifest();
    if (manifest.isEmpty) return;

    final idsToDownload = <String>[];

    for (final entry in manifest) {
      final localSet = _localStorage.getStudySet(entry.id);

      if (localSet == null) {
        // New set from another device ??need full download
        idsToDownload.add(entry.id);
      } else {
        // Compare timestamps: download if remote is newer
        final localUpdated = localSet.updatedAt ?? localSet.createdAt;
        if (entry.updatedAt.isAfter(localUpdated)) {
          idsToDownload.add(entry.id);
        }
      }
    }

    if (idsToDownload.isEmpty) return;

    final remoteSets =
        await _supabaseService.fetchStudySetsByIds(idsToDownload);
    for (final remoteSet in remoteSets) {
      await _localStorage.saveStudySet(remoteSet);
    }
  }
}


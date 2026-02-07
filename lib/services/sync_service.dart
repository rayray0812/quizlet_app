import 'package:flutter/foundation.dart';
import 'package:recall_app/models/card_progress.dart';
import 'package:recall_app/services/local_storage_service.dart';
import 'package:recall_app/services/supabase_service.dart';

class SyncService {
  final LocalStorageService _localStorage;
  final SupabaseService _supabaseService;

  SyncService({
    required LocalStorageService localStorage,
    required SupabaseService supabaseService,
  }) : _localStorage = localStorage,
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
      await _pullProgressAndLogs();
    } catch (e) {
      debugPrint('SyncService pull failed: $e');
    }
  }

  /// Push local changes that haven't been synced yet.
  Future<void> _pushUnsynced() async {
    final unsyncedSets = _localStorage.getUnsyncedSets();
    final pushedSetIds = <String>{};

    for (final studySet in unsyncedSets) {
      try {
        await _supabaseService.upsertStudySet(studySet);
        await _localStorage.markAsSynced(studySet.id);
        pushedSetIds.add(studySet.id);
      } catch (e) {
        debugPrint('Failed to sync set ${studySet.id}: $e');
      }
    }

    final unsyncedProgress = _localStorage.getUnsyncedCardProgress();
    final progressToPush = unsyncedProgress.where((p) {
      final set = _localStorage.getStudySet(p.setId);
      return set != null && (set.isSynced || pushedSetIds.contains(p.setId));
    }).toList();
    if (progressToPush.isNotEmpty) {
      try {
        await _supabaseService.upsertCardProgress(progressToPush);
        for (final progress in progressToPush) {
          await _localStorage.markCardProgressAsSynced(progress.cardId);
        }
      } catch (e) {
        debugPrint('Failed to sync card progress: $e');
      }
    }

    final unsyncedLogs = _localStorage.getUnsyncedReviewLogs();
    final logsToPush = unsyncedLogs.where((log) {
      final set = _localStorage.getStudySet(log.setId);
      return set != null && (set.isSynced || pushedSetIds.contains(log.setId));
    }).toList();
    if (logsToPush.isNotEmpty) {
      try {
        await _supabaseService.upsertReviewLogs(logsToPush);
        for (final log in logsToPush) {
          await _localStorage.markReviewLogAsSynced(log.id);
        }
      } catch (e) {
        debugPrint('Failed to sync review logs: $e');
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
        // New set from another device -> need full download.
        idsToDownload.add(entry.id);
      } else {
        // Compare timestamps: download if remote is newer.
        final localUpdated = localSet.updatedAt ?? localSet.createdAt;
        if (localSet.isSynced && entry.updatedAt.isAfter(localUpdated)) {
          idsToDownload.add(entry.id);
        }
      }
    }

    if (idsToDownload.isEmpty) return;

    final remoteSets = await _supabaseService.fetchStudySetsByIds(
      idsToDownload,
    );
    for (final remoteSet in remoteSets) {
      await _localStorage.saveStudySet(remoteSet.copyWith(isSynced: true));
    }
  }

  /// Pull card progress + review logs for all local sets.
  Future<void> _pullProgressAndLogs() async {
    final setIds = _localStorage.getAllStudySets().map((s) => s.id).toList();
    if (setIds.isEmpty) return;

    try {
      final remoteProgress = await _supabaseService.fetchCardProgressBySetIds(
        setIds,
      );
      for (final remote in remoteProgress) {
        final local = _localStorage.getCardProgress(remote.cardId);
        if (_shouldApplyRemoteProgress(local, remote)) {
          await _localStorage.saveCardProgress(remote.copyWith(isSynced: true));
        }
      }
    } catch (e) {
      debugPrint('Failed to pull card progress: $e');
    }

    try {
      final remoteLogs = await _supabaseService.fetchReviewLogsBySetIds(setIds);
      for (final remote in remoteLogs) {
        final existing = _localStorage.getReviewLog(remote.id);
        if (existing == null) {
          await _localStorage.saveReviewLog(remote.copyWith(isSynced: true));
        }
      }
    } catch (e) {
      debugPrint('Failed to pull review logs: $e');
    }
  }

  bool _shouldApplyRemoteProgress(CardProgress? local, CardProgress remote) {
    if (local == null) return true;
    if (!local.isSynced) return false;

    final localLast = local.lastReview;
    final remoteLast = remote.lastReview;
    if (localLast == null && remoteLast != null) return true;
    if (localLast != null && remoteLast == null) return false;
    if (localLast != null &&
        remoteLast != null &&
        remoteLast.isAfter(localLast)) {
      return true;
    }

    if (remote.reps > local.reps) return true;
    if (remote.due != null && local.due != null && remote.due != local.due) {
      return remote.due!.isAfter(local.due!);
    }
    return false;
  }
}

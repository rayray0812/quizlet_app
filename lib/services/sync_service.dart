import 'package:flutter/foundation.dart';
import 'package:recall_app/models/card_progress.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/models/sync_conflict.dart';
import 'package:recall_app/services/local_storage_service.dart';
import 'package:recall_app/services/supabase_service.dart';
import 'package:recall_app/services/sync_conflict_service.dart';

class SyncService {
  final LocalStorageService _localStorage;
  final SupabaseService _supabaseService;
  final SyncConflictService _conflictService;

  SyncService({
    required LocalStorageService localStorage,
    required SupabaseService supabaseService,
    required SyncConflictService conflictService,
  }) : _localStorage = localStorage,
       _supabaseService = supabaseService,
       _conflictService = conflictService;

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
    final deletedSetIds = _localStorage.getDeletedStudySetIds();
    await _runInBatches<String>(deletedSetIds, (setId) async {
      try {
        await _supabaseService.deleteStudySetById(setId);
        await _localStorage.clearDeletedStudySetId(setId);
        await _conflictService.removeConflict(setId);
      } catch (e) {
        debugPrint('Failed to sync deleted set $setId: $e');
      }
    });

    final unsyncedSets = _localStorage.getUnsyncedSets();
    final pushedSetIds = <String>{};
    await _runInBatches(unsyncedSets, (studySet) async {
      try {
        await _supabaseService.upsertStudySet(studySet);
        pushedSetIds.add(studySet.id);
      } catch (e) {
        debugPrint('Failed to sync set ${studySet.id}: $e');
      }
    });
    await _localStorage.markStudySetsAsSynced(pushedSetIds.toList());

    final unsyncedProgress = _localStorage.getUnsyncedCardProgress();
    final progressToPush = unsyncedProgress.where((p) {
      final set = _localStorage.getStudySet(p.setId);
      return set != null && (set.isSynced || pushedSetIds.contains(p.setId));
    }).toList();
    if (progressToPush.isNotEmpty) {
      try {
        await _supabaseService.upsertCardProgress(progressToPush);
        await _localStorage.markCardProgressAsSyncedBatch(
          progressToPush.map((p) => p.cardId).toList(),
        );
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
        await _localStorage.markReviewLogsAsSyncedBatch(
          logsToPush.map((log) => log.id).toList(),
        );
      } catch (e) {
        debugPrint('Failed to sync review logs: $e');
      }
    }
  }

  Future<void> _runInBatches<T>(
    List<T> items,
    Future<void> Function(T item) task, {
    int batchSize = 4,
  }) async {
    if (items.isEmpty) return;
    final safeBatchSize = batchSize < 1 ? 1 : batchSize;
    for (var i = 0; i < items.length; i += safeBatchSize) {
      final end = (i + safeBatchSize < items.length)
          ? i + safeBatchSize
          : items.length;
      final batch = items.sublist(i, end);
      await Future.wait(batch.map(task));
    }
  }

  /// Delta pull: fetch lightweight manifest, compare with local data,
  /// only download sets that are new or updated remotely.
  Future<void> _pullDelta() async {
    final manifest = await _supabaseService.fetchStudySetManifest();
    if (manifest.isEmpty) {
      await _applyRemoteDeletedSets(const <String>{});
      return;
    }

    final remoteIds = manifest.map((item) => item.id).toSet();
    await _applyRemoteDeletedSets(remoteIds);

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
        } else if (!localSet.isSynced &&
            entry.updatedAt.isAfter(localUpdated)) {
          await _conflictService.upsertConflict(
            SyncConflict(
              setId: entry.id,
              title: localSet.title,
              localUpdatedAt: localUpdated,
              remoteUpdatedAt: entry.updatedAt,
            ),
          );
        }
      }
    }

    if (idsToDownload.isEmpty) return;

    final remoteSets = await _supabaseService.fetchStudySetsByIds(
      idsToDownload,
    );
    for (final remoteSet in remoteSets) {
      await _localStorage.saveStudySet(remoteSet.copyWith(isSynced: true));
      await _conflictService.removeConflict(remoteSet.id);
    }
  }

  Future<void> _applyRemoteDeletedSets(Set<String> remoteIds) async {
    final localSets = _localStorage.getAllStudySets();
    for (final localSet in localSets) {
      if (!localSet.isSynced) continue;
      if (!remoteIds.contains(localSet.id)) {
        await _localStorage.deleteCardProgressForSet(localSet.id);
        await _localStorage.deleteReviewLogsForSet(localSet.id);
        await _localStorage.deleteStudySet(localSet.id);
        await _localStorage.clearDeletedStudySetId(localSet.id);
        await _conflictService.removeConflict(localSet.id);
      }
    }
  }

  List<SyncConflict> getConflicts() => _conflictService.getConflicts();

  Future<void> resolveConflictKeepLocal(String setId) async {
    final local = _localStorage.getStudySet(setId);
    if (local == null) {
      await _conflictService.removeConflict(setId);
      return;
    }

    await _localStorage.saveStudySet(
      local.copyWith(updatedAt: DateTime.now().toUtc(), isSynced: false),
    );
    await _conflictService.removeConflict(setId);
  }

  Future<void> resolveConflictKeepRemote(String setId) async {
    final remote = await _supabaseService.fetchStudySetsByIds([setId]);
    if (remote.isNotEmpty) {
      await _localStorage.saveStudySet(remote.first.copyWith(isSynced: true));
    }
    await _conflictService.removeConflict(setId);
  }

  Future<void> resolveConflictMerge(String setId) async {
    final local = _localStorage.getStudySet(setId);
    final remote = await _supabaseService.fetchStudySetsByIds([setId]);
    if (local == null || remote.isEmpty) {
      await _conflictService.removeConflict(setId);
      return;
    }

    final remoteSet = remote.first;
    final localUpdatedAt = local.updatedAt ?? local.createdAt;
    final remoteUpdatedAt = remoteSet.updatedAt ?? remoteSet.createdAt;
    final localIsNewer = localUpdatedAt.isAfter(remoteUpdatedAt);
    final mergedCards = _mergeCards(
      local.cards,
      remoteSet.cards,
      preferLocal: localIsNewer,
    );
    final mergedSet = local.copyWith(
      title: local.title.isNotEmpty ? local.title : remoteSet.title,
      description: local.description.isNotEmpty
          ? local.description
          : remoteSet.description,
      cards: mergedCards,
      updatedAt: DateTime.now().toUtc(),
      isSynced: false,
    );

    await _localStorage.saveStudySet(mergedSet);
    await _conflictService.removeConflict(setId);
  }

  /// Merge cards from local and remote. When both sides have the same card ID,
  /// keep the version from whichever StudySet was updated more recently.
  List<Flashcard> _mergeCards(
    List<Flashcard> local,
    List<Flashcard> remote, {
    required bool preferLocal,
  }) {
    if (preferLocal) {
      // Start with remote, then overwrite with local (local wins on conflict).
      final byId = <String, Flashcard>{
        for (final card in remote) card.id: card,
      };
      for (final card in local) {
        byId[card.id] = card;
      }
      return byId.values.toList();
    } else {
      // Start with local, then overwrite with remote (remote wins on conflict).
      final byId = <String, Flashcard>{
        for (final card in local) card.id: card,
      };
      for (final card in remote) {
        byId[card.id] = card;
      }
      return byId.values.toList();
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

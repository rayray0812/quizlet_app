import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/models/sync_conflict.dart';
import 'package:recall_app/providers/auth_provider.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/services/sync_conflict_service.dart';
import 'package:recall_app/services/sync_service.dart';

final syncConflictServiceProvider = Provider<SyncConflictService>((ref) {
  return SyncConflictService();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  final supabaseService = ref.watch(supabaseServiceProvider);
  final conflictService = ref.watch(syncConflictServiceProvider);
  return SyncService(
    localStorage: localStorage,
    supabaseService: supabaseService,
    conflictService: conflictService,
  );
});

final syncProvider = FutureProvider<void>((ref) async {
  final syncService = ref.watch(syncServiceProvider);
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    await syncService.syncAll();
    ref.read(studySetsProvider.notifier).refresh();
    ref.invalidate(syncConflictsProvider);
  }
});

final syncConflictsProvider = Provider<List<SyncConflict>>((ref) {
  final service = ref.watch(syncServiceProvider);
  return service.getConflicts();
});

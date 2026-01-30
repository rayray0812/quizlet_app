import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizlet_app/providers/auth_provider.dart';
import 'package:quizlet_app/providers/study_set_provider.dart';
import 'package:quizlet_app/services/sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  final supabaseService = ref.watch(supabaseServiceProvider);
  return SyncService(
    localStorage: localStorage,
    supabaseService: supabaseService,
  );
});

final syncProvider = FutureProvider<void>((ref) async {
  final syncService = ref.watch(syncServiceProvider);
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    await syncService.syncAll();
    ref.read(studySetsProvider.notifier).refresh();
  }
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/models/folder.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/services/local_storage_service.dart';

final foldersProvider =
    StateNotifierProvider<FoldersNotifier, List<Folder>>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  return FoldersNotifier(localStorage);
});

class FoldersNotifier extends StateNotifier<List<Folder>> {
  FoldersNotifier(this._localStorage) : super([]) {
    _load();
  }

  final LocalStorageService _localStorage;

  void _load() {
    state = _localStorage.getAllFolders();
  }

  Future<void> add(Folder folder) async {
    final stamped = folder.copyWith(
      updatedAt: DateTime.now().toUtc(),
      isSynced: false,
    );
    await _localStorage.saveFolder(stamped);
    _load();
  }

  Future<void> update(Folder folder) async {
    final stamped = folder.copyWith(
      updatedAt: DateTime.now().toUtc(),
      isSynced: false,
    );
    await _localStorage.saveFolder(stamped);
    _load();
  }

  Future<void> remove(String id) async {
    await _localStorage.markFolderDeleted(id);
    await _localStorage.deleteFolder(id);
    await _localStorage.clearFolderReference(id);
    _load();
  }

  void refresh() {
    _load();
  }
}

final selectedFolderIdProvider = StateProvider<String?>((ref) => null);

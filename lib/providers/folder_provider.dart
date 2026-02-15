import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/models/folder.dart';

final foldersProvider =
    StateNotifierProvider<FoldersNotifier, List<Folder>>((ref) {
  return FoldersNotifier();
});

class FoldersNotifier extends StateNotifier<List<Folder>> {
  FoldersNotifier() : super([]) {
    _load();
  }

  Box get _box => Hive.box(AppConstants.hiveFoldersBox);

  void _load() {
    final folders = <Folder>[];
    for (int i = 0; i < _box.length; i++) {
      final value = _box.getAt(i);
      if (value is Folder) folders.add(value);
    }
    state = folders;
  }

  Future<void> add(Folder folder) async {
    await _box.put(folder.id, folder);
    _load();
  }

  Future<void> update(Folder folder) async {
    await _box.put(folder.id, folder);
    _load();
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
    _load();
  }
}

final selectedFolderIdProvider = StateProvider<String?>((ref) => null);

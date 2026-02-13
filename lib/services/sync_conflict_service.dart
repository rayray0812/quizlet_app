import 'package:hive_flutter/hive_flutter.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/models/sync_conflict.dart';

class SyncConflictService {
  Box get _box => Hive.box(AppConstants.hiveSettingsBox);

  List<SyncConflict> getConflicts() {
    final raw =
        (_box.get(
                  AppConstants.settingSyncConflictsKey,
                  defaultValue: <dynamic>[],
                )
                as List)
            .cast<dynamic>();
    return raw
        .map((e) => SyncConflict.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.remoteUpdatedAt.compareTo(a.remoteUpdatedAt));
  }

  Future<void> upsertConflict(SyncConflict conflict) async {
    final items = getConflicts();
    final index = items.indexWhere((item) => item.setId == conflict.setId);
    if (index >= 0) {
      items[index] = conflict;
    } else {
      items.add(conflict);
    }
    await _saveAll(items);
  }

  Future<void> removeConflict(String setId) async {
    final items = getConflicts()..removeWhere((item) => item.setId == setId);
    await _saveAll(items);
  }

  Future<void> clearConflicts() async {
    await _box.put(AppConstants.settingSyncConflictsKey, <dynamic>[]);
  }

  Future<void> _saveAll(List<SyncConflict> items) async {
    await _box.put(
      AppConstants.settingSyncConflictsKey,
      items.map((item) => item.toJson()).toList(),
    );
  }
}

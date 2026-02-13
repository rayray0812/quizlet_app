import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/models/sync_conflict.dart';
import 'package:recall_app/services/sync_conflict_service.dart';

void main() {
  late Directory tempDir;
  late SyncConflictService service;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('Recall-sync-conflict-');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.hiveSettingsBox);
  });

  tearDownAll(() async {
    await Hive.box(AppConstants.hiveSettingsBox).clear();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    service = SyncConflictService();
    await service.clearConflicts();
  });

  test('upsertConflict adds and updates by setId', () async {
    final now = DateTime.utc(2026, 2, 13);
    await service.upsertConflict(
      SyncConflict(
        setId: 's1',
        title: 'Set 1',
        localUpdatedAt: now,
        remoteUpdatedAt: now.add(const Duration(minutes: 1)),
      ),
    );
    await service.upsertConflict(
      SyncConflict(
        setId: 's1',
        title: 'Set 1 edited',
        localUpdatedAt: now,
        remoteUpdatedAt: now.add(const Duration(minutes: 2)),
      ),
    );

    final conflicts = service.getConflicts();
    expect(conflicts.length, 1);
    expect(conflicts.first.title, 'Set 1 edited');
  });

  test('removeConflict deletes matching record', () async {
    final now = DateTime.utc(2026, 2, 13);
    await service.upsertConflict(
      SyncConflict(
        setId: 's1',
        title: 'Set 1',
        localUpdatedAt: now,
        remoteUpdatedAt: now,
      ),
    );
    await service.removeConflict('s1');

    expect(service.getConflicts(), isEmpty);
  });
}

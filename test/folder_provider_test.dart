import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/models/adapters/card_progress_adapter.dart';
import 'package:recall_app/models/adapters/folder_adapter.dart';
import 'package:recall_app/models/adapters/review_log_adapter.dart';
import 'package:recall_app/models/adapters/study_set_adapter.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/models/folder.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/providers/folder_provider.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/services/local_storage_service.dart';

void main() {
  late Directory tempDir;
  late LocalStorageService localStorage;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('Recall-folder-provider-');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(StudySetAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CardProgressAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ReviewLogAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(FolderAdapter());
    }
    await Hive.openBox(AppConstants.hiveStudySetsBox);
    await Hive.openBox(AppConstants.hiveCardProgressBox);
    await Hive.openBox(AppConstants.hiveReviewLogsBox);
    await Hive.openBox(AppConstants.hiveSettingsBox);
    await Hive.openBox(AppConstants.hiveFoldersBox);
    localStorage = LocalStorageService();
  });

  tearDownAll(() async {
    await Hive.box(AppConstants.hiveStudySetsBox).clear();
    await Hive.box(AppConstants.hiveCardProgressBox).clear();
    await Hive.box(AppConstants.hiveReviewLogsBox).clear();
    await Hive.box(AppConstants.hiveSettingsBox).clear();
    await Hive.box(AppConstants.hiveFoldersBox).clear();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    await Hive.box(AppConstants.hiveStudySetsBox).clear();
    await Hive.box(AppConstants.hiveCardProgressBox).clear();
    await Hive.box(AppConstants.hiveReviewLogsBox).clear();
    await Hive.box(AppConstants.hiveSettingsBox).clear();
    await Hive.box(AppConstants.hiveFoldersBox).clear();
  });

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(localStorage),
      ],
    );
  }

  test('remove marks folder tombstone and clears linked study sets', () async {
    await localStorage.saveFolder(
      Folder(
        id: 'folder_1',
        name: 'Folder 1',
        createdAt: DateTime.utc(2026, 3, 7),
        isSynced: true,
      ),
    );
    await localStorage.saveStudySet(
      StudySet(
        id: 'set_1',
        title: 'Set 1',
        createdAt: DateTime.utc(2026, 3, 7),
        folderId: 'folder_1',
        isSynced: true,
        cards: const [
          Flashcard(id: 'card_1', term: 'term', definition: 'definition'),
        ],
      ),
    );

    final container = buildContainer();
    addTearDown(container.dispose);

    await container.read(foldersProvider.notifier).remove('folder_1');

    expect(localStorage.getFolder('folder_1'), isNull);
    expect(localStorage.getDeletedFolderIds(), contains('folder_1'));

    final updatedSet = localStorage.getStudySet('set_1');
    expect(updatedSet, isNotNull);
    expect(updatedSet!.folderId, isNull);
    expect(updatedSet.isSynced, isFalse);
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/models/adapters/review_log_adapter.dart';
import 'package:recall_app/models/review_log.dart';
import 'package:recall_app/services/local_storage_service.dart';

void main() {
  late Directory tempDir;
  late LocalStorageService service;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('Recall-hive-test-');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ReviewLogAdapter());
    }
    await Hive.openBox(AppConstants.hiveStudySetsBox);
    await Hive.openBox(AppConstants.hiveCardProgressBox);
    await Hive.openBox(AppConstants.hiveReviewLogsBox);
  });

  tearDownAll(() async {
    await Hive.box(AppConstants.hiveReviewLogsBox).clear();
    await Hive.box(AppConstants.hiveCardProgressBox).clear();
    await Hive.box(AppConstants.hiveStudySetsBox).clear();
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    service = LocalStorageService();
    await Hive.box(AppConstants.hiveReviewLogsBox).clear();
  });

  test('getReviewLogsForDate includes exact start-of-day boundary', () async {
    final day = DateTime.utc(2026, 2, 6);

    await service.saveReviewLog(ReviewLog(
      id: 'start',
      cardId: 'c1',
      setId: 's1',
      rating: 3,
      state: 0,
      reviewedAt: day,
    ));
    await service.saveReviewLog(ReviewLog(
      id: 'inside',
      cardId: 'c2',
      setId: 's1',
      rating: 4,
      state: 1,
      reviewedAt: day.add(const Duration(hours: 12)),
    ));
    await service.saveReviewLog(ReviewLog(
      id: 'outside',
      cardId: 'c3',
      setId: 's1',
      rating: 2,
      state: 1,
      reviewedAt: day.subtract(const Duration(seconds: 1)),
    ));

    final logs = service.getReviewLogsForDate(day);
    final ids = logs.map((e) => e.id).toSet();

    expect(ids, contains('start'));
    expect(ids, contains('inside'));
    expect(ids, isNot(contains('outside')));
  });

  test('getReviewLogsInRange includes from-boundary and excludes to-boundary',
      () async {
    final from = DateTime.utc(2026, 2, 1);
    final to = DateTime.utc(2026, 2, 2);

    await service.saveReviewLog(ReviewLog(
      id: 'from',
      cardId: 'c1',
      setId: 's1',
      rating: 3,
      state: 0,
      reviewedAt: from,
    ));
    await service.saveReviewLog(ReviewLog(
      id: 'middle',
      cardId: 'c2',
      setId: 's1',
      rating: 1,
      state: 1,
      reviewedAt: from.add(const Duration(hours: 8)),
    ));
    await service.saveReviewLog(ReviewLog(
      id: 'to',
      cardId: 'c3',
      setId: 's1',
      rating: 2,
      state: 1,
      reviewedAt: to,
    ));

    final logs = service.getReviewLogsInRange(from, to);
    final ids = logs.map((e) => e.id).toSet();

    expect(ids, contains('from'));
    expect(ids, contains('middle'));
    expect(ids, isNot(contains('to')));
  });
}


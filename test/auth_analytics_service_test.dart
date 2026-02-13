import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/services/auth_analytics_service.dart';

void main() {
  late Directory tempDir;
  late AuthAnalyticsService service;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('Recall-auth-analytics-');
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
    service = AuthAnalyticsService();
    await Hive.box(AppConstants.hiveSettingsBox).clear();
  });

  test('logAuthEvent stores and returns latest-first records', () async {
    await service.logAuthEvent(
      action: 'sign_in',
      provider: 'email',
      result: 'success',
    );
    await service.logAuthEvent(
      action: 'sign_out',
      provider: 'session',
      result: 'local',
      note: 'manual',
    );

    final events = service.getRecentEvents(limit: 10);
    expect(events.length, 2);
    expect(events.first.action, 'sign_out');
    expect(events.first.note, 'manual');
    expect(events.last.action, 'sign_in');
  });

  test('getRecentEvents respects limit', () async {
    for (var i = 0; i < 5; i++) {
      await service.logAuthEvent(
        action: 'sign_in',
        provider: 'email',
        result: 'success',
        note: 'n$i',
      );
    }

    final events = service.getRecentEvents(limit: 3);
    expect(events.length, 3);
  });
}

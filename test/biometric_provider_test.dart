import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/providers/biometric_provider.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('Recall-biometric-test-');
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

  tearDown(() async {
    await Hive.box(AppConstants.hiveSettingsBox).clear();
  });

  test('loads biometric quick unlock setting from Hive', () async {
    await Hive.box(
      AppConstants.hiveSettingsBox,
    ).put(AppConstants.settingBiometricQuickUnlockKey, true);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final enabled = container.read(biometricQuickUnlockProvider);
    expect(enabled, isTrue);
  });

  test('setEnabled persists biometric quick unlock setting', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(biometricQuickUnlockProvider.notifier)
        .setEnabled(true);

    expect(container.read(biometricQuickUnlockProvider), isTrue);
    expect(
      Hive.box(
        AppConstants.hiveSettingsBox,
      ).get(AppConstants.settingBiometricQuickUnlockKey, defaultValue: false),
      isTrue,
    );
  });
}

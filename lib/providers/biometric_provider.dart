import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/services/biometric_service.dart';

class BiometricQuickUnlockNotifier extends StateNotifier<bool> {
  BiometricQuickUnlockNotifier() : super(false) {
    _load();
  }

  void _load() {
    final box = Hive.box(AppConstants.hiveSettingsBox);
    state =
        box.get(
              AppConstants.settingBiometricQuickUnlockKey,
              defaultValue: false,
            )
            as bool;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final box = Hive.box(AppConstants.hiveSettingsBox);
    await box.put(AppConstants.settingBiometricQuickUnlockKey, enabled);
  }
}

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final biometricQuickUnlockProvider =
    StateNotifierProvider<BiometricQuickUnlockNotifier, bool>(
      (ref) => BiometricQuickUnlockNotifier(),
    );

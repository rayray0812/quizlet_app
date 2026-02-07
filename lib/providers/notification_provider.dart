import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/services/notification_service.dart';

const _boxName = 'settings';
const _notificationEnabledKey = 'notification_enabled';

class NotificationNotifier extends StateNotifier<bool> {
  NotificationNotifier() : super(false) {
    _load();
  }

  void _load() {
    final box = Hive.box(_boxName);
    state = box.get(_notificationEnabledKey, defaultValue: false) as bool;
  }

  Future<void> toggle(bool enabled, {required String title, required String body}) async {
    state = enabled;
    final box = Hive.box(_boxName);
    await box.put(_notificationEnabledKey, enabled);

    if (enabled) {
      await NotificationService.requestPermission();
      await NotificationService.scheduleDailyReminder(
        hour: AppConstants.defaultNotificationHour,
        minute: AppConstants.defaultNotificationMinute,
        title: title,
        body: body,
      );
    } else {
      await NotificationService.cancelAll();
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, bool>(
  (ref) => NotificationNotifier(),
);

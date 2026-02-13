class AppConstants {
  static const String appName = '拾憶';
  static const String hiveStudySetsBox = 'study_sets';
  static const String hiveCardProgressBox = 'card_progress';
  static const String hiveReviewLogsBox = 'review_logs';
  static const String hiveSettingsBox = 'settings';

  static const String settingNotificationEnabledKey = 'notification_enabled';
  static const String settingBiometricQuickUnlockKey = 'biometric_quick_unlock';
  static const String settingAuthEventsKey = 'auth_events';
  static const String settingSyncConflictsKey = 'sync_conflicts';

  static const int maxCardsPerSet = 500;
  static const int defaultNewCardsPerDay = 20;
  static const String notificationChannelId = 'recall_daily_review';
  static const int defaultNotificationHour = 20;
  static const int defaultNotificationMinute = 0;

  // Home Screen Widgets
  static const String widgetAppGroupId = 'group.com.studyapp.recallapp';
  static const String widgetAndroidDailyMission = 'DailyMissionWidgetProvider';
  static const String widgetAndroidPressureBar = 'PressureBarWidgetProvider';
  static const String widgetIosDailyMission = 'DailyMissionWidget';
  static const String widgetIosPressureBar = 'PressureBarWidget';
  static const String deepLinkScheme = 'recall';
  static const int defaultDailyTarget = 20;
}

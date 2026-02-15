import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recall_app/app.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/core/constants/supabase_constants.dart';
import 'package:recall_app/core/router/app_router.dart';
import 'package:recall_app/models/adapters/study_set_adapter.dart';
import 'package:recall_app/models/adapters/flashcard_adapter.dart';
import 'package:recall_app/models/adapters/card_progress_adapter.dart';
import 'package:recall_app/models/adapters/review_log_adapter.dart';
import 'package:recall_app/models/adapters/folder_adapter.dart';
import 'package:recall_app/services/notification_service.dart';
import 'package:recall_app/services/widget_snapshot_service.dart';

/// Pending deep link URI from widget tap before router is ready.
Uri? _pendingWidgetUri;

void _handleWidgetUri(Uri? uri) {
  if (uri == null) return;
  // recall://review → /review
  if (uri.host == 'review' || uri.path == '/review' || uri.path == 'review') {
    if (!navigateFromDeepLink('/review')) {
      // Router not ready yet — store for later consumption.
      _pendingWidgetUri = uri;
    }
  }
}

/// Called once after the router is initialized to flush any pending deep link.
void consumePendingDeepLink() {
  final uri = _pendingWidgetUri;
  if (uri != null) {
    _pendingWidgetUri = null;
    _handleWidgetUri(uri);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(StudySetAdapter());
  Hive.registerAdapter(FlashcardAdapter());
  Hive.registerAdapter(CardProgressAdapter());
  Hive.registerAdapter(ReviewLogAdapter());
  Hive.registerAdapter(FolderAdapter());
  try {
    await Hive.openBox(AppConstants.hiveStudySetsBox);
    await Hive.openBox(AppConstants.hiveCardProgressBox);
    await Hive.openBox(AppConstants.hiveReviewLogsBox);
    await Hive.openBox(AppConstants.hiveFoldersBox);
    await Hive.openBox(AppConstants.hiveSettingsBox);
  } catch (e) {
    debugPrint('Hive openBox failed: $e');
  }

  // Initialize Notifications
  await NotificationService.init();

  // Initialize Home Screen Widgets
  await WidgetSnapshotService.init();

  // Handle widget deep links (mobile/desktop only).
  onRouterReady = consumePendingDeepLink;
  if (!kIsWeb) {
    HomeWidget.widgetClicked.listen(_handleWidgetUri);
    final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    _handleWidgetUri(initialUri);
  }

  // Re-schedule daily reminder if enabled (survives reboots)
  final settingsBox = Hive.box(AppConstants.hiveSettingsBox);
  if (settingsBox.get('notification_enabled', defaultValue: false) as bool) {
    await NotificationService.scheduleDailyReminder(
      hour: AppConstants.defaultNotificationHour,
      minute: AppConstants.defaultNotificationMinute,
      title: '\u8A72\u4F86\u8907\u7FD2\u4E86\uFF01',
      body: '\u4F60\u6709\u5F85\u8907\u7FD2\u7684\u5361\u7247\uFF0C\u6253\u958B\u62FE\u61B6\u770B\u770B\u5427',
    );
  }

  // Initialize Supabase only when credentials are provided.
  if (SupabaseConstants.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConstants.supabaseUrl,
        anonKey: SupabaseConstants.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Supabase init failed (offline mode): $e');
    }
  } else {
    debugPrint(
      'Supabase not configured. Pass SUPABASE_URL and SUPABASE_ANON_KEY with --dart-define.',
    );
  }

  runApp(const ProviderScope(child: RecallApp()));
}

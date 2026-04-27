import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recall_app/app.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/constants/supabase_constants.dart';
import 'package:recall_app/core/router/app_router.dart';
import 'package:recall_app/models/adapters/study_set_adapter.dart';
import 'package:recall_app/models/adapters/flashcard_adapter.dart';
import 'package:recall_app/models/adapters/card_progress_adapter.dart';
import 'package:recall_app/models/adapters/review_log_adapter.dart';
import 'package:recall_app/models/adapters/review_session_adapter.dart';
import 'package:recall_app/models/adapters/folder_adapter.dart';
import 'package:recall_app/services/notification_service.dart';
import 'package:recall_app/services/widget_snapshot_service.dart';

/// True when Hive fell back to unencrypted storage.
bool hiveEncryptionFailed = false;

/// Provider so UI can show a warning banner when encryption is degraded.
final hiveEncryptionFailedProvider = Provider<bool>((ref) => false);

/// Pending deep link URI from widget tap before router is ready.
Uri? _pendingWidgetUri;

bool get _supportsHomeWidgetPlatform {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

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

Future<Uint8List?> _getOrCreateEncryptionKey() async {
  try {
    const secureStorage = FlutterSecureStorage();
    const keyName = 'hive_encryption_key_v1';
    final encodedKey = await secureStorage.read(key: keyName);
    if (encodedKey != null) {
      return base64Url.decode(encodedKey);
    }
    final key = Hive.generateSecureKey();
    await secureStorage.write(key: keyName, value: base64Url.encode(key));
    return Uint8List.fromList(key);
  } catch (e) {
    debugPrint('FlutterSecureStorage failed, falling back to unencrypted Hive: $e');
    return null;
  }
}

Future<void> _bootstrap() async {
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(StudySetAdapter());
  Hive.registerAdapter(FlashcardAdapter());
  Hive.registerAdapter(CardProgressAdapter());
  Hive.registerAdapter(ReviewLogAdapter());
  Hive.registerAdapter(ReviewSessionAdapter());
  Hive.registerAdapter(FolderAdapter());

  final encryptionKey = await _getOrCreateEncryptionKey();
  final HiveAesCipher? cipher =
      encryptionKey != null ? HiveAesCipher(encryptionKey) : null;

  final boxesToOpen = [
    AppConstants.hiveStudySetsBox,
    AppConstants.hiveCardProgressBox,
    AppConstants.hiveReviewLogsBox,
    AppConstants.hiveReviewSessionsBox,
    AppConstants.hiveFoldersBox,
    AppConstants.hiveSettingsBox,
  ];

  for (final boxName in boxesToOpen) {
    try {
      await Hive.openBox(boxName, encryptionCipher: cipher);
    } catch (e) {
      debugPrint('Hive openBox failed for $boxName: $e');
      try {
        // Box might exist from a previous run with different encryption state.
        await Hive.deleteBoxFromDisk(boxName);
        await Hive.openBox(boxName, encryptionCipher: cipher);
      } catch (e2) {
        debugPrint('Hive fallback also failed for $boxName: $e2');
        // Last resort: open without encryption so the app can at least start.
        hiveEncryptionFailed = true;
        await Hive.openBox(boxName);
      }
    }
  }

  // Initialize Notifications
  try {
    await NotificationService.init();
  } catch (e, st) {
    debugPrint('Notification init failed: $e');
    debugPrintStack(stackTrace: st);
  }

  // Initialize Home Screen Widgets (mobile only)
  if (_supportsHomeWidgetPlatform) {
    try {
      await WidgetSnapshotService.init();
    } catch (e, st) {
      debugPrint('WidgetSnapshot init failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  // Handle widget deep links (mobile/desktop only).
  onRouterReady = consumePendingDeepLink;
  if (_supportsHomeWidgetPlatform) {
    try {
      HomeWidget.widgetClicked.listen(_handleWidgetUri);
      final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      _handleWidgetUri(initialUri);
    } catch (e, st) {
      debugPrint('HomeWidget deep-link setup failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  // Re-schedule daily reminder if enabled (survives reboots)
  try {
    final settingsBox = Hive.box(AppConstants.hiveSettingsBox);
    final localeLangCode =
        settingsBox.get('locale_language_code', defaultValue: 'zh') as String;
    final localeCountryCode =
        settingsBox.get('locale_country_code', defaultValue: 'TW') as String;
    final reminderL10n = localeLangCode.toLowerCase() == 'en'
        ? AppLocalizationsEn(const Locale('en', 'US'))
        : AppLocalizationsZh(Locale(localeLangCode, localeCountryCode));
    if (settingsBox.get('notification_enabled', defaultValue: false) as bool) {
      await NotificationService.scheduleDailyReminder(
        hour: AppConstants.defaultNotificationHour,
        minute: AppConstants.defaultNotificationMinute,
        title: reminderL10n.reminderTitle,
        body: reminderL10n.reminderBody,
      );
    }
  } catch (e) {
    debugPrint('Notification scheduling failed: $e');
  }

  // Initialize Supabase only when credentials are provided.
  if (SupabaseConstants.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConstants.resolvedSupabaseUrl,
        anonKey: SupabaseConstants.resolvedSupabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Supabase init failed (offline mode): $e');
    }
  } else {
    debugPrint(
      'Supabase not configured. Pass SUPABASE_URL and SUPABASE_ANON_KEY with --dart-define.',
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        hiveEncryptionFailedProvider.overrideWithValue(hiveEncryptionFailed),
      ],
      child: const RecallApp(),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  if (sentryDsn.isNotEmpty && !kDebugMode) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment = kReleaseMode ? 'production' : 'profile';
        options.release = 'recall@${AppConstants.appVersion}';
        options.tracesSampleRate = 0.2;
        options.attachScreenshot = false;
        options.sendDefaultPii = false;
      },
      appRunner: _bootstrap,
    );
  } else {
    await _bootstrap();
  }
}

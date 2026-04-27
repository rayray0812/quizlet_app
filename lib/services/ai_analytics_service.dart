import 'package:hive/hive.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/services/ai_error.dart';
import 'package:recall_app/services/ai_task.dart';

/// Lightweight, append-only log of AI operation outcomes stored in Hive.
///
/// Used for debugging rate limits, tracking provider reliability, and
/// providing telemetry data for future cost-optimisation decisions.
/// Maximum [_maxRecords] events are kept; older entries are trimmed.
class AiAnalyticsService {
  static const int _maxRecords = 100;

  Box get _box => Hive.box(AppConstants.hiveSettingsBox);

  /// Log the outcome of an AI task.
  Future<void> logEvent({
    required AiTaskType taskType,
    required String provider,
    required bool success,
    required Duration elapsed,
    ScanFailureReason? failureReason,
  }) async {
    final raw =
        (_box.get(AppConstants.settingAiEventsKey, defaultValue: <dynamic>[])
                as List)
            .cast<dynamic>();
    final events = List<Map<String, dynamic>>.from(
      raw.map((e) => Map<String, dynamic>.from(e as Map)),
    );

    events.add({
      'at': DateTime.now().toUtc().toIso8601String(),
      'task': taskType.name,
      'provider': provider,
      'result': success ? 'success' : 'failed',
      'elapsed_ms': elapsed.inMilliseconds,
      if (failureReason != null) 'failure_reason': failureReason.name,
    });

    if (events.length > _maxRecords) {
      events.removeRange(0, events.length - _maxRecords);
    }

    await _box.put(AppConstants.settingAiEventsKey, events);
  }

  /// Return recent AI events (newest first), capped at [limit].
  List<Map<String, dynamic>> getRecentEvents({int limit = 20}) {
    final raw =
        (_box.get(AppConstants.settingAiEventsKey, defaultValue: <dynamic>[])
                as List)
            .cast<dynamic>();
    final events = raw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
        .reversed
        .take(limit)
        .toList();
    return events;
  }

  /// Return the count of failures for [provider] in the last [hours] hours.
  int recentFailureCount(String provider, {int hours = 1}) {
    final cutoff = DateTime.now().toUtc().subtract(Duration(hours: hours));
    final raw =
        (_box.get(AppConstants.settingAiEventsKey, defaultValue: <dynamic>[])
                as List)
            .cast<dynamic>();
    return raw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((e) {
          final at = DateTime.tryParse(e['at'] as String? ?? '');
          return at != null &&
              at.isAfter(cutoff) &&
              e['provider'] == provider &&
              e['result'] == 'failed';
        })
        .length;
  }
}

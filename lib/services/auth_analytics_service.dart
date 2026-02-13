import 'package:hive_flutter/hive_flutter.dart';
import 'package:recall_app/core/constants/app_constants.dart';

typedef AuthEventRecord = ({
  DateTime at,
  String action,
  String provider,
  String result,
  String note,
});

class AuthAnalyticsService {
  static const int _maxRecords = 200;

  Box get _box => Hive.box(AppConstants.hiveSettingsBox);

  Future<void> logAuthEvent({
    required String action,
    required String provider,
    required String result,
    String note = '',
  }) async {
    final raw =
        (_box.get(AppConstants.settingAuthEventsKey, defaultValue: <dynamic>[])
                as List)
            .cast<dynamic>();
    final events = List<Map<String, dynamic>>.from(
      raw.map((e) => Map<String, dynamic>.from(e as Map)),
    );
    events.add({
      'at': DateTime.now().toUtc().toIso8601String(),
      'action': action,
      'provider': provider,
      'result': result,
      'note': note,
    });

    if (events.length > _maxRecords) {
      events.removeRange(0, events.length - _maxRecords);
    }

    await _box.put(AppConstants.settingAuthEventsKey, events);
  }

  List<AuthEventRecord> getRecentEvents({int limit = 20}) {
    final raw =
        (_box.get(AppConstants.settingAuthEventsKey, defaultValue: <dynamic>[])
                as List)
            .cast<dynamic>();
    final events = raw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map(
          (e) => (
            at: DateTime.tryParse(e['at'] as String? ?? '') ?? DateTime.now(),
            action: e['action'] as String? ?? 'unknown',
            provider: e['provider'] as String? ?? 'unknown',
            result: e['result'] as String? ?? 'unknown',
            note: e['note'] as String? ?? '',
          ),
        )
        .toList();

    events.sort((a, b) => b.at.compareTo(a.at));
    return events.take(limit).toList();
  }
}

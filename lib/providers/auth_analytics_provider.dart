import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/services/auth_analytics_service.dart';

final authAnalyticsServiceProvider = Provider<AuthAnalyticsService>((ref) {
  return AuthAnalyticsService();
});

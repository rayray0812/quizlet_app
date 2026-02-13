import 'package:flutter/foundation.dart';

class SupabaseConstants {
  // Provide via --dart-define:
  // SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_REDIRECT_URL
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const String supabaseRedirectUrl = String.fromEnvironment(
    'SUPABASE_REDIRECT_URL',
  );
  static const String mobileRedirectUrl =
      'io.supabase.flutter://login-callback/';

  static bool get isConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  static String get authRedirectUrl {
    if (supabaseRedirectUrl.trim().isNotEmpty) return supabaseRedirectUrl;
    if (kIsWeb) return Uri.base.origin;
    return mobileRedirectUrl;
  }

  static const String studySetsTable = 'study_sets';
  static const String cardProgressTable = 'card_progress';
  static const String reviewLogsTable = 'review_logs';
  static const String adminRolesTable = 'admin_roles';
  static const String adminRoleBindingsTable = 'admin_role_bindings';
  static const String adminAuditLogsTable = 'admin_audit_logs';
  static const String adminAccountBlocksTable = 'admin_account_blocks';
  static const String adminBulkJobsTable = 'admin_bulk_jobs';
  static const String adminRiskAlertsTable = 'admin_risk_alerts';
  static const String adminImpersonationSessionsTable =
      'admin_impersonation_sessions';
  static const String adminApprovalRequestsTable = 'admin_approval_requests';
  static const String adminNotificationRoutesTable =
      'admin_notification_routes';
  static const String adminNotificationOutboxTable =
      'admin_notification_outbox';
  static const String adminImpersonationTelemetryTable =
      'admin_impersonation_telemetry';
  static const String adminComplianceExportsTable = 'admin_compliance_exports';
}

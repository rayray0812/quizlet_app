import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:recall_app/models/admin_account_summary.dart';
import 'package:recall_app/models/admin_approval_request.dart';
import 'package:recall_app/models/admin_bulk_job.dart';
import 'package:recall_app/models/admin_impersonation_session.dart';
import 'package:recall_app/providers/admin_provider.dart';
import 'package:share_plus/share_plus.dart';

class AdminManagementScreen extends ConsumerStatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  ConsumerState<AdminManagementScreen> createState() =>
      _AdminManagementScreenState();
}

class _AdminManagementScreenState extends ConsumerState<AdminManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _activeImpersonationOnly = true;
  String? _bulkJobStatus = 'pending';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref.invalidate(adminAccountsProvider(_query));
    ref.invalidate(adminAuditProvider);
    ref.invalidate(adminRiskAlertsProvider);
    ref.invalidate(adminApprovalRequestsProvider('pending'));
    ref.invalidate(
      adminImpersonationSessionsProvider(_activeImpersonationOnly),
    );
    ref.invalidate(adminBulkJobsProvider(_bulkJobStatus));
  }

  /// Wraps an admin operation with try/catch and shows error SnackBar on failure.
  Future<void> _safeAdminAction(
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    try {
      await action();
      if (!mounted) return;
      _refreshAll();
      if (successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operation failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(adminAccountsProvider(_query));
    final auditAsync = ref.watch(adminAuditProvider);
    final riskAlertsAsync = ref.watch(adminRiskAlertsProvider);
    final approvalsAsync = ref.watch(adminApprovalRequestsProvider('pending'));
    final impersonationAsync = ref.watch(
      adminImpersonationSessionsProvider(_activeImpersonationOnly),
    );
    final bulkJobsAsync = ref.watch(adminBulkJobsProvider(_bulkJobStatus));
    final adminService = ref.read(adminServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            onPressed: () => _showCreateBulkJobDialog(context),
            icon: const Icon(Icons.playlist_add_check_rounded),
            tooltip: 'Create bulk job',
          ),
          IconButton(
            onPressed: () => _showComplianceExportDialog(context),
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export compliance report',
          ),
          IconButton(
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Search by user id',
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _query = _searchController.text.trim());
                },
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
            onSubmitted: (_) =>
                setState(() => _query = _searchController.text.trim()),
          ),
          const SizedBox(height: 16),
          const Text(
            'Accounts',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 8),
          accountsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Failed to load accounts: $e'),
            data: (accounts) {
              if (accounts.isEmpty) {
                return const Text('No accounts found.');
              }
              return Column(
                children: accounts
                    .map(
                      (account) => _AdminAccountCard(
                        account: account,
                        onBlock: () => _safeAdminAction(
                          () => adminService.blockUser(
                            targetUserId: account.userId,
                            reason: 'manual_admin_action',
                          ),
                        ),
                        onUnblock: () => _safeAdminAction(
                          () => adminService.unblockUser(
                            targetUserId: account.userId,
                            reason: 'manual_admin_action',
                          ),
                        ),
                        onForceSignOut: () => _safeAdminAction(
                          () => adminService.forceSignOutAllSessions(
                            targetUserId: account.userId,
                            reason: 'manual_admin_action',
                          ),
                          successMessage: 'Sign-out job queued.',
                        ),
                        onAssignSupportAdmin: () => _safeAdminAction(
                          () => adminService.assignRole(
                            adminUserId: account.userId,
                            roleKey: 'support_admin',
                            scopeType: 'global',
                          ),
                          successMessage: 'Role assigned.',
                        ),
                        onRequestDeleteApproval: () => _safeAdminAction(
                          () => adminService.createApprovalRequest(
                            actionType: 'delete_account',
                            reason: 'manual_admin_review',
                            payload: {'target_user_id': account.userId},
                          ),
                          successMessage: 'Delete approval request created.',
                        ),
                        onRequestMfaEnforcement: () => _safeAdminAction(
                          () => adminService.requestMfaEnforcement(
                            targetUserId: account.userId,
                          ),
                          successMessage: 'MFA enforcement request created.',
                        ),
                        onStartImpersonation: () async {
                          await _showStartImpersonationDialog(
                            context,
                            targetUserId: account.userId,
                          );
                        },
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Pending Approvals',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () async {
                  try {
                    final changed = await adminService.assignApprovalOwners();
                    if (!context.mounted) return;
                    _refreshAll();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Assigned owners: $changed')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: Theme.of(context).colorScheme.error),
                    );
                  }
                },
                child: const Text('Assign Approval Owners'),
              ),
              OutlinedButton(
                onPressed: () async {
                  try {
                    final queued = await adminService.enqueueSlaEscalations();
                    if (!context.mounted) return;
                    _refreshAll();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Queued SLA escalations: $queued')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e'), backgroundColor: Theme.of(context).colorScheme.error),
                    );
                  }
                },
                child: const Text('Run SLA Escalation'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          approvalsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Failed to load approval requests: $e'),
            data: (requests) {
              if (requests.isEmpty) return const Text('No pending approvals.');
              return Column(
                children: requests
                    .take(30)
                    .map(
                      (request) => _AdminApprovalCard(
                        request: request,
                        onApprove: () => _safeAdminAction(
                          () => adminService.approveRequest(
                            requestId: request.id,
                            reason: 'approved_in_console',
                          ),
                          successMessage: 'Request #${request.id} approved and queued.',
                        ),
                        onReject: () async {
                          final rejectReason = await _showRejectReasonDialog(
                            context,
                          );
                          if (rejectReason == null || rejectReason.isEmpty) {
                            return;
                          }
                          await _safeAdminAction(
                            () => adminService.rejectRequest(
                              requestId: request.id,
                              rejectReason: rejectReason,
                            ),
                          );
                        },
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Impersonation Sessions',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ),
              Switch.adaptive(
                value: _activeImpersonationOnly,
                onChanged: (value) {
                  setState(() => _activeImpersonationOnly = value);
                  ref.invalidate(adminImpersonationSessionsProvider(value));
                },
              ),
              const Text('Active only'),
            ],
          ),
          const SizedBox(height: 8),
          impersonationAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Failed to load impersonation sessions: $e'),
            data: (sessions) {
              if (sessions.isEmpty) {
                return const Text('No impersonation sessions.');
              }
              return Column(
                children: sessions
                    .take(30)
                    .map(
                      (session) => _ImpersonationSessionCard(
                        session: session,
                        onEnd: session.status == 'active'
                            ? () => _safeAdminAction(
                                () => adminService.endImpersonationSession(
                                  sessionId: session.id,
                                  targetUserId: session.targetUserId,
                                ),
                              )
                            : null,
                        onRevoke: session.status == 'active'
                            ? () => _safeAdminAction(
                                () => adminService.revokeImpersonationSession(
                                  sessionId: session.id,
                                  targetUserId: session.targetUserId,
                                ),
                              )
                            : null,
                        onViewTelemetry: () async {
                          await _showImpersonationTelemetryDialog(
                            context,
                            sessionId: session.id,
                          );
                        },
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bulk Jobs',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ),
              DropdownButton<String?>(
                value: _bulkJobStatus,
                onChanged: (value) {
                  setState(() => _bulkJobStatus = value);
                  ref.invalidate(adminBulkJobsProvider(value));
                },
                items: const [
                  DropdownMenuItem<String?>(
                    value: 'pending',
                    child: Text('Pending'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'running',
                    child: Text('Running'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'failed',
                    child: Text('Failed'),
                  ),
                  DropdownMenuItem<String?>(value: 'done', child: Text('Done')),
                  DropdownMenuItem<String?>(value: null, child: Text('All')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          bulkJobsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Failed to load bulk jobs: $e'),
            data: (jobs) {
              if (jobs.isEmpty) return const Text('No bulk jobs.');
              return Column(
                children: jobs
                    .take(30)
                    .map(
                      (job) => _BulkJobCard(
                        job: job,
                        onRetry:
                            (job.status == 'failed' ||
                                job.status == 'cancelled')
                            ? () => _safeAdminAction(
                                () => adminService.retryBulkJob(
                                  jobId: job.id,
                                  reason: 'retry_from_console',
                                ),
                              )
                            : null,
                        onCancel:
                            (job.status == 'pending' ||
                                job.status == 'running' ||
                                job.status == 'failed')
                            ? () => _safeAdminAction(
                                () => adminService.cancelBulkJob(
                                  jobId: job.id,
                                  reason: 'cancel_from_console',
                                ),
                              )
                            : null,
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Risk Alerts',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 8),
          riskAlertsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Failed to load risk alerts: $e'),
            data: (alerts) {
              if (alerts.isEmpty) return const Text('No risk alerts.');
              return Column(
                children: alerts
                    .take(20)
                    .map(
                      (alert) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.warning_amber_rounded),
                        title: Text('${alert.riskType} (${alert.severity})'),
                        subtitle: Text(
                          'target=${alert.targetUserId}\n'
                          'status=${alert.status}\n'
                          '${alert.summary}\n'
                          '${alert.createdAt.toLocal()}',
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Admin Audit Timeline',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 8),
          auditAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Failed to load audit logs: $e'),
            data: (logs) {
              if (logs.isEmpty) return const Text('No audit logs yet.');
              return Column(
                children: logs
                    .take(30)
                    .map(
                      (entry) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.history_rounded),
                        title: Text(entry.action),
                        subtitle: Text(
                          'actor=${entry.actorUserId}\n'
                          'target=${entry.targetUserId ?? '-'}\n'
                          '${entry.reason}\n'
                          '${entry.createdAt.toLocal()}',
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showStartImpersonationDialog(
    BuildContext context, {
    required String targetUserId,
  }) async {
    final ticketController = TextEditingController();
    final reasonController = TextEditingController();
    final adminService = ref.read(adminServiceProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Start Impersonation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Target: $targetUserId'),
              const SizedBox(height: 12),
              TextField(
                controller: ticketController,
                decoration: const InputDecoration(
                  labelText: 'Ticket ID',
                  hintText: 'SUP-2026-0001',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Customer support diagnosis',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Start'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      ticketController.dispose();
      reasonController.dispose();
      return;
    }

    final ticketId = ticketController.text.trim();
    final reason = reasonController.text.trim();
    ticketController.dispose();
    reasonController.dispose();
    if (ticketId.isEmpty || reason.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket ID and reason are required.')),
      );
      return;
    }

    await adminService.startImpersonationSession(
      targetUserId: targetUserId,
      ticketId: ticketId,
      reason: reason,
    );
    if (!context.mounted) return;
    _refreshAll();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impersonation session started.')),
    );
  }

  Future<String?> _showRejectReasonDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reject Request'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reject reason',
              hintText: 'Policy or risk assessment reason',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  Future<void> _showCreateBulkJobDialog(BuildContext context) async {
    final adminService = ref.read(adminServiceProvider);
    final typeController = TextEditingController(text: 'signout_user');
    final usersController = TextEditingController();
    final summaryController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create Bulk Job'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: 'Job Type',
                  hintText: 'signout_user / enforce_mfa / delete_account',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: usersController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Target User IDs',
                  hintText: 'uuid1,uuid2,uuid3',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: summaryController,
                decoration: const InputDecoration(
                  labelText: 'Summary',
                  hintText: 'Emergency signout for risk incident',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      typeController.dispose();
      usersController.dispose();
      summaryController.dispose();
      return;
    }

    final jobType = typeController.text.trim();
    final summary = summaryController.text.trim();
    final userIds = usersController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    typeController.dispose();
    usersController.dispose();
    summaryController.dispose();

    if (jobType.isEmpty || userIds.isEmpty || summary.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Type, user IDs, and summary are required.'),
        ),
      );
      return;
    }

    await adminService.createBulkJob(
      jobType: jobType,
      payload: {'target_user_ids': userIds},
      summary: summary,
    );
    if (!context.mounted) return;
    _refreshAll();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bulk job created.')));
  }

  Future<void> _showComplianceExportDialog(BuildContext context) async {
    final adminService = ref.read(adminServiceProvider);
    final daysController = TextEditingController(text: '30');
    final params = await showDialog<(int, String)>(
      context: context,
      builder: (ctx) {
        final format = ValueNotifier<String>('json');
        return AlertDialog(
          title: const Text('Compliance Export'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: daysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Days',
                  hintText: '30',
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<String>(
                valueListenable: format,
                builder: (_, value, __) => DropdownButton<String>(
                  value: value,
                  onChanged: (next) {
                    if (next != null) format.value = next;
                  },
                  items: const [
                    DropdownMenuItem(value: 'json', child: Text('JSON')),
                    DropdownMenuItem(value: 'csv', child: Text('CSV')),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(daysController.text.trim()) ?? 30;
                Navigator.of(ctx).pop((parsed, format.value));
              },
              child: const Text('Export'),
            ),
          ],
        );
      },
    );
    daysController.dispose();
    if (params == null) return;

    final days = params.$1;
    final format = params.$2;
    final archive = await adminService.exportSignedComplianceArchive(
      days: days,
      format: format,
    );
    if (archive == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compliance export failed.')),
      );
      return;
    }

    if (!context.mounted) return;
    if (kIsWeb) {
      final contentText = utf8.decode(archive.content, allowMalformed: true);
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text('Export Ready (${archive.format.toUpperCase()})'),
            content: SizedBox(
              width: 640,
              child: SingleChildScrollView(
                child: SelectableText(
                  'file=${archive.fileName}\n'
                  'signature=${archive.signature}\n'
                  'sha256=${archive.checksumSha256}\n\n'
                  '$contentText',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: contentText));
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                },
                child: const Text('Copy Content'),
              ),
            ],
          );
        },
      );
      return;
    }

    await Share.shareXFiles(
      [
        XFile.fromData(
          archive.content,
          mimeType: archive.mimeType,
          name: archive.fileName,
        ),
      ],
      text:
          'signature=${archive.signature}\n'
          'sha256=${archive.checksumSha256}',
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Exported ${archive.fileName}')));
  }

  Future<void> _showImpersonationTelemetryDialog(
    BuildContext context, {
    required int sessionId,
  }) async {
    final adminService = ref.read(adminServiceProvider);
    final telemetry = await adminService.fetchImpersonationTelemetry(
      sessionId: sessionId,
      limit: 100,
    );
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Telemetry #$sessionId'),
          content: SizedBox(
            width: 640,
            child: telemetry.isEmpty
                ? const Text('No telemetry.')
                : ListView(
                    shrinkWrap: true,
                    children: telemetry
                        .map(
                          (event) => ListTile(
                            dense: true,
                            title: Text(event.eventType),
                            subtitle: Text(
                              'actor=${event.actorUserId}\n'
                              'target=${event.targetUserId}\n'
                              '${event.eventMessage}\n'
                              '${event.createdAt.toLocal()}',
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _AdminAccountCard extends StatelessWidget {
  final AdminAccountSummary account;
  final Future<void> Function() onBlock;
  final Future<void> Function() onUnblock;
  final Future<void> Function() onForceSignOut;
  final Future<void> Function() onAssignSupportAdmin;
  final Future<void> Function() onRequestDeleteApproval;
  final Future<void> Function() onRequestMfaEnforcement;
  final Future<void> Function() onStartImpersonation;

  const _AdminAccountCard({
    required this.account,
    required this.onBlock,
    required this.onUnblock,
    required this.onForceSignOut,
    required this.onAssignSupportAdmin,
    required this.onRequestDeleteApproval,
    required this.onRequestMfaEnforcement,
    required this.onStartImpersonation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              account.userId,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text('Study sets: ${account.studySetCount}'),
            Text('Last activity: ${account.lastActivityAt?.toLocal() ?? '-'}'),
            Text('Blocked: ${account.isBlocked ? 'Yes' : 'No'}'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!account.isBlocked)
                  OutlinedButton(
                    onPressed: () => onBlock(),
                    child: const Text('Block'),
                  ),
                if (account.isBlocked)
                  OutlinedButton(
                    onPressed: () => onUnblock(),
                    child: const Text('Unblock'),
                  ),
                OutlinedButton(
                  onPressed: () => onForceSignOut(),
                  child: const Text('Force Sign-Out'),
                ),
                ElevatedButton(
                  onPressed: () => onAssignSupportAdmin(),
                  child: const Text('Grant Support Admin'),
                ),
                OutlinedButton(
                  onPressed: () => onRequestDeleteApproval(),
                  child: const Text('Request Delete Approval'),
                ),
                OutlinedButton(
                  onPressed: () => onRequestMfaEnforcement(),
                  child: const Text('Request MFA Enforcement'),
                ),
                OutlinedButton(
                  onPressed: () => onStartImpersonation(),
                  child: const Text('Start Impersonation'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminApprovalCard extends StatelessWidget {
  final AdminApprovalRequest request;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;

  const _AdminApprovalCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final targetUserId = request.payload['target_user_id'] as String? ?? '-';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '#${request.id} ${request.actionType}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text('requested_by: ${request.requestedBy}'),
            Text('target: $targetUserId'),
            Text('reason: ${request.reason}'),
            Text('created_at: ${request.createdAt.toLocal()}'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: () => onApprove(),
                  child: const Text('Approve'),
                ),
                OutlinedButton(
                  onPressed: () => onReject(),
                  child: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpersonationSessionCard extends StatelessWidget {
  final AdminImpersonationSession session;
  final Future<void> Function()? onEnd;
  final Future<void> Function()? onRevoke;
  final Future<void> Function() onViewTelemetry;

  const _ImpersonationSessionCard({
    required this.session,
    required this.onEnd,
    required this.onRevoke,
    required this.onViewTelemetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.support_agent_rounded),
        title: Text('Session #${session.id} (${session.status})'),
        subtitle: Text(
          'actor=${session.actorUserId}\n'
          'target=${session.targetUserId}\n'
          'ticket=${session.ticketId}\n'
          'start=${session.startedAt.toLocal()}\n'
          'expires=${session.expiresAt.toLocal()}\n'
          'reason=${session.reason}',
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (session.status == 'active' && onEnd != null)
              OutlinedButton(onPressed: onEnd, child: const Text('End')),
            if (session.status == 'active' && onRevoke != null)
              OutlinedButton(onPressed: onRevoke, child: const Text('Revoke')),
            TextButton(
              onPressed: onViewTelemetry,
              child: const Text('Telemetry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkJobCard extends StatelessWidget {
  final AdminBulkJob job;
  final Future<void> Function()? onRetry;
  final Future<void> Function()? onCancel;

  const _BulkJobCard({
    required this.job,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '#${job.id} ${job.jobType} (${job.status})',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text('actor=${job.actorUserId}'),
            Text('summary=${job.summary}'),
            Text('attempts=${job.attemptCount}/${job.maxAttempts}'),
            if (job.workerId != null && job.workerId!.isNotEmpty)
              Text('worker=${job.workerId}'),
            if (job.startedAt != null)
              Text('started=${job.startedAt!.toLocal()}'),
            if (job.finishedAt != null)
              Text('finished=${job.finishedAt!.toLocal()}'),
            if (job.lastError.isNotEmpty) Text('last_error=${job.lastError}'),
            Text('created=${job.createdAt.toLocal()}'),
            Text('updated=${job.updatedAt.toLocal()}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (onRetry != null)
                  OutlinedButton(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                if (onCancel != null)
                  OutlinedButton(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

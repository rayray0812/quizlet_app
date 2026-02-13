# Admin Governance Worker Runbook

## Purpose
Run governance automations for admin controls:
- expire stale pending approvals
- expire timed-out impersonation sessions
- generate overdue approval risk alerts
- auto-assign pending approval owners
- queue and dispatch SLA escalation notifications

## Prerequisites
- Supabase migration applied:
  - `supabase/migrations/202602130006_admin_governance_automation.sql`
- Edge Function deployed:
  - path: `supabase/functions/admin-governance-worker/index.ts`
- Environment variables configured:
  - `SUPABASE_URL`
  - `SUPABASE_SERVICE_ROLE_KEY`
  - `ADMIN_GOVERNANCE_WORKER_TOKEN` (recommended)
- Notification routes seeded in DB:
  - table: `admin_notification_routes`
  - recommended row: `channel=webhook`, `destination=<incident webhook>`

## Deploy
```bash
supabase functions deploy admin-governance-worker
```

## Trigger Manually
```bash
export SUPABASE_PROJECT_URL="https://<project-ref>.supabase.co"
export ADMIN_GOVERNANCE_WORKER_TOKEN="<token>"
./scripts/run_admin_governance_worker.sh 72 24
./scripts/run_admin_governance_worker.sh 72 24 24 50
```

Arguments:
- arg1: stale approval expiry threshold in hours (default `72`)
- arg2: overdue approval alert threshold in hours (default `24`)
- arg3: default SLA hours for unowned approvals (default `24`)
- arg4: max pending notifications to dispatch this run (default `50`)

## Suggested Scheduling
- Run every hour.
- Suggested production values:
  - `staleApprovalHours=72`
  - `overdueApprovalHours=24`

## Observability
- Track function response fields:
  - `assignedApprovalOwners`
  - `expiredApprovals`
  - `expiredImpersonationSessions`
  - `createdOverdueAlerts`
  - `queuedEscalationNotifications`
  - `dispatch.sentCount` / `dispatch.failedCount`
- Alert on non-200 response, timeout, or repeated high overdue alert growth.

# Admin Bulk Worker Runbook

## Purpose
Execute queued admin jobs in `admin_bulk_jobs` by calling the `admin-bulk-worker` Edge Function.

Supported job types:
- `signout_user`
- `enforce_mfa`
- `delete_account`

## Prerequisites
- Supabase migrations applied through:
  - `supabase/migrations/202602130004_admin_bulk_job_execution_foundation.sql`
  - `supabase/migrations/202602130005_admin_bulk_job_handlers.sql`
- Edge Function deployed:
  - path: `supabase/functions/admin-bulk-worker/index.ts`
- Environment variables configured for the function:
  - `SUPABASE_URL`
  - `SUPABASE_SERVICE_ROLE_KEY`
  - `ADMIN_WORKER_TOKEN` (recommended)
  - `ADMIN_WORKER_ID` (optional)

## Deploy
```bash
supabase functions deploy admin-bulk-worker
```

## Trigger Manually
```bash
export SUPABASE_PROJECT_URL="https://<project-ref>.supabase.co"
export ADMIN_WORKER_TOKEN="<token>"
./scripts/run_admin_bulk_worker.sh 20 manual-cli-worker
```

Arguments:
- arg1: `maxJobs` (default `20`)
- arg2: `workerId` (default `manual-cli-worker`)

## Suggested Scheduling
- Run every 1-5 minutes from a secure scheduler/cron.
- Keep `maxJobs` moderate (10-50) for predictable run time.
- Alert if:
  - response has `failedCount > 0`
  - repeated `claim_failed`
  - stuck `running` jobs older than SLA.

## Failure Handling
- Failed jobs are marked `failed` by function via `admin_complete_bulk_job`.
- Admin can requeue from console (`Retry`) which sets status back to `pending`.
- Use audit timeline to trace actor, target, and execution metadata.

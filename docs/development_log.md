# Development Log

## 2026-02-15

### UI Refactor (Stitch-style, layout-level)
- Reworked core home information architecture to be closer to stitch composition:
  - hero review block
  - quick-action grid
  - task cards
  - study set section
- Refactored major screens beyond color/theme-only changes:
  - `lib/features/home/screens/home_screen.dart`
  - `lib/features/home/screens/search_screen.dart`
  - `lib/features/stats/screens/stats_screen.dart`
  - `lib/features/study/screens/srs_review_screen.dart`
- Refactored key widgets for hierarchy/interaction parity:
  - `lib/features/home/widgets/today_review_card.dart`
  - `lib/features/home/widgets/study_set_card.dart`
  - `lib/features/home/widgets/revenge_card.dart`
  - `lib/features/study/widgets/rating_buttons.dart`
- Validation status:
  - `flutter analyze` passed (full project)
  - `flutter build web` passed

### Supabase Setup & Auth Progress
- Added local runtime define workflow (non-committed secrets):
  - `dart_defines.local.json` (gitignored)
  - `dart_defines.example.json`
  - `tool/run_web_local.ps1`
- Updated `.gitignore` to exclude local define file.
- Verified Supabase project endpoint is reachable and auth settings are active:
  - `disable_signup = false`
  - `email provider = true`
  - `mailer_autoconfirm = false` (email verification required)
- Added auth UX fallback for verification-required scenarios:
  - resend signup confirmation API in `SupabaseService`
  - `Resend` actions in signup/login flow snackbars
  - files:
    - `lib/services/supabase_service.dart`
    - `lib/features/auth/screens/signup_screen.dart`
    - `lib/features/auth/screens/login_screen.dart`

### Current Blocker
- User-reported runtime error: "Supabase 沒有定義" when trying to login.
- Most likely cause: app started without `--dart-define-from-file=dart_defines.local.json` (or wrong launch command).
- Secondary expected behavior: unverified new accounts cannot password-login until email confirmation (because `mailer_autoconfirm = false`).

### Next Session First Actions
- Reproduce login path using exact command:
  - `powershell -ExecutionPolicy Bypass -File tool\\run_web_local.ps1`
- Confirm startup log does NOT print:
  - `Supabase not configured. Pass SUPABASE_URL and SUPABASE_ANON_KEY with --dart-define.`
- If issue persists, capture and inspect:
  - browser console/network for auth calls
  - exact exception stack from app login submit handler
- Decide auth policy:
  - keep email verification flow
  - or enable autoconfirm in Supabase dashboard for immediate login after signup

## 2026-02-13

### Auth & Security
- Added route guard strategy with protected-route redirect and post-login return path.
- Added OAuth cancel/failure retry UX with explicit retry actions.
- Added centralized Supabase redirect URL handling and mobile deep-link callback wiring.
- Added app lifecycle auth gate:
  - startup session validation
  - auth event-triggered sync
  - biometric quick unlock on resume
- Added Security Center MVP:
  - sign out current device
  - sign out all devices
  - account deletion flow (with re-auth support)

### Data & Sync
- Added sync conflict detection/persistence for local-vs-remote set updates.
- Added conflict resolution actions:
  - Keep Local
  - Keep Remote
  - Merge
- Added encrypted full backup import/export:
  - AES-GCM encryption
  - PBKDF2-derived key from passphrase
  - includes study sets, card progress, review logs

### Verification & Tooling
- Added auth integration tests for login/signup/google/magic-link/guest/logout.
- Added analytics storage tests and sync-conflict service tests.
- Added RLS verification script and dashboard SQL checklist docs.

### Admin Management
- Added Admin Account Management Phase 1 foundation:
  - admin schema migration
  - admin service/provider layer
  - protected `/admin` route + admin console screen
- Added Admin phase 2/3 schema foundation:
  - risk alerts
  - approval requests
  - impersonation sessions
- Added admin runtime workflows in console:
  - pending approval queue with approve/reject actions
  - MFA enforcement approval request creation and approved-job enqueue
  - support impersonation session start/end with ticket id and audit trail
- Added admin phase 3 console workflows:
  - bulk job queue list with status filtering
  - bulk job retry/cancel actions
  - compliance snapshot export (audit/approvals/impersonation/jobs) as JSON payload
- Added admin phase 3 execution migration:
  - `admin_bulk_jobs` execution columns (`attempt_count`, `max_attempts`, `last_error`, `worker_id`, timestamps)
  - RPC helpers: `admin_claim_next_bulk_job(worker)` and `admin_complete_bulk_job(job_id, success, err)`
  - schema verification script for execution migration
- Added admin phase 3 worker execution path:
  - job handler SQL functions: `admin_worker_signout_user`, `admin_worker_enforce_mfa`, `admin_worker_delete_account`
  - edge worker function: `supabase/functions/admin-bulk-worker/index.ts`
  - run tooling and runbook: `scripts/run_admin_bulk_worker.sh`, `docs/admin_bulk_worker_runbook.md`
- Added admin governance automation:
  - SQL functions for stale approval expiry, impersonation expiry, and overdue approval risk alerts
  - edge worker function: `supabase/functions/admin-governance-worker/index.ts`
  - governance run tooling and runbook
- Added GitHub Actions scheduled worker orchestration:
  - `.github/workflows/admin-workers.yml`
  - every 5 minutes for bulk worker, hourly for governance worker
  - webhook alert hook on failures
- Added admin phase 3 hardening migration:
  - approval owner/SLA columns and escalation counters
  - notification route/outbox tables for escalation delivery
  - impersonation telemetry table and revoke function
  - compliance export registry table
- Added admin compliance export worker:
  - `supabase/functions/admin-compliance-export/index.ts`
  - signed JSON/CSV export payload with checksum and signature
  - metadata persistence to `admin_compliance_exports`
- Extended governance worker:
  - auto-assign approval owners
  - queue SLA escalation notifications
  - dispatch webhook outbox messages with sent/failed status updates
- Added compliance/governance operational tooling:
  - `scripts/run_admin_compliance_export.sh`
  - `scripts/check_admin_phase3_hardening_schema.sh`
  - updated runbooks and schedule to include daily compliance export job

### Operations & Handover
- Consolidated deployment run order for admin stack:
  - apply migrations up to `202602130007_admin_sla_telemetry_and_exports.sql`
  - deploy edge workers (`admin-bulk-worker`, `admin-governance-worker`, `admin-compliance-export`)
  - configure function/action secrets and alert webhook
- Documented manual execution commands for operators:
  - `scripts/run_admin_bulk_worker.sh`
  - `scripts/run_admin_governance_worker.sh`
  - `scripts/run_admin_compliance_export.sh`
- Documented admin console usage flow:
  - approvals, impersonation control, bulk jobs, and signed compliance export

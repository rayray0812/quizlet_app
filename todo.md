# Auth System TODO

## Done
- [x] Email/password login
- [x] Email/password signup
- [x] Forgot password flow
- [x] Google/Apple OAuth button wiring
- [x] Magic Link quick sign-in (login page)
- [x] Unified auth error message mapper
- [x] Basic auth error mapper tests

## In Progress
- [ ] Verify Supabase Dashboard OAuth settings (Google/Apple provider enabled + redirect URL whitelist)
- [ ] Verify RLS policies for auth-bound tables (`study_sets`, `card_progress`, `review_logs`)
- [ ] Add auth risk alerts (new device sign-in / unusual activity)

## Next
- [ ] Add adaptive trust policy (step-up auth for sensitive actions)

## Newly Done
- [x] Route guard strategy (public vs protected routes)
- [x] Implement full route guards in `lib/core/router/app_router.dart`
- [x] Keep guest mode but block protected pages for unauthenticated users
- [x] Add post-login redirect back to intended protected route
- [x] Add OAuth cancel/failure retry UX
- [x] Centralize auth redirect URL in `SupabaseConstants` and apply to Google/Apple/Magic Link
- [x] Configure deep link redirects in app for iOS/Android callback (`io.supabase.flutter://login-callback/`)
- [x] Add session restore validation at app launch and trigger sync on auth lifecycle events
- [x] Add biometric quick unlock (settings toggle + app resume lock screen + retry/signout actions)
- [x] Add integration tests for login/signup/google/magic-link/guest/logout
- [x] Add auth event analytics logging for email/social/magic-link/sign-out flows
- [x] Add Security Center MVP in settings (local/global session sign-out actions)
- [x] Add RLS verification tooling (`scripts/check_rls_policies.sh`) and dashboard checklist (`docs/rls_verification.md`)
- [x] Add conflict-resolution UI for cross-device sync merge cases
- [x] Add encrypted local backup import/export with passphrase
- [x] Add in-app account deletion flow with re-auth confirmation
- [x] Add development log (`docs/development_log.md`)
- [x] Add full admin account management plan (`docs/admin_account_management_plan.md`)
- [x] Add admin foundation migration (`supabase/migrations/202602130002_admin_account_management.sql`)
- [x] Add admin schema check script (`scripts/check_admin_schema.sh`)
- [x] Build Admin Account Management Phase 1 (schema + admin service + admin console UI + /admin route guard)
- [x] Add Admin Phase 2/3 foundation migration (`supabase/migrations/202602130003_admin_phase2_phase3_foundation.sql`)
- [x] Add risk alert feed in Admin Console and approval-request creation action
- [x] Add admin phase2/3 schema check script (`scripts/check_admin_phase23_schema.sh`)
- [x] Build Admin Account Management Phase 2 runtime flows:
  - pending approval queue (approve/reject in console)
  - MFA enforcement request + approval-to-job queue
  - support impersonation session start/end with ticket binding
- [x] Add Admin Phase 3 console runtime tools:
  - bulk job queue panel with status filtering
  - retry/cancel bulk job controls
  - in-console compliance snapshot export (JSON copy for last N days)
- [x] Add Admin Phase 3 execution foundation migration (`supabase/migrations/202602130004_admin_bulk_job_execution_foundation.sql`)
- [x] Add admin phase3 execution schema check script (`scripts/check_admin_phase3_execution_schema.sh`)
- [x] Add Admin Phase 3 bulk job handler migration (`supabase/migrations/202602130005_admin_bulk_job_handlers.sql`)
- [x] Add Admin bulk worker Edge Function (`supabase/functions/admin-bulk-worker/index.ts`)
- [x] Add Admin bulk worker run tooling/docs (`scripts/run_admin_bulk_worker.sh`, `docs/admin_bulk_worker_runbook.md`)
- [x] Add Admin governance automation migration (`supabase/migrations/202602130006_admin_governance_automation.sql`)
- [x] Add Admin governance worker Edge Function (`supabase/functions/admin-governance-worker/index.ts`)
- [x] Add governance runner tooling/docs (`scripts/run_admin_governance_worker.sh`, `docs/admin_governance_worker_runbook.md`)
- [x] Add GitHub Actions schedule for admin workers (`.github/workflows/admin-workers.yml`)
- [x] Add Admin SLA escalation routing + owner assignment foundation (`supabase/migrations/202602130007_admin_sla_telemetry_and_exports.sql`)
- [x] Add impersonation revocation hooks + telemetry stream persistence (`admin_revoke_impersonation_session`, `admin_impersonation_telemetry`)
- [x] Add signed compliance export workflow (`supabase/functions/admin-compliance-export/index.ts`, `scripts/run_admin_compliance_export.sh`, `docs/admin_compliance_export_runbook.md`)
- [x] Add compliance export trigger in scheduled workers (`.github/workflows/admin-workers.yml`)

## Notes
- Supabase redirect URI currently set to `io.supabase.flutter://login-callback/`.
- Ensure the same callback is whitelisted in Supabase Auth URL config.

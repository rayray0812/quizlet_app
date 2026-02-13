# Admin Compliance Export Runbook

## Purpose
Generate signed compliance report files (JSON/CSV) for admin operations.

## Prerequisites
- Supabase migration applied:
  - `supabase/migrations/202602130007_admin_sla_telemetry_and_exports.sql`
- Edge Function deployed:
  - path: `supabase/functions/admin-compliance-export/index.ts`
- Environment variables configured:
  - `SUPABASE_URL`
  - `SUPABASE_SERVICE_ROLE_KEY`
  - `ADMIN_COMPLIANCE_EXPORT_TOKEN`
  - `ADMIN_COMPLIANCE_SIGNING_KEY`
  - `ADMIN_COMPLIANCE_ACTOR_USER_ID` (or pass `actorUserId` in request body)

## Deploy
```bash
supabase functions deploy admin-compliance-export
```

## Trigger Manually
```bash
export SUPABASE_PROJECT_URL="https://<project-ref>.supabase.co"
export ADMIN_COMPLIANCE_EXPORT_TOKEN="<token>"
export ADMIN_COMPLIANCE_ACTOR_USER_ID="<admin-user-uuid>"
./scripts/run_admin_compliance_export.sh json 30 /tmp
./scripts/run_admin_compliance_export.sh csv 30 /tmp
```

Arguments:
- arg1: format `json` or `csv` (default `json`)
- arg2: day window (default `30`)
- arg3: output directory (default `/tmp`)

## Output
- Worker response includes:
  - `signature` (HMAC-SHA256 hex)
  - `checksumSha256` (SHA-256 hex)
  - `fileName`
- Metadata is persisted in `admin_compliance_exports`.

## Verification
- Recompute SHA-256 checksum of the file and compare to `checksumSha256`.
- Recompute HMAC-SHA256 using `ADMIN_COMPLIANCE_SIGNING_KEY` and compare to `signature`.

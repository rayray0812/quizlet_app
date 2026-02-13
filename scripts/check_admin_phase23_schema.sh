#!/usr/bin/env bash
set -euo pipefail

MIGRATION_FILE="${1:-supabase/migrations/202602130003_admin_phase2_phase3_foundation.sql}"

if [[ ! -f "$MIGRATION_FILE" ]]; then
  echo "Admin phase2/3 schema check failed: migration file not found: $MIGRATION_FILE"
  exit 1
fi

required_tables=(
  "admin_risk_alerts"
  "admin_impersonation_sessions"
  "admin_approval_requests"
)

for table in "${required_tables[@]}"; do
  if ! rg -q "create table if not exists public\\.${table}" "$MIGRATION_FILE"; then
    echo "Admin phase2/3 schema check failed: missing table ${table}"
    exit 1
  fi
  if ! rg -q "alter table public\\.${table} enable row level security;" "$MIGRATION_FILE"; then
    echo "Admin phase2/3 schema check failed: missing RLS enable for ${table}"
    exit 1
  fi
done

echo "Admin phase2/3 schema check passed for $MIGRATION_FILE"

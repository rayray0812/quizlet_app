#!/usr/bin/env bash
set -euo pipefail

MIGRATION_FILE="${1:-supabase/migrations/202602130006_admin_governance_automation.sql}"

if [[ ! -f "$MIGRATION_FILE" ]]; then
  echo "Admin governance schema check failed: migration file not found: $MIGRATION_FILE"
  exit 1
fi

required_patterns=(
  "create or replace function public\\.admin_expire_stale_approval_requests"
  "create or replace function public\\.admin_expire_impersonation_sessions"
  "create or replace function public\\.admin_raise_overdue_approval_alerts"
  "update public\\.admin_approval_requests"
  "update public\\.admin_impersonation_sessions"
  "insert into public\\.admin_risk_alerts"
)

for pattern in "${required_patterns[@]}"; do
  if ! rg -q "$pattern" "$MIGRATION_FILE"; then
    echo "Admin governance schema check failed: missing pattern '$pattern'"
    exit 1
  fi
done

echo "Admin governance schema check passed for $MIGRATION_FILE"

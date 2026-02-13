#!/usr/bin/env bash
set -euo pipefail

MIGRATION_FILE="${1:-supabase/migrations/202602130005_admin_bulk_job_handlers.sql}"

if [[ ! -f "$MIGRATION_FILE" ]]; then
  echo "Admin phase3 handlers schema check failed: migration file not found: $MIGRATION_FILE"
  exit 1
fi

required_patterns=(
  "create or replace function public\\.admin_worker_signout_user"
  "create or replace function public\\.admin_worker_enforce_mfa"
  "create or replace function public\\.admin_worker_delete_account"
  "delete from auth\\.sessions"
  "update auth\\.users"
  "delete from auth\\.users"
)

for pattern in "${required_patterns[@]}"; do
  if ! rg -q "$pattern" "$MIGRATION_FILE"; then
    echo "Admin phase3 handlers schema check failed: missing pattern '$pattern'"
    exit 1
  fi
done

echo "Admin phase3 handlers schema check passed for $MIGRATION_FILE"

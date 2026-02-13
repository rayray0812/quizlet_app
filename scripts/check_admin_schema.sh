#!/usr/bin/env bash
set -euo pipefail

MIGRATION_FILE="${1:-supabase/migrations/202602130002_admin_account_management.sql}"

if [[ ! -f "$MIGRATION_FILE" ]]; then
  echo "Admin schema check failed: migration file not found: $MIGRATION_FILE"
  exit 1
fi

required_tables=(
  "admin_roles"
  "admin_role_bindings"
  "admin_audit_logs"
  "admin_account_blocks"
  "admin_bulk_jobs"
)

for table in "${required_tables[@]}"; do
  if ! rg -q "create table if not exists public\\.${table}" "$MIGRATION_FILE"; then
    echo "Admin schema check failed: missing table ${table}"
    exit 1
  fi
  if ! rg -q "alter table public\\.${table} enable row level security;" "$MIGRATION_FILE"; then
    echo "Admin schema check failed: missing RLS enable for ${table}"
    exit 1
  fi
done

if ! rg -q "create or replace function public\\.is_global_admin" "$MIGRATION_FILE"; then
  echo "Admin schema check failed: missing is_global_admin function"
  exit 1
fi

if ! rg -q "insert into public\\.admin_roles" "$MIGRATION_FILE"; then
  echo "Admin schema check failed: missing role seed insert"
  exit 1
fi

echo "Admin schema check passed for $MIGRATION_FILE"

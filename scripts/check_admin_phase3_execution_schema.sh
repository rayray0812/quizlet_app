#!/usr/bin/env bash
set -euo pipefail

MIGRATION_FILE="${1:-supabase/migrations/202602130004_admin_bulk_job_execution_foundation.sql}"

if [[ ! -f "$MIGRATION_FILE" ]]; then
  echo "Admin phase3 execution schema check failed: migration file not found: $MIGRATION_FILE"
  exit 1
fi

required_patterns=(
  "alter table public\\.admin_bulk_jobs"
  "add column if not exists attempt_count"
  "add column if not exists max_attempts"
  "add column if not exists last_error"
  "add column if not exists started_at"
  "add column if not exists finished_at"
  "add column if not exists worker_id"
  "create or replace function public\\.admin_claim_next_bulk_job"
  "create or replace function public\\.admin_complete_bulk_job"
)

for pattern in "${required_patterns[@]}"; do
  if ! rg -q "$pattern" "$MIGRATION_FILE"; then
    echo "Admin phase3 execution schema check failed: missing pattern '$pattern'"
    exit 1
  fi
done

echo "Admin phase3 execution schema check passed for $MIGRATION_FILE"

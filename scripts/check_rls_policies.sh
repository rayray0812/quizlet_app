#!/usr/bin/env bash
set -euo pipefail

MIGRATION_FILE="${1:-supabase/migrations/202602070001_sync_schema.sql}"

if [[ ! -f "$MIGRATION_FILE" ]]; then
  echo "RLS check failed: migration file not found: $MIGRATION_FILE"
  exit 1
fi

required_tables=("study_sets" "card_progress" "review_logs")
required_policies=("study_sets_owner_all" "card_progress_owner_all" "review_logs_owner_all")

for table in "${required_tables[@]}"; do
  if ! rg -q "alter table public\\.${table} enable row level security;" "$MIGRATION_FILE"; then
    echo "RLS check failed: missing RLS enable statement for table: ${table}"
    exit 1
  fi
done

for policy in "${required_policies[@]}"; do
  if ! rg -q "create policy \"${policy}\"" "$MIGRATION_FILE"; then
    echo "RLS check failed: missing policy: ${policy}"
    exit 1
  fi
done

if ! rg -q "using \\(auth.uid\\(\\) = user_id\\)" "$MIGRATION_FILE"; then
  echo "RLS check failed: missing owner guard in USING clause"
  exit 1
fi

if ! rg -q "with check \\(auth.uid\\(\\) = user_id\\)" "$MIGRATION_FILE"; then
  echo "RLS check failed: missing owner guard in WITH CHECK clause"
  exit 1
fi

echo "RLS check passed for $MIGRATION_FILE"

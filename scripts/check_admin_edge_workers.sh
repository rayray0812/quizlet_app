#!/usr/bin/env bash
set -euo pipefail

required_files=(
  "supabase/functions/admin-bulk-worker/index.ts"
  "supabase/functions/admin-governance-worker/index.ts"
  "supabase/functions/admin-compliance-export/index.ts"
  ".github/workflows/admin-workers.yml"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "Admin edge worker check failed: missing file $file"
    exit 1
  fi
done

if ! rg -q "admin-compliance-export" ".github/workflows/admin-workers.yml"; then
  echo "Admin edge worker check failed: workflow missing compliance export job"
  exit 1
fi

if ! rg -q "admin_enqueue_sla_escalation_notifications" "supabase/functions/admin-governance-worker/index.ts"; then
  echo "Admin edge worker check failed: governance worker missing SLA escalation call"
  exit 1
fi

echo "Admin edge worker check passed"

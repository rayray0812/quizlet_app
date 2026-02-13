#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${SUPABASE_PROJECT_URL:-}" ]]; then
  echo "Missing SUPABASE_PROJECT_URL"
  exit 1
fi

if [[ -z "${ADMIN_WORKER_TOKEN:-}" ]]; then
  echo "Missing ADMIN_WORKER_TOKEN"
  exit 1
fi

MAX_JOBS="${1:-20}"
WORKER_ID="${2:-manual-cli-worker}"

curl -sS -X POST \
  "${SUPABASE_PROJECT_URL}/functions/v1/admin-bulk-worker" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ADMIN_WORKER_TOKEN}" \
  -d "{\"maxJobs\": ${MAX_JOBS}, \"workerId\": \"${WORKER_ID}\"}"

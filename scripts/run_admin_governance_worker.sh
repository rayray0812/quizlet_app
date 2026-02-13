#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${SUPABASE_PROJECT_URL:-}" ]]; then
  echo "Missing SUPABASE_PROJECT_URL"
  exit 1
fi

if [[ -z "${ADMIN_GOVERNANCE_WORKER_TOKEN:-}" ]]; then
  echo "Missing ADMIN_GOVERNANCE_WORKER_TOKEN"
  exit 1
fi

STALE_APPROVAL_HOURS="${1:-72}"
OVERDUE_APPROVAL_HOURS="${2:-24}"
SLA_HOURS="${3:-24}"
DISPATCH_LIMIT="${4:-50}"

curl -sS -X POST \
  "${SUPABASE_PROJECT_URL}/functions/v1/admin-governance-worker" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ADMIN_GOVERNANCE_WORKER_TOKEN}" \
  -d "{\"staleApprovalHours\": ${STALE_APPROVAL_HOURS}, \"overdueApprovalHours\": ${OVERDUE_APPROVAL_HOURS}, \"slaHours\": ${SLA_HOURS}, \"dispatchLimit\": ${DISPATCH_LIMIT}, \"escalationChannel\": \"webhook\"}"

#!/usr/bin/env bash
set -euo pipefail

MIGRATION_FILE="${1:-supabase/migrations/202602130007_admin_sla_telemetry_and_exports.sql}"

if [[ ! -f "$MIGRATION_FILE" ]]; then
  echo "Admin phase3 hardening schema check failed: migration file not found: $MIGRATION_FILE"
  exit 1
fi

required_patterns=(
  "add column if not exists owner_admin_user_id"
  "create table if not exists public\\.admin_notification_routes"
  "create table if not exists public\\.admin_notification_outbox"
  "create table if not exists public\\.admin_impersonation_telemetry"
  "create table if not exists public\\.admin_compliance_exports"
  "create or replace function public\\.admin_assign_approval_owners"
  "create or replace function public\\.admin_enqueue_sla_escalation_notifications"
  "create or replace function public\\.admin_revoke_impersonation_session"
)

for pattern in "${required_patterns[@]}"; do
  if ! rg -q "$pattern" "$MIGRATION_FILE"; then
    echo "Admin phase3 hardening schema check failed: missing pattern '$pattern'"
    exit 1
  fi
done

echo "Admin phase3 hardening schema check passed for $MIGRATION_FILE"

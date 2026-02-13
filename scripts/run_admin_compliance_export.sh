#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${SUPABASE_PROJECT_URL:-}" ]]; then
  echo "Missing SUPABASE_PROJECT_URL"
  exit 1
fi

if [[ -z "${ADMIN_COMPLIANCE_EXPORT_TOKEN:-}" ]]; then
  echo "Missing ADMIN_COMPLIANCE_EXPORT_TOKEN"
  exit 1
fi

if [[ -z "${ADMIN_COMPLIANCE_ACTOR_USER_ID:-}" ]]; then
  echo "Missing ADMIN_COMPLIANCE_ACTOR_USER_ID"
  exit 1
fi

FORMAT="${1:-json}"   # json | csv
DAYS="${2:-30}"
OUT_DIR="${3:-/tmp}"

response=$(curl -sS -X POST \
  "${SUPABASE_PROJECT_URL}/functions/v1/admin-compliance-export" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ADMIN_COMPLIANCE_EXPORT_TOKEN}" \
  -d "{\"format\":\"${FORMAT}\",\"days\":${DAYS},\"actorUserId\":\"${ADMIN_COMPLIANCE_ACTOR_USER_ID}\"}")

ok=$(echo "$response" | jq -r '.ok // false')
if [[ "$ok" != "true" ]]; then
  echo "$response"
  echo "Compliance export failed"
  exit 1
fi

file_name=$(echo "$response" | jq -r '.fileName')
content_base64=$(echo "$response" | jq -r '.contentBase64')
signature=$(echo "$response" | jq -r '.signature')
checksum=$(echo "$response" | jq -r '.checksumSha256')

mkdir -p "$OUT_DIR"
output_path="${OUT_DIR}/${file_name}"
echo "$content_base64" | base64 --decode > "$output_path"

echo "Export saved: $output_path"
echo "signature=$signature"
echo "checksum=$checksum"

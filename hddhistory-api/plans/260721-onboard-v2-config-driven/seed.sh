#!/usr/bin/env bash
#
# Seed the onboarding-config singleton with onboard_v2's content (en/vi),
# INCLUDING the per-path symptoms that onboard_v2's symptom-selection screen +
# course recommendation need. Singleton → plain PUT (no id), server partial-
# merges, so re-running is safe. Image URLs (path icons) left empty — upload in
# admin if you want custom art; otherwise onboard_v2 uses the bundled cat_* SVGs
# via the iconKey.
#
# Requires the hddhistory-api `onboarding-config` module DEPLOYED to the target with
# the new paths.items[].symptoms field (this session's backend change).
#
# Usage:
#   BASE_URL="https://api-aitutor-dev.eup.ai/api/v1" TOKEN="<admin bearer>" \
#     ./seed.sh
# BASE_URL must include the API prefix + version (.../api/v1). Requires: curl, jq.

set -euo pipefail
: "${BASE_URL:?set BASE_URL, e.g. https://api-aitutor-dev.eup.ai/api/v1}"
: "${TOKEN:?set TOKEN to an admin bearer token}"

DIR="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD_FILE="$DIR/onboarding-config-seed.json"
[ -f "$PAYLOAD_FILE" ] || { echo "Missing $PAYLOAD_FILE"; exit 1; }

echo "→ PUT $BASE_URL/onboarding-config (seeding onboard_v2 content + symptoms) ..."
curl -fsS -X PUT \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @"$PAYLOAD_FILE" \
  "$BASE_URL/onboarding-config" >/dev/null

echo "→ Verify (GET) ..."
V="$(curl -fsS -H "Authorization: Bearer $TOKEN" "$BASE_URL/onboarding-config")"
echo "$V" | jq -r '(.data // .) | {
  paths: (.paths.items | length),
  symptoms_total: ([.paths.items[].symptoms // [] | length] | add),
  age: (.age.options | length),
  notif_cta: (.notif.ctaLabel)
}'
echo "✓ Done. Expect paths=6, symptoms_total=18, age=5."

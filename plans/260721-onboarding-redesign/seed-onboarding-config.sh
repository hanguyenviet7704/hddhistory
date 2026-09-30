#!/usr/bin/env bash
#
# Seed the onboarding-config singleton with the design content (en/vi). The
# config is a singleton, so this is a plain PUT (no id). Partial-merge on the
# server, so re-running is safe and only overwrites the sections in the JSON.
# Image URLs (welcome deck, path icons) are left empty — upload them in admin.
#
# Requires the hddhistory-api `onboarding-config` module to be DEPLOYED to the target.
#
# Usage:
#   BASE_URL="https://api-aitutor-dev.eup.ai/api/v1" TOKEN="<admin bearer>" \
#     ./seed-onboarding-config.sh
# Requires: curl, jq.

set -euo pipefail
: "${BASE_URL:?set BASE_URL, e.g. https://api-aitutor-dev.eup.ai/api/v1}"
: "${TOKEN:?set TOKEN to an admin bearer token}"

DIR="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD_FILE="$DIR/onboarding-config-seed.json"
[ -f "$PAYLOAD_FILE" ] || { echo "Missing $PAYLOAD_FILE"; exit 1; }

echo "→ PUT $BASE_URL/onboarding-config (seeding onboarding config) ..."
curl -fsS -X PUT \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @"$PAYLOAD_FILE" \
  "$BASE_URL/onboarding-config" >/dev/null

echo "→ Verify (GET) ..."
V="$(curl -fsS -H "Authorization: Bearer $TOKEN" "$BASE_URL/onboarding-config")"
echo "$V" | jq -r '(.data // .) | {paths:(.paths.items|length), age:(.age.options|length), deck:(.welcome.deck|length), welcome_cta:(.welcome.ctaLabel)}'
echo "✓ Done."

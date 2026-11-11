#!/usr/bin/env bash
#
# Seed the onboarding "paths" (learning paths + symptoms) into the onboarding
# singleton document, with content IDENTICAL to the app's current hardcoded
# enums. Idempotent: it does a PARTIAL update (only `paths`), so existing
# onboarding fields (intro / motivations / age / ...) are left untouched.
#
# Goes through the REST API with a bearer token (NOT direct Mongo), so it works
# against the hosted dev/stg/prod API regardless of which Mongo it uses.
#
# Usage:
#   BASE_URL="https://api-aitutor-dev.eup.ai/api/v1" \
#   TOKEN="<admin bearer token>" \
#   ./seed-onboarding-paths.sh
#
# BASE_URL must include the API prefix + version (e.g. .../api/v1).
# Requires: curl, jq.

set -euo pipefail

: "${BASE_URL:?set BASE_URL, e.g. https://api-aitutor-dev.eup.ai/api/v1}"
: "${TOKEN:?set TOKEN to an admin bearer token}"

DIR="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD_FILE="$DIR/onboarding-paths.json"
[ -f "$PAYLOAD_FILE" ] || { echo "Missing $PAYLOAD_FILE"; exit 1; }

echo "→ Fetching current onboarding document from $BASE_URL/onboardings ..."
RESP="$(curl -fsS -H "Authorization: Bearer $TOKEN" "$BASE_URL/onboardings")"

# The onboarding singleton is returned inside BaseResponse.data (fallbacks cover
# a few response shapes just in case).
ID="$(echo "$RESP" | jq -r '.data._id // .data.id // ._id // .id // empty')"
if [ -z "$ID" ]; then
  echo "✗ Could not find the onboarding _id in the response. First 400 chars:"
  echo "$RESP" | head -c 400; echo
  exit 1
fi
echo "  onboarding _id = $ID"

# Send ONLY paths + copy — UpdateOnboardingDto is a PartialType, so this is a
# partial update and does not overwrite any other onboarding field.
BODY="$(jq -c '{paths: .paths, copy: .copy}' "$PAYLOAD_FILE")"
NPATHS="$(jq '.paths | length' "$PAYLOAD_FILE")"
NCOPY="$(jq '.copy | length' "$PAYLOAD_FILE")"
echo "→ PUT $BASE_URL/onboardings/$ID  (seeding $NPATHS paths + $NCOPY copy entries) ..."

curl -fsS -X PUT \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$BODY" \
  "$BASE_URL/onboardings/$ID" >/dev/null

# The PUT returns the Mongoose updateOne result ({acknowledged,matchedCount,...}),
# NOT the document — so re-GET to report the real persisted state.
VERIFY="$(curl -fsS -H "Authorization: Bearer $TOKEN" "$BASE_URL/onboardings")"
SP="$(echo "$VERIFY" | jq -r '(.data.paths // .paths // []) | length')"
SC="$(echo "$VERIFY" | jq -r '(.data.copy // .copy // []) | length')"
echo "✓ Done. Onboarding now has $SP paths + $SC copy entries."
echo "  Verify: GET $BASE_URL/onboardings → data.paths / data.copy"

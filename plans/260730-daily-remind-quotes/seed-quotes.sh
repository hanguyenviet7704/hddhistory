#!/usr/bin/env bash
#
# Seed the `quotes` collection so the "Daily remind" notification has something
# to rotate through.
#
# Daily remind's body is literally `{quote}` — the dispatcher fills it from a
# RANDOM quote (NotificationDispatchService.resolveContext → QuoteRepository
# .findRandom). Dev only had 2 quotes, so every day's push repeated one of two
# lines; this adds 30 more (en/vi/zh/ja/ko, the five keys ITranslation allows).
#
# There is no bulk-import endpoint for quotes — POST /courses-quotes takes one at
# a time — so this loops. Idempotent: quotes whose English line already exists on
# the target are skipped, so re-running does not duplicate.
#
# Usage:
#   BASE_URL="https://api-aitutor-dev.eup.ai/api/v1" TOKEN="<admin bearer>" \
#     ./seed-quotes.sh
#
# BASE_URL must include the API prefix + version (.../api/v1). Requires: curl, jq.
# TOKEN: copy `accessToken` from the admin tab's localStorage.

set -euo pipefail
: "${BASE_URL:?set BASE_URL, e.g. https://api-aitutor-dev.eup.ai/api/v1}"
: "${TOKEN:?set TOKEN to an admin bearer token}"

DIR="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD_FILE="$DIR/quotes-seed.json"
[ -f "$PAYLOAD_FILE" ] || { echo "Missing $PAYLOAD_FILE"; exit 1; }

echo "→ Reading existing quotes from $BASE_URL/courses-quotes ..."
EXISTING="$(curl -fsS -H "Authorization: Bearer $TOKEN" \
  "$BASE_URL/courses-quotes?page=1&take=500" \
  | jq -r '((.data // .).items // []) | map(.content.en // "") | @json')"
echo "  found $(echo "$EXISTING" | jq 'length') existing"

TOTAL="$(jq 'length' "$PAYLOAD_FILE")"
CREATED=0
SKIPPED=0

for i in $(seq 0 $((TOTAL - 1))); do
  ITEM="$(jq -c ".[$i]" "$PAYLOAD_FILE")"
  EN="$(echo "$ITEM" | jq -r '.content.en')"

  if echo "$EXISTING" | jq -e --arg en "$EN" 'index($en) != null' >/dev/null; then
    SKIPPED=$((SKIPPED + 1))
    echo "  = skip: $EN"
    continue
  fi

  curl -fsS -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$ITEM" \
    "$BASE_URL/courses-quotes" >/dev/null
  CREATED=$((CREATED + 1))
  echo "  + $EN"
done

echo "→ Verify (GET) ..."
COUNT="$(curl -fsS -H "Authorization: Bearer $TOKEN" \
  "$BASE_URL/courses-quotes?page=1&take=500" \
  | jq -r '((.data // .).items // []) | length')"

echo "✓ Created $CREATED, skipped $SKIPPED. Collection now holds $COUNT quotes."
echo "  Note: findRandom caches the pool for 5 minutes (QuoteRepository"
echo "  .POOL_TTL_MS), so a fresh quote can take up to 5 min to show up."

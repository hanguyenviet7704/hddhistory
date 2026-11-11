#!/usr/bin/env bash
#
# Import the FULL study-theme catalogue (the exact set the onboarding "Pick
# theme" screen shows offline, from the app's bundled PresetCatalog) into the
# hosted dev DB via the REST API — so the catalogue is DB/admin-managed and the
# onboarding grid + Change-Background sheet render the same set everywhere.
#
# WHY the full set: the flutter cubit uses the remote catalogue when it is
# non-empty, else falls back to the bundled PresetCatalog. So a PARTIAL import
# (e.g. colours only) would make the app show only those and DROP the image/live
# themes. Import all 13 or none.
#
# Image/live presets need R2-hosted assets, so this first uploads the 5 bundled
# bg assets (ocean/sunset/rain jpg + live-bee.mp4 + live-ambient.mp3) to R2 via
# POST /cloudflares/upload, then seeds the presets with the returned URLs.
# Idempotent: POST, and on a duplicate key it PATCHes instead.
#
# Usage:
#   BASE_URL="https://api-aitutor-dev.eup.ai/api/v1" TOKEN="<admin bearer>" \
#     ./seed-study-themes-dev.sh
# Requires: curl, jq. BG assets read from the local hddhistory-flutter repo.

set -euo pipefail
: "${BASE_URL:?set BASE_URL, e.g. https://api-aitutor-dev.eup.ai/api/v1}"
: "${TOKEN:?set TOKEN to an admin bearer token}"
BG="/Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter/assets/bg"

up() { # $1=filename -> prints the R2 url
  local f="$BG/$1" ct
  [ -f "$f" ] || { echo "missing asset: $f" >&2; exit 1; }
  case "$1" in
    *.jpg|*.jpeg) ct="image/jpeg" ;;
    *.png) ct="image/png" ;;
    *.mp4) ct="video/mp4" ;;
    *.mp3) ct="audio/mpeg" ;;
    *) ct="application/octet-stream" ;;
  esac
  # Explicit ;type — curl mis-detects .mp4/.mp3 and the R2 endpoint rejects the
  # wrong/octet mimetype with 400.
  curl -fsS -H "Authorization: Bearer $TOKEN" \
    -F "file=@$f;type=$ct" -F "folder=study-themes" \
    "$BASE_URL/cloudflares/upload" | jq -r '(.data // .).url'
}

echo "→ Uploading bg assets to R2 ..."
OCEAN=$(up ocean-photo.jpg);   echo "  ocean  = $OCEAN"
SUNSET=$(up ocean-sunset.jpg); echo "  sunset = $SUNSET"
RAIN=$(up rain-photo.jpg);     echo "  rain   = $RAIN"
VIDEO=$(up live-bee.mp4);      echo "  video  = $VIDEO"
AUDIO=$(up live-ambient.mp3);  echo "  audio  = $AUDIO"

post() { # $1=json ; POST, fall back to PATCH /:key on non-2xx (duplicate)
  local body="$1" key code
  key=$(echo "$body" | jq -r .key)
  code=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    -d "$body" "$BASE_URL/study-themes")
  if [ "${code:0:1}" != "2" ]; then
    curl -fsS -X PATCH -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
      -d "$body" "$BASE_URL/study-themes/$key" >/dev/null && echo "  ~ $key (updated)"
  else
    echo "  + $key"
  fi
}

echo "→ Seeding presets ..."
post '{"key":"default","mode":"default","category":"Default","name":"Default","gradient":["#EFEEF9","#E6EBDE"],"order":0}'
post '{"key":"lavender","mode":"color","category":"Solid & Gradient","name":"Lavender","gradient":["#EDE9FF","#D5D2F7"],"order":10}'
post '{"key":"peach","mode":"color","category":"Solid & Gradient","name":"Peach","gradient":["#FFE7D6","#FCD1C0"],"order":20}'
post '{"key":"mint","mode":"color","category":"Solid & Gradient","name":"Mint","gradient":["#DCF6EC","#C3EBDD"],"order":30}'
post '{"key":"midnight","mode":"color","category":"Solid & Gradient","name":"Midnight","gradient":["#20244A","#141733"],"isDark":true,"order":40}'
post '{"key":"rose","mode":"color","category":"Solid & Gradient","name":"Rose","gradient":["#FDE6F0","#F6C9DE"],"order":50}'
post '{"key":"sky","mode":"color","category":"Solid & Gradient","name":"Sky","gradient":["#E3F0FF","#C7DDFB"],"order":60}'
post '{"key":"sand","mode":"color","category":"Solid & Gradient","name":"Sand","gradient":["#FBF3E2","#EFE0C4"],"order":70}'
post '{"key":"plum","mode":"color","category":"Solid & Gradient","name":"Plum","gradient":["#3A2C57","#241735"],"isDark":true,"order":80}'
# image/live presets carry a dark readability `overlay` scrim (matches bundled
# PresetCatalog: images ~35% black, live ~18%) + isDark:true so text-on-bg goes
# light. overlay is #RRGGBBAA. Always send the FULL payload — a partial PATCH
# lets the DTO's `= false`/`= 0` defaults clobber isDark/order.
post "$(jq -nc --arg u "$OCEAN"  '{key:"ocean",mode:"image",category:"Nature",name:"Ocean",imageUrl:$u,isDark:true,overlay:"#00000059",order:90}')"
post "$(jq -nc --arg u "$SUNSET" '{key:"sunset",mode:"image",category:"Nature",name:"Sunset",imageUrl:$u,isDark:true,overlay:"#00000059",order:100}')"
post "$(jq -nc --arg u "$RAIN"   '{key:"rain",mode:"image",category:"Nature",name:"Rain",imageUrl:$u,isDark:true,overlay:"#00000059",order:110}')"
post "$(jq -nc --arg v "$VIDEO" --arg a "$AUDIO" --arg t "$RAIN" '{key:"live-meadow",mode:"video",category:"Live",name:"Meadow",videoUrl:$v,audioUrl:$a,thumbUrl:$t,isDark:true,overlay:"#0000002E",order:120}')"

echo "→ Verify (GET all) ..."
curl -fsS -H "Authorization: Bearer $TOKEN" "$BASE_URL/study-themes/all" \
  | jq -r 'def a: if type=="object" then (.data // .items // .) else . end; (a|length) as $n | "✓ catalogue now has \($n) presets"' 2>/dev/null \
  || echo "  (re-check GET $BASE_URL/study-themes/all manually)"

#!/usr/bin/env bash
set -u
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
STATUS=0
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"

ok() { printf "[ok] %s\n" "$1"; }
warn() { printf "[warn] %s\n" "$1"; }
fail() { printf "[fail] %s\n" "$1"; STATUS=1; }

run_help() {
  local script="$1"
  local label="$2"
  if [ ! -f "$script" ]; then
    warn "$label missing ($script)"
    return
  fi
  bash "$script" --help >/dev/null 2>&1
  local code=$?
  if [ $code -le 1 ]; then
    ok "$label (--help exit $code)"
  else
    fail "$label (--help exit $code)"
  fi
}

if [[ "$OS" == darwin* || "$OS" == "darwin" ]]; then
  PLATFORM=macos
elif [[ "$OS" == linux* || "$OS" == "linux" ]]; then
  PLATFORM=linux
else
  echo "Unsupported OS for this smoke script."
  exit 1
fi

run_help "$BASE_DIR/$PLATFORM/build/build_apk.sh" "build_apk"
run_help "$BASE_DIR/$PLATFORM/build/build_appbundle.sh" "build_appbundle"
run_help "$BASE_DIR/$PLATFORM/localization/localization.sh" "localization"
run_help "$BASE_DIR/$PLATFORM/config/flutterfire_config.sh" "flutterfire_config"
# Skip heavy tasks (codegen/clean); just check presence
if [ -f "$BASE_DIR/$PLATFORM/resource/generate_file.sh" ]; then ok "generate_file present"; else warn "generate_file missing"; STATUS=$((STATUS)) ; fi
if [ -f "$BASE_DIR/$PLATFORM/resource/reset_app.sh" ]; then ok "reset_app present"; else warn "reset_app missing"; STATUS=$((STATUS)) ; fi

if [[ "$PLATFORM" == "macos" ]] && command -v xcodebuild >/dev/null 2>&1; then
  run_help "$BASE_DIR/macos/build/build_ios.sh" "build_ios"
  run_help "$BASE_DIR/macos/build/build_ipa.sh" "build_ipa"
fi

if [ $STATUS -eq 0 ]; then
  echo "Smoke checks passed."
else
  echo "Smoke checks completed with issues." >&2
fi
exit $STATUS

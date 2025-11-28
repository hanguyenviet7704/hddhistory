#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS="$ROOT"

uname_out=$(uname | tr '[:upper:]' '[:lower:]')
case "$uname_out" in
  darwin) platform="macos" ;;
  linux)  platform="linux" ;;
  *)      platform="windows" ;; # use windows smoke.bat or WSL
esac

if [[ "$platform" == "windows" ]]; then
  echo "Detected Windows/unknown shell. Run tools/windows/smoke.bat (or use WSL and rerun this script)."
  exit 0
fi

run() {
  echo "→ $*"
  "$@"
}

dir="$TOOLS/$platform"

run "$dir/build/build_apk.sh" --help
run "$dir/build/build_appbundle.sh" --help
run "$dir/localization/localization.sh" --help
run "$dir/config/flutterfire_config.sh" --help

# macOS-only iOS helpers when Xcode is present
if [[ "$platform" == "macos" ]] && command -v xcodebuild >/dev/null 2>&1; then
  run "$dir/build/build_ios.sh" --help
  run "$dir/build/build_ipa.sh" --help
  run "$dir/distribution/distribute_ios.sh" --help
else
  if [[ "$platform" == "macos" ]]; then
    echo "Skipping iOS smoke checks (xcodebuild not found)."
  fi
fi

echo "Smoke tests finished."

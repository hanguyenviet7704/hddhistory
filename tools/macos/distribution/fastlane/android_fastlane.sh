#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../../../" && pwd)"
ANDROID_DIR="${PROJECT_ROOT}/android"
PREFERRED_BUNDLE_BIN="/opt/homebrew/opt/ruby/bin/bundle"
CI_MODE=false
DRY_RUN=false
VERBOSE=false
SHOW_HELP=false
BUNDLE_BIN=""
COMMAND_ARGS=()
REMAINING_ARGS=()
readonly ALIAS_LANES=(
  "test" "build_apk" "build_bundle" "beta" "beta_bundle"
  "deploy" "deploy_alpha" "deploy_beta" "deploy_production"
)
log() { printf "[android-fastlane] %s\n" "$1"; }
die() { printf "[android-fastlane] ERROR: %s\n" "$1" >&2; exit 1; }

print_usage() {
  cat <<'EOF'
Usage: android_fastlane.sh [global options] <command> [args...]
Purpose:
  Runs from repo root, switches to ./android, ensures bundler, then executes fastlane.
Global options:
  --dry-run      Print all commands only (do not execute)
  --verbose      Add --verbose to fastlane
  --ci           CI-friendly mode marker (for log context)
  -h, --help     Show this help
  --             Stop wrapper option parsing and pass remaining args through
Commands:
  lanes                                      List all available lanes
  lane <lane_name> [key:value ...]
      Run any lane explicitly (example: lane deploy flavor:prod track:internal)
  raw <fastlane args...>
      True passthrough. Everything after 'raw' is forwarded unchanged.
      Examples: raw lanes | raw supply init --package_name com.eup.meup | --dry-run raw supply --help
  Lane aliases (shortcut for 'lane <name>'):
    test build_apk build_bundle beta beta_bundle deploy deploy_alpha deploy_beta deploy_production
Argument style:
  Use Fastlane native key:value (examples: build_apk flavor:dev | deploy flavor:prod track:internal upload_metadata:true)
Bundler behavior:
  Prefer /opt/homebrew/opt/ruby/bin/bundle, fallback bundle in PATH.
  Then run: bundle config set path vendor/bundle -> bundle check -> auto bundle install --jobs 4 --retry 3 (if missing).
Quick examples:
  tools/macos/distribution/fastlane/android_fastlane.sh lanes --ci
  tools/macos/distribution/fastlane/android_fastlane.sh build_apk flavor:dev
  tools/macos/distribution/fastlane/android_fastlane.sh deploy --dry-run flavor:prod track:internal
  tools/macos/distribution/fastlane/android_fastlane.sh raw supply --skip_upload_aab true --skip_upload_apk true
More examples:
  tools/macos/distribution/fastlane/android_fastlane.sh deploy flavor:prod track:internal
  tools/macos/distribution/fastlane/android_fastlane.sh deploy_alpha flavor:stg
  tools/macos/distribution/fastlane/android_fastlane.sh deploy_beta flavor:stg
  tools/macos/distribution/fastlane/android_fastlane.sh deploy_production flavor:prod
  tools/macos/distribution/fastlane/android_fastlane.sh deploy flavor:prod track:internal upload_metadata:true
  tools/macos/distribution/fastlane/android_fastlane.sh deploy flavor:prod track:internal upload_images:true upload_screenshots:true
  tools/macos/distribution/fastlane/android_fastlane.sh deploy flavor:prod track:internal upload_all_metadata:true
Deploy mapping to raw:
  deploy ... == lane deploy ... == raw deploy ...
  deploy_alpha ... == raw deploy_alpha ... | deploy_beta ... == raw deploy_beta ... | deploy_production ... == raw deploy_production ...
  raw supply init --package_name com.eup.meup | --dry-run raw supply --help | -- raw --version
Execution mapping (runs inside @android/):
  <alias> ...           -> (cd android && bundle exec fastlane <alias> ...)
  lane <name> ...       -> (cd android && bundle exec fastlane <name> ...)
  raw <fastlane args>   -> (cd android && bundle exec fastlane <fastlane args>)
Bundler pre-steps inside @android/:
  bundle config set path vendor/bundle
  bundle check || bundle install --jobs 4 --retry 3
EOF
}

print_cmd() {
  local escaped=()
  local token
  for token in "$@"; do escaped+=("$(printf '%q' "$token")"); done
  log "CMD: ${escaped[*]}"
}

run_cmd() {
  print_cmd "$@"
  [[ "$DRY_RUN" == "true" ]] && return 0
  "$@"
}

parse_global_options() {
  local arg
  local command=""
  local command_seen=false
  local raw_passthrough=false
  REMAINING_ARGS=()
  while [[ $# -gt 0 ]]; do
    arg="$1"
    if [[ "$raw_passthrough" == "true" ]]; then
      REMAINING_ARGS+=("$arg")
      shift
      continue
    fi
    case "$arg" in
      --dry-run) DRY_RUN=true ;;
      --verbose) VERBOSE=true ;;
      --ci) CI_MODE=true ;;
      -h|--help) SHOW_HELP=true ;;
      --) shift; REMAINING_ARGS+=("$@"); break ;;
      *)
        if [[ "$command_seen" == "false" ]]; then
          command="$arg"
          command_seen=true
          [[ "$command" == "raw" ]] && raw_passthrough=true
        fi
        REMAINING_ARGS+=("$arg")
        ;;
    esac
    shift
  done
}

resolve_bundle_bin() {
  if [[ -x "$PREFERRED_BUNDLE_BIN" ]]; then
    BUNDLE_BIN="$PREFERRED_BUNDLE_BIN"
  elif command -v bundle >/dev/null 2>&1; then
    BUNDLE_BIN="$(command -v bundle)"
  else
    die "Bundler not found. Install Ruby/Bundler first."
  fi
}

is_alias_lane() {
  local lane="$1"
  local candidate
  for candidate in "${ALIAS_LANES[@]}"; do
    [[ "$lane" == "$candidate" ]] && return 0
  done
  return 1
}

append_from_index() {
  local index="$1"
  if [[ ${#REMAINING_ARGS[@]} -gt "$index" ]]; then
    COMMAND_ARGS+=("${REMAINING_ARGS[@]:$index}")
  fi
}

dispatch_command() {
  local command="${REMAINING_ARGS[0]}"
  case "$command" in
    lanes)
      COMMAND_ARGS=("lanes")
      append_from_index 1
      ;;
    lane)
      [[ ${#REMAINING_ARGS[@]} -ge 2 ]] || die "Missing lane name for 'lane' command."
      COMMAND_ARGS=("${REMAINING_ARGS[1]}")
      append_from_index 2
      ;;
    raw)
      [[ ${#REMAINING_ARGS[@]} -ge 2 ]] || die "Missing fastlane args for 'raw' command."
      COMMAND_ARGS=()
      append_from_index 1
      ;;
    *)
      if is_alias_lane "$command"; then
        COMMAND_ARGS=("$command")
        append_from_index 1
      else
        die "Unsupported command '$command'. Use --help to see supported commands."
      fi
      ;;
  esac
}

prepare_bundler() {
  run_cmd "$BUNDLE_BIN" config set path vendor/bundle
  if ! run_cmd "$BUNDLE_BIN" check; then
    run_cmd "$BUNDLE_BIN" install --jobs 4 --retry 3
  fi
}

main() {
  parse_global_options "$@"
  [[ "$SHOW_HELP" == "true" ]] && { print_usage; exit 0; }
  [[ -d "$ANDROID_DIR" ]] || die "Android directory not found: $ANDROID_DIR"
  [[ ${#REMAINING_ARGS[@]} -gt 0 ]] || die "Missing command. Use --help for usage."

  resolve_bundle_bin
  dispatch_command
  [[ "$CI_MODE" == "true" ]] && log "CI mode enabled."
  [[ "$DRY_RUN" == "true" ]] && log "Dry-run mode enabled."

  (
    cd "$ANDROID_DIR"
    prepare_bundler
    local fastlane_cmd=("$BUNDLE_BIN" "exec" "fastlane")
    [[ "$VERBOSE" == "true" ]] && fastlane_cmd+=("--verbose")
    fastlane_cmd+=("${COMMAND_ARGS[@]}")
    run_cmd "${fastlane_cmd[@]}"
  )
}

main "$@"

#!/bin/bash

# Tracking helper (macOS) - run app and filter tracking logs

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck source=../common/common.sh
source "${SCRIPT_DIR}/../common/common.sh" || {
    echo "Failed to load common configuration"
    exit 1
}

usage() {
    cat <<'USAGE'
Usage: run_app.sh [run|logs|devices|clear] [options]

Commands:
  run <dev|stg|prod> [--platform <android|ios>] [--device <id>] [--target <path>] [--env <path>]
      Run the app with flavor and env file.
  logs [--device <id>] [--follow] [--raw]
      Show tracking logs from adb (Android).
  devices
      List available Flutter devices.
  clear [--device <id>] [--platform <android>]
      Clear adb logcat buffer.

Options:
  --platform <p>  target platform for run (default: android)
  --device <id>   Flutter device id (optional; auto-select by platform if omitted)
  --target <path> Flutter target (default: lib/main_<flavor>.dart)
  --env <path>    Env file path (default from .info paths config)
  --follow        Stream logs (default: one-time dump)
  --raw           Do not filter by [Tracking]
  -h, --help      Show this help

Examples:
  ./run_app.sh run prod --device R58M35FT1NR
  ./run_app.sh run dev --platform ios
  ./run_app.sh logs --device R58M35FT1NR --follow
USAGE
}

ACTION="run"
FOLLOW=0
RAW=0
DEVICE=""
FLAVOR=""
TARGET=""
ENV_FILE=""
PLATFORM=""

if [[ $# -gt 0 ]]; then
    case "$1" in
        run|logs|devices|clear)
            ACTION="$1"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
    esac
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        dev|stg|prod)
            FLAVOR="$1"
            shift
            ;;
        --device)
            DEVICE="$2"
            shift 2
            ;;
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --target)
            TARGET="$2"
            shift 2
            ;;
        --env)
            ENV_FILE="$2"
            shift 2
            ;;
        --follow)
            FOLLOW=1
            shift
            ;;
        --raw)
            RAW=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

cd "$PROJECT_ROOT"

ADB_CMD="adb"
if [[ -n "$DEVICE" ]]; then
    ADB_CMD="adb -s $DEVICE"
fi

case "$ACTION" in
    devices)
        FLUTTER_CMD=$(get_flutter_command)
        $FLUTTER_CMD devices
        exit 0
        ;;
    clear)
        if [[ -n "$PLATFORM" && "$PLATFORM" != "android" ]]; then
            log_error "clear command only supports android"
            exit 1
        fi
        command -v adb >/dev/null 2>&1 || { log_error "adb not found"; exit 1; }
        $ADB_CMD logcat -c
        log_info "logcat buffer cleared"
        exit 0
        ;;
    logs)
        if [[ -n "$PLATFORM" && "$PLATFORM" != "android" ]]; then
            log_error "logs command only supports android"
            exit 1
        fi
        command -v adb >/dev/null 2>&1 || { log_error "adb not found"; exit 1; }
        FILTER="grep -E"
        if command -v rg >/dev/null 2>&1; then
            FILTER="rg"
        fi
        if [[ "$FOLLOW" -eq 1 ]]; then
            if [[ "$RAW" -eq 1 ]]; then
                $ADB_CMD logcat
            else
                $ADB_CMD logcat | $FILTER "\\[Tracking\\]"
            fi
        else
            if [[ "$RAW" -eq 1 ]]; then
                $ADB_CMD logcat -d
            else
                $ADB_CMD logcat -d | $FILTER "\\[Tracking\\]"
            fi
        fi
        exit 0
        ;;
esac

if [[ -z "$FLAVOR" ]]; then
    log_error "Missing flavor"
    usage
    exit 1
fi

validate_environment
validate_flavor "$FLAVOR"
if [[ -z "$PLATFORM" ]]; then
    PLATFORM="android"
fi
validate_platform "$PLATFORM"

if [[ -z "$ENV_FILE" ]]; then
    ENV_FILE=$(get_env_file_path "$FLAVOR")
fi

if [[ -z "$TARGET" ]]; then
    TARGET="lib/main_${FLAVOR}.dart"
    if [[ ! -f "$TARGET" ]]; then
        TARGET="lib/main.dart"
    fi
fi

if [[ ! -f "$ENV_FILE" ]]; then
    log_error "Environment file not found: $ENV_FILE"
    exit 1
fi

FLUTTER_CMD=$(get_flutter_command)
show_config_summary "$FLAVOR" "$PLATFORM"

if [[ -z "$DEVICE" ]]; then
    DEVICE=$(
        $FLUTTER_CMD devices --machine | jq -r --arg platform "$PLATFORM" '
            if $platform == "android" then
                map(select((.targetPlatform // "") | startswith("android"))) | .[0].id // empty
            elif $platform == "ios" then
                map(select((.targetPlatform // "") == "ios")) | .[0].id // empty
            else
                empty
            end
        '
    )
    if [[ -z "$DEVICE" ]]; then
        log_error "No $PLATFORM device found. Connect one or pass --device <id>."
        log_info "Run './tools/macos/build/run_app.sh devices' to list available devices."
        exit 1
    fi
    log_info "Auto-selected $PLATFORM device: $DEVICE"
fi

RUN_ARGS=(
    run
    --flavor "$FLAVOR"
    "--dart-define-from-file=$ENV_FILE"
    -t "$TARGET"
    -d "$DEVICE"
)

echo "Command: $FLUTTER_CMD ${RUN_ARGS[*]}"
$FLUTTER_CMD "${RUN_ARGS[@]}"

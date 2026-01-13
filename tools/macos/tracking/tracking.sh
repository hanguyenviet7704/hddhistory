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
Usage: tracking.sh [run|logs|devices|clear] [options]

Commands:
  run <dev|stg|prod> [--device <id>] [--target <path>] [--env <path>]
      Run the app with flavor and env file.
  logs [--device <id>] [--follow] [--raw]
      Show tracking logs from adb (Android).
  devices
      List connected adb devices.
  clear [--device <id>]
      Clear adb logcat buffer.

Options:
  --device <id>   adb device id (optional)
  --target <path> Flutter target (default: lib/main_<flavor>.dart)
  --env <path>    Env file path (default from .info paths config)
  --follow        Stream logs (default: one-time dump)
  --raw           Do not filter by [Tracking]
  -h, --help      Show this help

Examples:
  ./tracking.sh run prod --device R58M35FT1NR
  ./tracking.sh logs --device R58M35FT1NR --follow
USAGE
}

ACTION="run"
FOLLOW=0
RAW=0
DEVICE=""
FLAVOR=""
TARGET=""
ENV_FILE=""

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
        command -v adb >/dev/null 2>&1 || { log_error "adb not found"; exit 1; }
        $ADB_CMD devices
        exit 0
        ;;
    clear)
        command -v adb >/dev/null 2>&1 || { log_error "adb not found"; exit 1; }
        $ADB_CMD logcat -c
        log_info "logcat buffer cleared"
        exit 0
        ;;
    logs)
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
show_config_summary "$FLAVOR" "android"

RUN_CMD="$FLUTTER_CMD run --flavor $FLAVOR --dart-define-from-file=$ENV_FILE -t $TARGET"
if [[ -n "$DEVICE" ]]; then
    RUN_CMD="$RUN_CMD -d $DEVICE"
fi

echo "Command: $RUN_CMD"
$RUN_CMD

#!/bin/bash

# Localization orchestrator (macOS) – config-driven wrapper around localization_cli.py

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck source=../common/common.sh
source "${SCRIPT_DIR}/../common/common.sh" || {
    echo "❌ Failed to load common configuration"
    exit 1
}

# shellcheck source=./localization_common.sh
source "${SCRIPT_DIR}/localization_common.sh" || {
    echo "❌ Failed to load localization configuration"
    exit 1
}

usage() {
    cat <<'EOF'
Usage: localization.sh [pull|migrate|push|validate] [options]

Commands:
  pull                      Fetch active sheet -> YAML + records.json
  migrate [--source sheet|arb] [--apply]
                            Import from legacy sheet/ARB -> YAML (optionally push)
  push [--apply]            Push records.json to active sheet (dry-run by default)
  validate                  Validate local records.json

Examples:
  localization.sh pull
  localization.sh migrate --source sheet --apply
  localization.sh push --apply
  localization.sh validate
EOF
}

ACTION="pull"
if [[ $# -gt 0 ]]; then
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        pull|migrate|push|validate)
            ACTION="$1"
            shift
            ;;
        *)
            log_error "Unknown action: $1"
            usage
            exit 1
            ;;
    esac
fi

cd "$PROJECT_ROOT"

if ! validate_environment; then
    exit 1
fi

if ! validate_localization_config; then
    exit 1
fi

# Seed service account env vars from config if not provided
SA_PATH_CFG=$(get_localization_sa_path)
SA_ENV_NAME=$(get_localization_sa_path_env)
SA_JSON_ENV_NAME=$(get_localization_sa_json_env)
if [[ -n "$SA_PATH_CFG" && -z "${LOCALIZATION_SA_PATH:-}" ]]; then
    export LOCALIZATION_SA_PATH="$SA_PATH_CFG"
fi
if [[ -n "$SA_ENV_NAME" && -z "${!SA_ENV_NAME:-}" && -n "${LOCALIZATION_SA_PATH:-}" ]]; then
    export "$SA_ENV_NAME"="$LOCALIZATION_SA_PATH"
fi

log_info "Localization action: ${ACTION}"
show_localization_config

if ! command -v python3 >/dev/null 2>&1; then
    log_error "Python 3 is required."
    exit 1
fi

VENV_DIR="$PROJECT_ROOT/.venv_localization"
if [[ ! -d "$VENV_DIR" ]]; then
    log_warning "Creating virtual environment at $VENV_DIR"
    python3 -m venv "$VENV_DIR"
fi

log_step "Activating virtual environment..."
source "$VENV_DIR/bin/activate"

REQ_FILE="${SCRIPT_DIR}/requirements.txt"
if [[ -f "$REQ_FILE" ]]; then
    REQ_HASH=$(md5sum "$REQ_FILE" | awk '{print $1}')
    DEPS_STAMP="$VENV_DIR/.deps_hash"
    CURRENT_HASH=""
    [[ -f "$DEPS_STAMP" ]] && CURRENT_HASH=$(cat "$DEPS_STAMP")
    if [[ "$REQ_HASH" != "$CURRENT_HASH" ]]; then
        log_step "Ensuring Python dependencies..."
        pip install --upgrade pip >/dev/null
        pip install -r "$REQ_FILE" >/dev/null
        echo "$REQ_HASH" > "$DEPS_STAMP"
    else
        log_info "Dependencies already satisfied (cached)."
    fi
fi

PYTHON_CONFIG="$(create_python_config)"
log_info "Using generated config: $PYTHON_CONFIG"

cleanup() {
    rm -f "$PYTHON_CONFIG" 2>/dev/null || true
    deactivate >/dev/null 2>&1 || true
}
trap cleanup EXIT

python3 "$SCRIPT_DIR/localization_cli.py" --config "$PYTHON_CONFIG" "$ACTION" "$@"

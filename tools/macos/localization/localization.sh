#!/bin/bash

# Entry point for localization tooling (sheets <-> slang)

set -e

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

ACTION="${1:-pull}"
shift || true

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
if [[ -n "$SA_ENV_NAME" && -z "${!SA_ENV_NAME:-}" && -n "$LOCALIZATION_SA_PATH" ]]; then
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
    log_step "Ensuring Python dependencies..."
    pip install --upgrade pip >/dev/null
    pip install -r "$REQ_FILE" >/dev/null
fi

PYTHON_CONFIG="$(create_python_config)"
log_info "Using generated config: $PYTHON_CONFIG"

cleanup() {
    rm -f "$PYTHON_CONFIG" 2>/dev/null || true
    deactivate >/dev/null 2>&1 || true
}
trap cleanup EXIT

python3 "$SCRIPT_DIR/localization_cli.py" --config "$PYTHON_CONFIG" "$ACTION" "$@"

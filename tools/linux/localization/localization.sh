#!/bin/bash

# Localization orchestrator (Linux) – config-driven wrapper around localization_cli.py

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
Usage: localization.sh [pull|migrate|push|validate|slang|cache-gids] [options]

Commands (forwarded to localization_cli.py):
  pull [--sheet-gids "1 2"] Fetch active sheet -> YAML + records.json (optionally restrict gids)
  migrate [--source sheet|arb] [--apply]
                            Import from legacy sheet/ARB -> YAML (optionally push)
  push [--apply] [--sheet-gids "1 2"]
                            Push records.json/YAML to active sheet (dry-run by default; optional gids)
  validate                  Validate local records.json
  slang                     Run slang generator (flutter pub run slang)
  cache-gids [--ensure-readme]
                            Refresh tab gid cache into .info/app/localization.json (optionally create README tab)

Examples:
  localization.sh pull
  localization.sh pull --sheet-gids "324747030"   # home tab only
  localization.sh migrate --source sheet --apply
  localization.sh push --apply
  localization.sh push --sheet-gids "1167029718 324747030" --apply
  localization.sh validate
EOF
}

ACTION="pull"
APPLY_FLAG=0
if [[ $# -gt 0 ]]; then
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        pull|migrate|push|validate|slang|cache-gids)
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

# Track --apply flag for post-actions
for arg in "$@"; do
  if [[ "$arg" == "--apply" ]]; then
    APPLY_FLAG=1
  fi
done

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

# Fast path for slang generation (uses flutter command that respects fvm/puro)
if [[ "$ACTION" == "slang" ]]; then
    FLUTTER_CMD=$(get_flutter_command)
    log_step "Running slang generator..."
    set +e
    $FLUTTER_CMD pub run slang "$@"
    EXIT_CODE=$?
    set -e
    exit $EXIT_CODE
fi

if ! command -v python3 >/dev/null 2>&1; then
    log_error "Python 3 is required."
    exit 1
fi

VENV_DIR="$PROJECT_ROOT/.venv"
if [[ ! -d "$VENV_DIR" ]]; then
    log_warning "Creating virtual environment at $VENV_DIR"
    python3 -m venv "$VENV_DIR"
fi

log_step "Activating virtual environment..."
source "$VENV_DIR/bin/activate"
VENV_PYTHON="$VENV_DIR/bin/python3"

REQ_FILE="${SCRIPT_DIR}/requirements.txt"
if [[ -f "$REQ_FILE" ]]; then
    compute_requirements_hash() {
        local file_path="$1"
        if command -v md5sum >/dev/null 2>&1; then
            md5sum "$file_path" | awk '{print $1}'
            return 0
        fi
        if command -v md5 >/dev/null 2>&1; then
            md5 -q "$file_path"
            return 0
        fi
        python3 - "$file_path" <<'PY'
import hashlib
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
print(hashlib.md5(path.read_bytes()).hexdigest())
PY
    }

    python_deps_healthy() {
        "$VENV_PYTHON" - <<'PY' >/dev/null 2>&1
import importlib
import sys

modules = [
    "requests",
    "gspread",
    "google.auth",
    "google_auth_oauthlib",
    "yaml",
    "tabulate",
]
for module in modules:
    try:
        importlib.import_module(module)
    except Exception:
        sys.exit(1)
sys.exit(0)
PY
    }

    REQ_HASH=$(compute_requirements_hash "$REQ_FILE")
    DEPS_STAMP="$VENV_DIR/.deps_hash"
    CURRENT_HASH=""
    [[ -f "$DEPS_STAMP" ]] && CURRENT_HASH=$(cat "$DEPS_STAMP")

    NEEDS_INSTALL=0
    if [[ "$REQ_HASH" != "$CURRENT_HASH" ]]; then
        NEEDS_INSTALL=1
    elif ! python_deps_healthy; then
        log_warning "Python dependency cache is stale or incomplete. Reinstalling requirements..."
        NEEDS_INSTALL=1
    fi

    if [[ "$NEEDS_INSTALL" -eq 1 ]]; then
        log_step "Ensuring Python dependencies..."
        if ! "$VENV_PYTHON" -m pip --version >/dev/null 2>&1; then
            "$VENV_PYTHON" -m ensurepip --upgrade >/dev/null
        fi
        "$VENV_PYTHON" -m pip install --upgrade pip >/dev/null
        "$VENV_PYTHON" -m pip install -r "$REQ_FILE" >/dev/null
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
EXIT_CODE=$?

# Auto refresh gid cache after mutating actions
if [[ $EXIT_CODE -eq 0 && $APPLY_FLAG -eq 1 && ( "$ACTION" == "push" || "$ACTION" == "migrate" ) ]]; then
    log_step "Refreshing sheet gid cache after apply..."
    python3 "$SCRIPT_DIR/localization_cli.py" --config "$PYTHON_CONFIG" cache-gids --ensure-readme || true
fi

exit $EXIT_CODE

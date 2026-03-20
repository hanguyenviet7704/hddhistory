#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
CONFIG_FILE="${HOME}/.gitlab-runner/config.toml"
CONFIG_LOCK_DIR=""

DEFAULT_GITLAB_URL="https://gitlab.com"
DEFAULT_TAGS="macos"

GITLAB_URL="${DEFAULT_GITLAB_URL}"
PROJECT_ID=""
PROJECT_PATH=""
RUNNER_TOKEN=""
RUNNER_DESCRIPTION=""
RUNNER_TAGS="${DEFAULT_TAGS}"
RUNNER_EXECUTOR="shell"
RUN_UNTAGGED="false"
LOCKED="true"
RUNNER_PATH=""
SKIP_INSTALL="false"
SKIP_SERVICE="false"
FORCE_REGISTER="false"
CREATED_RUNNER_ID=""
STRICT="false"

usage() {
    cat <<EOF
Usage: ./${SCRIPT_NAME} [options]

Set up this macOS machine as a GitLab project runner.

Options:
  --gitlab-url <url>        GitLab base URL (default: ${DEFAULT_GITLAB_URL})
  --project-id <id>         GitLab project numeric ID
  --project-path <path>     GitLab project path, ex: eup/meup/meup-flutter
  --runner-token <token>    Existing runner auth token (glrt-...)
  --name <name>             Runner description/name
  --tags <tags>             Runner tags (comma-separated, default: ${DEFAULT_TAGS})
  --executor <executor>     Runner executor (default: shell)
  --run-untagged <bool>     Runner run_untagged when creating token via API (default: false)
  --locked <bool>           Runner locked when creating token via API (default: true)
  --runner-path <path>      PATH injected into runner config environment
  --skip-install            Skip gitlab-runner installation step
  --skip-service            Skip service restart/start step
  --strict                  Fail when service restart or verify fails
  --force-register          Force register a new runner even if name exists in local config
  -h, --help                Show this help message

Examples:
  # Auto-create project runner token via glab API and register
  ./${SCRIPT_NAME} --project-path eup/meup/meup-flutter

  # Use an existing runner token
  ./${SCRIPT_NAME} --runner-token glrt-xxxxx --name meup-macos-runner
EOF
}

log_info() {
    printf '[INFO] %s\n' "$1"
}

log_warn() {
    printf '[WARN] %s\n' "$1"
}

log_error() {
    printf '[ERROR] %s\n' "$1" >&2
}

fail() {
    log_error "$1"
    exit 1
}

validate_bool() {
    local key="$1"
    local value="$2"
    if [[ "${value}" != "true" && "${value}" != "false" ]]; then
        fail "Invalid value for ${key}: ${value} (expected: true|false)"
    fi
}

acquire_config_lock() {
    local lock_dir="${CONFIG_FILE}.lock"
    local attempts=0
    while ! mkdir "${lock_dir}" 2>/dev/null; do
        attempts=$((attempts + 1))
        if [[ "${attempts}" -ge 50 ]]; then
            fail "Could not acquire config lock: ${lock_dir}"
        fi
        sleep 0.2
    done
    CONFIG_LOCK_DIR="${lock_dir}"
}

release_config_lock() {
    if [[ -n "${CONFIG_LOCK_DIR}" && -d "${CONFIG_LOCK_DIR}" ]]; then
        rmdir "${CONFIG_LOCK_DIR}" >/dev/null 2>&1 || true
        CONFIG_LOCK_DIR=""
    fi
}

backup_config_file() {
    local stamp backup_file
    stamp="$(date +%Y%m%d%H%M%S)"
    backup_file="${CONFIG_FILE}.bak.${stamp}"
    cp "${CONFIG_FILE}" "${backup_file}" || fail "Failed to backup config file."
    log_info "Backed up config: ${backup_file}"
}

require_cmd() {
    local cmd="$1"
    command -v "${cmd}" >/dev/null 2>&1 || fail "Missing required command: ${cmd}"
}

trim_slash() {
    local value="$1"
    value="${value%/}"
    printf '%s' "${value}"
}

slugify() {
    local value="$1"
    value="$(printf '%s' "${value}" | tr '[:upper:]' '[:lower:]')"
    value="$(printf '%s' "${value}" | tr -cs 'a-z0-9' '-')"
    value="${value#-}"
    value="${value%-}"
    printf '%s' "${value}"
}

runner_exists_in_config() {
    [[ -f "${CONFIG_FILE}" ]] || return 1
    grep -Fq "name = \"${RUNNER_DESCRIPTION}\"" "${CONFIG_FILE}"
}

detect_git_remote_context() {
    local remote_url host path
    remote_url="$(git remote get-url origin 2>/dev/null || true)"
    [[ -n "${remote_url}" ]] || return 0

    if [[ "${remote_url}" =~ ^git@([^:]+):(.+)$ ]]; then
        host="${BASH_REMATCH[1]}"
        path="${BASH_REMATCH[2]}"
    elif [[ "${remote_url}" =~ ^https?://([^/]+)/(.+)$ ]]; then
        host="${BASH_REMATCH[1]}"
        path="${BASH_REMATCH[2]}"
    else
        return 0
    fi

    path="${path%.git}"

    if [[ -z "${PROJECT_PATH}" ]]; then
        PROJECT_PATH="${path}"
        log_info "Detected project path from git remote: ${PROJECT_PATH}"
    fi

    if [[ "${GITLAB_URL}" == "${DEFAULT_GITLAB_URL}" ]]; then
        GITLAB_URL="https://${host}"
    fi
}

resolve_project_id() {
    if [[ -n "${PROJECT_ID}" ]]; then
        return 0
    fi

    [[ -n "${PROJECT_PATH}" ]] || fail "Missing --project-id or --project-path (cannot resolve project)."

    require_cmd glab
    require_cmd jq

    local encoded
    encoded="$(jq -rn --arg value "${PROJECT_PATH}" '$value|@uri')"
    PROJECT_ID="$(glab api "projects/${encoded}" | jq -r '.id // empty')"
    [[ -n "${PROJECT_ID}" ]] || fail "Unable to resolve project id from path: ${PROJECT_PATH}"
}

create_runner_token() {
    resolve_project_id
    require_cmd glab
    require_cmd jq
    glab auth status >/dev/null 2>&1 || fail "glab is not authenticated. Run: glab auth login"

    log_info "Creating project runner token via GitLab API..."
    local response
    response="$(glab api "user/runners" -X POST \
        -F "runner_type=project_type" \
        -F "project_id=${PROJECT_ID}" \
        -F "description=${RUNNER_DESCRIPTION}" \
        -F "tag_list=${RUNNER_TAGS}" \
        -F "run_untagged=${RUN_UNTAGGED}" \
        -F "locked=${LOCKED}")"

    CREATED_RUNNER_ID="$(printf '%s' "${response}" | jq -r '.id // empty')"
    RUNNER_TOKEN="$(printf '%s' "${response}" | jq -r '.token // empty')"

    [[ -n "${CREATED_RUNNER_ID}" && -n "${RUNNER_TOKEN}" ]] || fail "Failed to create runner token via API."
}

delete_created_runner_if_needed() {
    if [[ -n "${CREATED_RUNNER_ID}" ]] && command -v glab >/dev/null 2>&1; then
        log_warn "Cleaning up runner ${CREATED_RUNNER_ID} because registration failed."
        glab api "runners/${CREATED_RUNNER_ID}" -X DELETE >/dev/null 2>&1 || true
    fi
}

install_gitlab_runner() {
    if command -v gitlab-runner >/dev/null 2>&1; then
        log_info "gitlab-runner already installed."
        return 0
    fi

    [[ "${SKIP_INSTALL}" == "false" ]] || fail "gitlab-runner is not installed and --skip-install was provided."
    require_cmd brew

    log_info "Installing gitlab-runner via Homebrew..."
    brew install gitlab-runner
}

register_runner() {
    if [[ "${FORCE_REGISTER}" != "true" ]] && runner_exists_in_config; then
        log_info "Runner ${RUNNER_DESCRIPTION} already exists in local config. Skipping registration."
        return 0
    fi

    [[ -n "${RUNNER_TOKEN}" ]] || create_runner_token

    log_info "Registering runner..."
    if ! gitlab-runner register --non-interactive \
        --url "${GITLAB_URL}" \
        --token "${RUNNER_TOKEN}" \
        --name "${RUNNER_DESCRIPTION}" \
        --executor "${RUNNER_EXECUTOR}"; then
        delete_created_runner_if_needed
        fail "gitlab-runner register failed."
    fi
}

ensure_runner_path_env() {
    [[ -f "${CONFIG_FILE}" ]] || {
        log_warn "Runner config not found at ${CONFIG_FILE}; skip PATH environment injection."
        return 0
    }

    if [[ -z "${RUNNER_PATH}" ]]; then
        RUNNER_PATH="${HOME}/fvm/default/bin:/opt/homebrew/opt/node@24/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    fi

    acquire_config_lock
    backup_config_file

    local tmp_file
    tmp_file="$(mktemp "${CONFIG_FILE}.tmp.XXXXXX")"
    awk \
        -v target_name="${RUNNER_DESCRIPTION}" \
        -v path_value="${RUNNER_PATH}" \
        '
        BEGIN {
            in_runner = 0
            is_target = 0
            env_written = 0
            env_line = "  environment = [\"PATH=" path_value "\"]"
        }
        /^\[\[runners\]\]$/ {
            if (in_runner == 1 && is_target == 1 && env_written == 0) {
                print env_line
            }
            in_runner = 1
            is_target = 0
            env_written = 0
            print
            next
        }
        {
            if (in_runner == 1 && $0 ~ /^  name = "/) {
                line = $0
                sub(/^  name = "/, "", line)
                sub(/"$/, "", line)
                if (line == target_name) {
                    is_target = 1
                }
            }

            if (in_runner == 1 && is_target == 1 && $0 ~ /^  environment = \[/) {
                print env_line
                env_written = 1
                next
            }

            if (in_runner == 1 && is_target == 1 && env_written == 0 && $0 ~ /^  \[runners\.cache\]/) {
                print env_line
                env_written = 1
            }

            print
        }
        END {
            if (in_runner == 1 && is_target == 1 && env_written == 0) {
                print env_line
            }
        }' "${CONFIG_FILE}" > "${tmp_file}" || {
        rm -f "${tmp_file}" >/dev/null 2>&1 || true
        release_config_lock
        fail "Failed to update runner config."
    }

    mv "${tmp_file}" "${CONFIG_FILE}" || {
        rm -f "${tmp_file}" >/dev/null 2>&1 || true
        release_config_lock
        fail "Failed to write runner config."
    }
    release_config_lock
    log_info "Injected runner PATH environment for ${RUNNER_DESCRIPTION}"
}

restart_runner_service() {
    [[ "${SKIP_SERVICE}" == "false" ]] || {
        log_warn "Skipping service restart/start."
        return 0
    }

    local restarted="false"

    if command -v brew >/dev/null 2>&1; then
        log_info "Restarting gitlab-runner service via Homebrew..."
        if brew services restart gitlab-runner >/dev/null 2>&1 || brew services start gitlab-runner >/dev/null 2>&1; then
            restarted="true"
        fi
    else
        log_warn "Homebrew not found. Falling back to user-mode service commands."
        if gitlab-runner stop >/dev/null 2>&1 \
            && gitlab-runner install >/dev/null 2>&1 \
            && gitlab-runner start >/dev/null 2>&1; then
            restarted="true"
        fi
    fi

    if [[ "${restarted}" != "true" ]]; then
        if [[ "${STRICT}" == "true" ]]; then
            fail "Failed to restart/start gitlab-runner service in strict mode."
        fi
        log_warn "Could not restart/start gitlab-runner service."
    fi
}

verify_runner() {
    if gitlab-runner verify >/dev/null 2>&1; then
        log_info "gitlab-runner verify passed."
    else
        if [[ "${STRICT}" == "true" ]]; then
            fail "gitlab-runner verify failed in strict mode."
        fi
        log_warn "gitlab-runner verify failed. Check runner status in GitLab UI."
    fi
}

print_summary() {
    log_info "Setup completed."
    printf 'Runner name: %s\n' "${RUNNER_DESCRIPTION}"
    if [[ -n "${CREATED_RUNNER_ID}" ]]; then
        printf 'Runner id: %s\n' "${CREATED_RUNNER_ID}"
    fi
    printf 'GitLab URL: %s\n' "${GITLAB_URL}"
    printf 'Tags: %s\n' "${RUNNER_TAGS}"
    printf 'Executor: %s\n' "${RUNNER_EXECUTOR}"
    printf '\n'
    printf 'Verify commands:\n'
    printf '  gitlab-runner verify\n'
    if command -v brew >/dev/null 2>&1; then
        printf '  brew services list | rg gitlab-runner\n'
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --gitlab-url)
            GITLAB_URL="$(trim_slash "${2:-}")"
            shift 2
            ;;
        --project-id)
            PROJECT_ID="${2:-}"
            shift 2
            ;;
        --project-path)
            PROJECT_PATH="${2:-}"
            shift 2
            ;;
        --runner-token)
            RUNNER_TOKEN="${2:-}"
            shift 2
            ;;
        --name)
            RUNNER_DESCRIPTION="${2:-}"
            shift 2
            ;;
        --tags)
            RUNNER_TAGS="${2:-}"
            shift 2
            ;;
        --executor)
            RUNNER_EXECUTOR="${2:-}"
            shift 2
            ;;
        --run-untagged)
            RUN_UNTAGGED="${2:-}"
            shift 2
            ;;
        --locked)
            LOCKED="${2:-}"
            shift 2
            ;;
        --runner-path)
            RUNNER_PATH="${2:-}"
            shift 2
            ;;
        --skip-install)
            SKIP_INSTALL="true"
            shift
            ;;
        --skip-service)
            SKIP_SERVICE="true"
            shift
            ;;
        --strict)
            STRICT="true"
            shift
            ;;
        --force-register)
            FORCE_REGISTER="true"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage
            fail "Unknown option: $1"
            ;;
    esac
done

validate_bool "run-untagged" "${RUN_UNTAGGED}"
validate_bool "locked" "${LOCKED}"
validate_bool "strict" "${STRICT}"

trap 'release_config_lock' EXIT

detect_git_remote_context

if [[ -z "${RUNNER_DESCRIPTION}" ]]; then
    host_slug="$(slugify "$(hostname -s)")"
    project_slug="project"
    if [[ -n "${PROJECT_PATH}" ]]; then
        project_slug="$(slugify "${PROJECT_PATH}")"
    fi
    RUNNER_DESCRIPTION="gitlab-runner-${host_slug}-${project_slug}"
fi

install_gitlab_runner
register_runner
ensure_runner_path_env
restart_runner_service
verify_runner
print_summary

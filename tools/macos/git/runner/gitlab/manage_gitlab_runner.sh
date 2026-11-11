#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
CONFIG_FILE="${HOME}/.gitlab-runner/config.toml"
CONFIG_LOCK_DIR=""

DRY_RUN="false"
YES="false"
SKIP_SERVICE_RESTART="false"
STRICT="false"
JSON="false"
JSON_RESULT=""

LAST_REMOTE_DELETE="skipped"
LAST_LOCAL_DELETE="skipped"
LAST_SERVICE_RESTART="skipped"

usage() {
    cat <<EOF_USAGE
Usage:
  ./${SCRIPT_NAME} list [--json]
  ./${SCRIPT_NAME} delete-one (--name <runner-name> | --id <runner-id>) [--yes] [--dry-run] [--strict] [--json]
  ./${SCRIPT_NAME} delete-all [--yes] [--dry-run] [--strict] [--json]
  ./${SCRIPT_NAME} clean-cache [--yes] [--dry-run] [--json]

Options:
  --name <runner-name>      Runner name (for delete-one)
  --id <runner-id>          Runner id (for delete-one)
  --yes                     Skip confirmation prompts
  --dry-run                 Print actions without making changes
  --skip-service-restart    Do not restart gitlab-runner service after delete
  --strict                  Fail when remote delete or service restart fails
  --json                    Output machine-readable JSON
  -h, --help                Show this help message

Examples:
  ./${SCRIPT_NAME} list
  ./${SCRIPT_NAME} list --json
  ./${SCRIPT_NAME} delete-one --name gitlab-runner-macbook-eup-hddhistory-hddhistory-flutter --yes --strict
  ./${SCRIPT_NAME} delete-all --yes
  ./${SCRIPT_NAME} clean-cache --yes
EOF_USAGE
}

log_info() {
    printf '[INFO] %s\n' "$1" >&2
}

log_warn() {
    printf '[WARN] %s\n' "$1" >&2
}

log_error() {
    printf '[ERROR] %s\n' "$1" >&2
}

fail() {
    log_error "$1"
    exit 1
}

json_escape() {
    local value="${1:-}"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\n'/\\n}"
    value="${value//$'\r'/\\r}"
    value="${value//$'\t'/\\t}"
    printf '%s' "${value}"
}

emit_json() {
    printf '%s\n' "$1"
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
    cp "${CONFIG_FILE}" "${backup_file}" || fail "Failed to backup config file"
    log_info "Backed up config: ${backup_file}"
}

confirm() {
    local message="$1"
    if [[ "${YES}" == "true" ]]; then
        return 0
    fi
    printf '%s [y/N]: ' "$message" >&2
    local answer
    read -r answer
    [[ "${answer}" =~ ^[Yy]$ ]]
}

has_glab_auth() {
    command -v glab >/dev/null 2>&1 && glab auth status >/dev/null 2>&1
}

has_jq() {
    command -v jq >/dev/null 2>&1
}

runner_lines() {
    [[ -f "${CONFIG_FILE}" ]] || return 0
    awk '
    function flush() {
      if (in_runner == 1 && name != "") {
        printf "%s|%s|%s|%s\n", name, id, url, executor
      }
      in_runner = 0
      name = ""
      id = ""
      url = ""
      executor = ""
    }
    /^\[\[runners\]\]$/ {
      flush()
      in_runner = 1
      next
    }
    {
      if (in_runner != 1) next
      if ($0 ~ /^  name = "/) {
        line = $0
        sub(/^  name = "/, "", line)
        sub(/"$/, "", line)
        name = line
      } else if ($0 ~ /^  id = /) {
        line = $0
        sub(/^  id = /, "", line)
        gsub(/ /, "", line)
        id = line
      } else if ($0 ~ /^  url = "/) {
        line = $0
        sub(/^  url = "/, "", line)
        sub(/"$/, "", line)
        url = line
      } else if ($0 ~ /^  executor = "/) {
        line = $0
        sub(/^  executor = "/, "", line)
        sub(/"$/, "", line)
        executor = line
      }
    }
    END {
      flush()
    }' "${CONFIG_FILE}"
}

remote_summary_by_id() {
    local runner_id="$1"
    if [[ -z "${runner_id}" ]]; then
        printf 'remote=unknown'
        return 0
    fi

    if ! has_glab_auth || ! has_jq; then
        printf 'remote=auth_unavailable'
        return 0
    fi

    local response
    response="$(glab api "runners/${runner_id}" 2>/dev/null || true)"
    if [[ -z "${response}" || "${response}" == *'"message":"404 Not found"'* ]]; then
        printf 'remote=not_found'
        return 0
    fi

    printf '%s' "${response}" | jq -r '"remote=\(.status) active=\(.active) paused=\(.paused) tags=\((.tag_list // []) | join(","))"'
}

print_runner_info() {
    local name="$1"
    local id="$2"
    local url="$3"
    local executor="$4"
    local remote
    remote="$(remote_summary_by_id "${id}")"

    printf 'Runner info:\n' >&2
    printf '  name: %s\n' "${name}" >&2
    printf '  id: %s\n' "${id:-n/a}" >&2
    printf '  url: %s\n' "${url:-n/a}" >&2
    printf '  executor: %s\n' "${executor:-n/a}" >&2
    printf '  %s\n' "${remote}" >&2
}

remove_runner_block_from_config() {
    local target_name="$1"
    [[ -f "${CONFIG_FILE}" ]] || return 0

    acquire_config_lock
    backup_config_file

    local tmp_file
    tmp_file="$(mktemp "${CONFIG_FILE}.tmp.XXXXXX")"

    awk -v target="${target_name}" '
    function flush_block() {
      if (block_started == 0) return
      if (block_name != target) {
        printf "%s", block
      }
      block = ""
      block_name = ""
      block_started = 0
    }
    /^\[\[runners\]\]$/ {
      flush_block()
      block_started = 1
      block = $0 ORS
      next
    }
    {
      if (block_started == 1) {
        block = block $0 ORS
        if ($0 ~ /^  name = "/) {
          line = $0
          sub(/^  name = "/, "", line)
          sub(/"$/, "", line)
          block_name = line
        }
        next
      }
      print
    }
    END {
      flush_block()
    }' "${CONFIG_FILE}" > "${tmp_file}" || {
        rm -f "${tmp_file}" >/dev/null 2>&1 || true
        release_config_lock
        fail "Failed to update config while removing runner block."
    }

    mv "${tmp_file}" "${CONFIG_FILE}" || {
        rm -f "${tmp_file}" >/dev/null 2>&1 || true
        release_config_lock
        fail "Failed to write updated config file."
    }

    release_config_lock
}

restart_runner_service_if_needed() {
    LAST_SERVICE_RESTART="skipped"
    [[ "${SKIP_SERVICE_RESTART}" == "false" ]] || return 0

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] brew services restart gitlab-runner"
        LAST_SERVICE_RESTART="dry_run"
        return 0
    fi

    if ! command -v brew >/dev/null 2>&1; then
        LAST_SERVICE_RESTART="unsupported"
        if [[ "${STRICT}" == "true" ]]; then
            fail "brew not found; strict mode requires successful service restart."
        fi
        log_warn "brew not found; skip service restart."
        return 0
    fi

    log_info "Restarting gitlab-runner service..."
    if brew services restart gitlab-runner >/dev/null 2>&1 || brew services start gitlab-runner >/dev/null 2>&1; then
        LAST_SERVICE_RESTART="restarted"
        return 0
    fi

    LAST_SERVICE_RESTART="failed"
    if [[ "${STRICT}" == "true" ]]; then
        fail "Failed to restart gitlab-runner service in strict mode."
    fi
    log_warn "Failed to restart gitlab-runner service."
}

delete_remote_runner_if_possible() {
    local runner_id="$1"
    LAST_REMOTE_DELETE="skipped"

    [[ -n "${runner_id}" ]] || {
        LAST_REMOTE_DELETE="skipped_no_id"
        return 0
    }

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] glab api runners/${runner_id} -X DELETE"
        LAST_REMOTE_DELETE="dry_run"
        return 0
    fi

    if ! has_glab_auth; then
        LAST_REMOTE_DELETE="auth_unavailable"
        if [[ "${STRICT}" == "true" ]]; then
            fail "glab auth unavailable; strict mode requires remote delete."
        fi
        log_warn "glab auth unavailable; skip remote delete for id=${runner_id}"
        return 0
    fi

    if glab api "runners/${runner_id}" -X DELETE >/dev/null 2>&1; then
        log_info "Deleted remote runner id=${runner_id}"
        LAST_REMOTE_DELETE="deleted"
        return 0
    fi

    LAST_REMOTE_DELETE="failed"
    if [[ "${STRICT}" == "true" ]]; then
        fail "Failed to delete remote runner id=${runner_id} in strict mode."
    fi
    log_warn "Failed to delete remote runner id=${runner_id} (it may already be removed)."
}

delete_local_runner() {
    local name="$1"
    LAST_LOCAL_DELETE="skipped"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[dry-run] gitlab-runner unregister --name ${name}"
        LAST_LOCAL_DELETE="dry_run"
        return 0
    fi

    if command -v gitlab-runner >/dev/null 2>&1; then
        if gitlab-runner unregister --name "${name}" >/dev/null 2>&1; then
            LAST_LOCAL_DELETE="unregistered"
        else
            LAST_LOCAL_DELETE="unregister_failed"
            log_warn "Failed to unregister runner by name: ${name}"
        fi
    fi

    if grep -Fq "name = \"${name}\"" "${CONFIG_FILE}" 2>/dev/null; then
        remove_runner_block_from_config "${name}"
        LAST_LOCAL_DELETE="deleted_config"
    fi
}

list_runners() {
    local lines
    lines="$(runner_lines || true)"

    if [[ "${JSON}" == "true" ]]; then
        local count=0
        local json_items=""
        local sep=""

        if [[ -n "${lines}" ]]; then
            while IFS='|' read -r name id url executor; do
                local remote
                remote="$(remote_summary_by_id "${id}")"
                json_items+="${sep}{\"name\":\"$(json_escape "${name}")\",\"id\":\"$(json_escape "${id}")\",\"url\":\"$(json_escape "${url}")\",\"executor\":\"$(json_escape "${executor}")\",\"remote\":\"$(json_escape "${remote}")\"}"
                sep=","
                count=$((count + 1))
            done <<< "${lines}"
        fi

        JSON_RESULT="{\"command\":\"list\",\"config_file\":\"$(json_escape "${CONFIG_FILE}")\",\"runner_count\":${count},\"runners\":[${json_items}]}"
        return 0
    fi

    if [[ -z "${lines}" ]]; then
        log_info "No local runners found in ${CONFIG_FILE}"
        return 0
    fi

    printf '%-4s | %-60s | %-10s | %-8s | %-40s\n' "No" "Name" "ID" "Exec" "Remote"
    printf '%s\n' "-----|--------------------------------------------------------------|------------|----------|----------------------------------------"

    local idx=1
    while IFS='|' read -r name id url executor; do
        local remote
        remote="$(remote_summary_by_id "${id}")"
        printf '%-4s | %-60s | %-10s | %-8s | %-40s\n' "${idx}" "${name}" "${id:-n/a}" "${executor:-n/a}" "${remote}"
        idx=$((idx + 1))
    done <<< "${lines}"
}

resolve_runner_by_name_or_id() {
    local expected_name="${1:-}"
    local expected_id="${2:-}"
    local lines
    lines="$(runner_lines || true)"
    [[ -n "${lines}" ]] || return 1

    while IFS='|' read -r name id url executor; do
        if [[ -n "${expected_name}" && "${name}" == "${expected_name}" ]]; then
            printf '%s|%s|%s|%s\n' "${name}" "${id}" "${url}" "${executor}"
            return 0
        fi
        if [[ -n "${expected_id}" && "${id}" == "${expected_id}" ]]; then
            printf '%s|%s|%s|%s\n' "${name}" "${id}" "${url}" "${executor}"
            return 0
        fi
    done <<< "${lines}"
    return 1
}

delete_one_runner() {
    local target_name="${1:-}"
    local target_id="${2:-}"
    local runner
    runner="$(resolve_runner_by_name_or_id "${target_name}" "${target_id}" || true)"
    [[ -n "${runner}" ]] || fail "Runner not found in local config."

    local name id url executor
    IFS='|' read -r name id url executor <<< "${runner}"

    if [[ "${JSON}" != "true" ]]; then
        print_runner_info "${name}" "${id}" "${url}" "${executor}"
    fi

    confirm "Delete this runner?" || fail "Cancelled."

    delete_remote_runner_if_possible "${id}"
    delete_local_runner "${name}"
    restart_runner_service_if_needed

    if [[ "${JSON}" == "true" ]]; then
        JSON_RESULT="{\"command\":\"delete-one\",\"name\":\"$(json_escape "${name}")\",\"id\":\"$(json_escape "${id}")\",\"remote_delete\":\"$(json_escape "${LAST_REMOTE_DELETE}")\",\"local_delete\":\"$(json_escape "${LAST_LOCAL_DELETE}")\",\"service_restart\":\"$(json_escape "${LAST_SERVICE_RESTART}")\"}"
    else
        log_info "Runner deleted: ${name}"
    fi
}

delete_all_runners() {
    local lines
    lines="$(runner_lines || true)"
    [[ -n "${lines}" ]] || {
        if [[ "${JSON}" == "true" ]]; then
            JSON_RESULT='{"command":"delete-all","count":0,"remote_failures":0,"service_restart":"skipped"}'
        else
            log_info "No local runners to delete."
        fi
        return 0
    }

    local count
    count="$(printf '%s\n' "${lines}" | wc -l | tr -d ' ')"
    log_warn "Will delete ${count} local runners."
    confirm "Continue delete-all?" || fail "Cancelled."

    local remote_failures=0
    local local_changed=0

    while IFS='|' read -r name id url executor; do
        if [[ "${JSON}" != "true" ]]; then
            print_runner_info "${name}" "${id}" "${url}" "${executor}"
        fi

        delete_remote_runner_if_possible "${id}"
        delete_local_runner "${name}"

        case "${LAST_REMOTE_DELETE}" in
            failed|auth_unavailable)
                remote_failures=$((remote_failures + 1))
                ;;
        esac

        case "${LAST_LOCAL_DELETE}" in
            deleted_config|unregistered)
                local_changed=$((local_changed + 1))
                ;;
        esac
    done <<< "${lines}"

    restart_runner_service_if_needed

    if [[ "${JSON}" == "true" ]]; then
        JSON_RESULT="{\"command\":\"delete-all\",\"count\":${count},\"local_changed\":${local_changed},\"remote_failures\":${remote_failures},\"service_restart\":\"$(json_escape "${LAST_SERVICE_RESTART}")\"}"
    else
        log_info "Delete-all completed."
    fi
}

clean_cache() {
    local cache_dirs=(
        "${HOME}/builds"
        "${HOME}/.cache/gitlab-runner"
        "${HOME}/.gitlab-runner/cache"
    )

    log_warn "Will remove runner caches and build workdirs."
    confirm "Continue clean-cache?" || fail "Cancelled."

    local removed_count=0
    local skipped_count=0

    local dir
    for dir in "${cache_dirs[@]}"; do
        if [[ -d "${dir}" ]]; then
            local size
            size="$(du -sh "${dir}" 2>/dev/null | awk '{print $1}')"
            log_info "Cache path: ${dir} (${size:-unknown})"
            if [[ "${DRY_RUN}" == "true" ]]; then
                log_info "[dry-run] rm -rf ${dir}"
                skipped_count=$((skipped_count + 1))
            else
                rm -rf "${dir}"
                removed_count=$((removed_count + 1))
            fi
        else
            log_info "Cache path not found (skip): ${dir}"
            skipped_count=$((skipped_count + 1))
        fi
    done

    if [[ "${JSON}" == "true" ]]; then
        JSON_RESULT="{\"command\":\"clean-cache\",\"removed_count\":${removed_count},\"skipped_count\":${skipped_count},\"dry_run\":${DRY_RUN}}"
        return 0
    fi

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "clean-cache dry-run completed."
    elif [[ "${removed_count}" -gt 0 ]]; then
        log_info "clean-cache completed."
    else
        log_info "No cache directories were removed."
    fi
}

trap 'release_config_lock' EXIT

COMMAND="${1:-}"
[[ -n "${COMMAND}" ]] || {
    usage
    exit 1
}
shift || true

TARGET_NAME=""
TARGET_ID=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name)
            TARGET_NAME="${2:-}"
            shift 2
            ;;
        --id)
            TARGET_ID="${2:-}"
            shift 2
            ;;
        --yes)
            YES="true"
            shift
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        --skip-service-restart)
            SKIP_SERVICE_RESTART="true"
            shift
            ;;
        --strict)
            STRICT="true"
            shift
            ;;
        --json)
            JSON="true"
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

case "${COMMAND}" in
    list)
        list_runners
        ;;
    delete-one|remove-one|delete)
        [[ -n "${TARGET_NAME}" || -n "${TARGET_ID}" ]] || fail "delete-one requires --name or --id"
        delete_one_runner "${TARGET_NAME}" "${TARGET_ID}"
        ;;
    delete-all|remove-all|delete-alls)
        delete_all_runners
        ;;
    clean-cache|clear-cache)
        clean_cache
        ;;
    *)
        usage
        fail "Unknown command: ${COMMAND}"
        ;;
esac

if [[ "${JSON}" == "true" && -n "${JSON_RESULT}" ]]; then
    emit_json "${JSON_RESULT}"
fi

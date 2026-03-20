#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

RUNNER_ROOT="${HOME}/actions-runners"
REPO=""
TARGET_NAME=""
TARGET_DIR=""

DRY_RUN="false"
YES="false"
STRICT="false"
JSON="false"
SKIP_SERVICE_UNINSTALL="false"
JSON_RESULT=""

LAST_REMOTE_DELETE="skipped"
LAST_LOCAL_DELETE="skipped"

usage() {
  cat <<EOF_USAGE
Usage:
  ./${SCRIPT_NAME} list [--json]
  ./${SCRIPT_NAME} delete-one (--name <runner-name> | --dir <runner-dir>) [--yes] [--dry-run] [--strict] [--json]
  ./${SCRIPT_NAME} delete-all [--yes] [--dry-run] [--strict] [--json]
  ./${SCRIPT_NAME} clean-cache [--yes] [--dry-run] [--json]

Options:
  --runner-root <path>         Root directory of GitHub runners (default: ${HOME}/actions-runners)
  --repo <owner/repo>          Fallback repository for remote delete if not detected from runner metadata
  --name <runner-name>         Runner name (for delete-one)
  --dir <runner-dir>           Runner directory (for delete-one)
  --yes                        Skip confirmation prompts
  --dry-run                    Print actions without making changes
  --strict                     Fail when remote delete or local delete fails
  --json                       Output machine-readable JSON
  --skip-service-uninstall     Skip svc.sh stop/uninstall during local delete
  -h, --help                   Show this help message

Examples:
  ./${SCRIPT_NAME} list
  ./${SCRIPT_NAME} list --json
  ./${SCRIPT_NAME} delete-one --name github-runner-mac-mini-owner-repo-macos --yes
  ./${SCRIPT_NAME} delete-all --yes --strict
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

require_jq() {
  command -v jq >/dev/null 2>&1 || fail "jq is required. Install with: brew install jq"
}

gh_auth_available() {
  command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1
}

extract_repo_from_url() {
  local url="${1:-}"
  url="${url%/}"
  if [[ "${url}" =~ ^https?://[^/]+/([^/]+/[^/]+)$ ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  fi
}

runner_records() {
  [[ -d "${RUNNER_ROOT}" ]] || return 0

  local runner_file
  while IFS= read -r runner_file; do
    [[ -f "${runner_file}" ]] || continue

    local runner_dir name id server_url repo
    runner_dir="$(dirname "${runner_file}")"
    name="$(jq -r '.AgentName // .agentName // empty' "${runner_file}" 2>/dev/null || true)"
    id="$(jq -r '.AgentId // .agentId // empty' "${runner_file}" 2>/dev/null || true)"
    server_url="$(jq -r '.ServerUrl // .serverUrl // .GitHubUrl // .gitHubUrl // empty' "${runner_file}" 2>/dev/null || true)"
    repo="$(extract_repo_from_url "${server_url}")"

    printf '%s|%s|%s|%s|%s\n' "${name}" "${id}" "${repo}" "${server_url}" "${runner_dir}"
  done < <(find "${RUNNER_ROOT}" -maxdepth 4 -type f -name '.runner' | sort)
}

print_runner_info() {
  local name="$1"
  local id="$2"
  local repo="$3"
  local server_url="$4"
  local runner_dir="$5"

  printf 'Runner info:\n' >&2
  printf '  name: %s\n' "${name:-n/a}" >&2
  printf '  id: %s\n' "${id:-n/a}" >&2
  printf '  repo: %s\n' "${repo:-n/a}" >&2
  printf '  url: %s\n' "${server_url:-n/a}" >&2
  printf '  dir: %s\n' "${runner_dir:-n/a}" >&2
}

resolve_runner() {
  local expected_name="${1:-}"
  local expected_dir="${2:-}"
  local records
  records="$(runner_records || true)"
  [[ -n "${records}" ]] || return 1

  local name id repo server_url runner_dir
  while IFS='|' read -r name id repo server_url runner_dir; do
    if [[ -n "${expected_name}" && "${name}" == "${expected_name}" ]]; then
      printf '%s|%s|%s|%s|%s\n' "${name}" "${id}" "${repo}" "${server_url}" "${runner_dir}"
      return 0
    fi
    if [[ -n "${expected_dir}" && "${runner_dir}" == "${expected_dir}" ]]; then
      printf '%s|%s|%s|%s|%s\n' "${name}" "${id}" "${repo}" "${server_url}" "${runner_dir}"
      return 0
    fi
  done <<< "${records}"

  return 1
}

delete_remote_runner_if_possible() {
  local repo="$1"
  local id="$2"

  LAST_REMOTE_DELETE="skipped"

  [[ -n "${repo}" ]] || repo="${REPO}"
  if [[ -z "${repo}" || -z "${id}" ]]; then
    LAST_REMOTE_DELETE="skipped_missing_repo_or_id"
    return 0
  fi

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_info "[dry-run] gh api --method DELETE repos/${repo}/actions/runners/${id}"
    LAST_REMOTE_DELETE="dry_run"
    return 0
  fi

  if ! gh_auth_available; then
    LAST_REMOTE_DELETE="auth_unavailable"
    if [[ "${STRICT}" == "true" ]]; then
      fail "gh auth unavailable; strict mode requires remote delete."
    fi
    log_warn "gh auth unavailable; skip remote delete for ${repo} runner id=${id}"
    return 0
  fi

  if gh api --method DELETE "repos/${repo}/actions/runners/${id}" >/dev/null 2>&1; then
    LAST_REMOTE_DELETE="deleted"
    log_info "Deleted remote GitHub runner ${id} from ${repo}"
  else
    LAST_REMOTE_DELETE="failed"
    if [[ "${STRICT}" == "true" ]]; then
      fail "Failed remote runner delete in strict mode (${repo} id=${id})"
    fi
    log_warn "Failed remote runner delete (${repo} id=${id})"
  fi
}

delete_local_runner() {
  local runner_dir="$1"
  local repo="$2"

  LAST_LOCAL_DELETE="skipped"

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_info "[dry-run] remove local runner dir: ${runner_dir}"
    LAST_LOCAL_DELETE="dry_run"
    return 0
  fi

  [[ -d "${runner_dir}" ]] || {
    LAST_LOCAL_DELETE="missing_dir"
    if [[ "${STRICT}" == "true" ]]; then
      fail "Runner directory not found in strict mode: ${runner_dir}"
    fi
    log_warn "Runner directory not found: ${runner_dir}"
    return 0
  }

  if [[ "${SKIP_SERVICE_UNINSTALL}" != "true" ]] && [[ -x "${runner_dir}/svc.sh" ]]; then
    (
      cd "${runner_dir}"
      ./svc.sh stop >/dev/null 2>&1 || true
      ./svc.sh uninstall >/dev/null 2>&1 || true
      if command -v sudo >/dev/null 2>&1; then
        sudo ./svc.sh stop >/dev/null 2>&1 || true
        sudo ./svc.sh uninstall >/dev/null 2>&1 || true
      fi
    )
  fi

  if [[ -x "${runner_dir}/config.sh" ]] && gh_auth_available; then
    local effective_repo token
    effective_repo="${repo}"
    [[ -n "${effective_repo}" ]] || effective_repo="${REPO}"

    if [[ -n "${effective_repo}" ]]; then
      token="$(gh api --method POST "repos/${effective_repo}/actions/runners/remove-token" --jq '.token' 2>/dev/null || true)"
      if [[ -n "${token}" ]]; then
        (
          cd "${runner_dir}"
          ./config.sh remove --token "${token}" >/dev/null 2>&1 || true
        )
      fi
    fi
  fi

  rm -rf "${runner_dir}" || {
    LAST_LOCAL_DELETE="failed"
    if [[ "${STRICT}" == "true" ]]; then
      fail "Failed to remove runner directory in strict mode: ${runner_dir}"
    fi
    log_warn "Failed to remove runner directory: ${runner_dir}"
    return 0
  }

  LAST_LOCAL_DELETE="deleted"
  log_info "Removed local runner directory: ${runner_dir}"
}

list_runners() {
  require_jq

  local records
  records="$(runner_records || true)"

  if [[ "${JSON}" == "true" ]]; then
    local count=0
    local items=""
    local sep=""

    if [[ -n "${records}" ]]; then
      local name id repo server_url runner_dir
      while IFS='|' read -r name id repo server_url runner_dir; do
        items+="${sep}{\"name\":\"$(json_escape "${name}")\",\"id\":\"$(json_escape "${id}")\",\"repo\":\"$(json_escape "${repo}")\",\"url\":\"$(json_escape "${server_url}")\",\"dir\":\"$(json_escape "${runner_dir}")\"}"
        sep=","
        count=$((count + 1))
      done <<< "${records}"
    fi

    JSON_RESULT="{\"command\":\"list\",\"runner_root\":\"$(json_escape "${RUNNER_ROOT}")\",\"runner_count\":${count},\"runners\":[${items}]}"
    return 0
  fi

  if [[ -z "${records}" ]]; then
    log_info "No local GitHub runners found in ${RUNNER_ROOT}"
    return 0
  fi

  printf '%-4s | %-50s | %-10s | %-28s | %s\n' "No" "Name" "ID" "Repo" "Dir"
  printf '%s\n' "-----|--------------------------------------------------|------------|------------------------------|-------------------------"

  local idx=1
  local name id repo server_url runner_dir
  while IFS='|' read -r name id repo server_url runner_dir; do
    printf '%-4s | %-50s | %-10s | %-28s | %s\n' "${idx}" "${name:-n/a}" "${id:-n/a}" "${repo:-n/a}" "${runner_dir}"
    idx=$((idx + 1))
  done <<< "${records}"
}

delete_one_runner() {
  require_jq

  local record
  record="$(resolve_runner "${TARGET_NAME}" "${TARGET_DIR}" || true)"
  [[ -n "${record}" ]] || fail "Runner not found in ${RUNNER_ROOT}"

  local name id repo server_url runner_dir
  IFS='|' read -r name id repo server_url runner_dir <<< "${record}"

  if [[ "${JSON}" != "true" ]]; then
    print_runner_info "${name}" "${id}" "${repo}" "${server_url}" "${runner_dir}"
  fi

  confirm "Delete this runner?" || fail "Cancelled."

  delete_remote_runner_if_possible "${repo}" "${id}"
  delete_local_runner "${runner_dir}" "${repo}"

  if [[ "${JSON}" == "true" ]]; then
    JSON_RESULT="{\"command\":\"delete-one\",\"name\":\"$(json_escape "${name}")\",\"id\":\"$(json_escape "${id}")\",\"repo\":\"$(json_escape "${repo}")\",\"remote_delete\":\"$(json_escape "${LAST_REMOTE_DELETE}")\",\"local_delete\":\"$(json_escape "${LAST_LOCAL_DELETE}")\"}"
  else
    log_info "Runner deleted: ${name}"
  fi
}

delete_all_runners() {
  require_jq

  local records
  records="$(runner_records || true)"
  [[ -n "${records}" ]] || {
    if [[ "${JSON}" == "true" ]]; then
      JSON_RESULT='{"command":"delete-all","count":0,"remote_failures":0,"local_failures":0}'
    else
      log_info "No local runners to delete."
    fi
    return 0
  }

  local count
  count="$(printf '%s\n' "${records}" | wc -l | tr -d ' ')"
  log_warn "Will delete ${count} local GitHub runners."
  confirm "Continue delete-all?" || fail "Cancelled."

  local remote_failures=0
  local local_failures=0

  local name id repo server_url runner_dir
  while IFS='|' read -r name id repo server_url runner_dir; do
    if [[ "${JSON}" != "true" ]]; then
      print_runner_info "${name}" "${id}" "${repo}" "${server_url}" "${runner_dir}"
    fi

    delete_remote_runner_if_possible "${repo}" "${id}"
    delete_local_runner "${runner_dir}" "${repo}"

    if [[ "${LAST_REMOTE_DELETE}" == "failed" || "${LAST_REMOTE_DELETE}" == "auth_unavailable" ]]; then
      remote_failures=$((remote_failures + 1))
    fi

    if [[ "${LAST_LOCAL_DELETE}" == "failed" ]]; then
      local_failures=$((local_failures + 1))
    fi
  done <<< "${records}"

  if [[ "${JSON}" == "true" ]]; then
    JSON_RESULT="{\"command\":\"delete-all\",\"count\":${count},\"remote_failures\":${remote_failures},\"local_failures\":${local_failures}}"
  else
    log_info "Delete-all completed."
  fi
}

clean_cache() {
  local work_dirs=()
  if [[ -d "${RUNNER_ROOT}" ]]; then
    while IFS= read -r work_dir; do
      work_dirs+=("${work_dir}")
    done < <(find "${RUNNER_ROOT}" -maxdepth 5 -type d -name '_work' | sort)
  fi

  log_warn "Will remove GitHub runner work caches (_work)."
  confirm "Continue clean-cache?" || fail "Cancelled."

  local removed_count=0
  local skipped_count=0

  local dir
  for dir in "${work_dirs[@]}"; do
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
    fi
  done

  if [[ "${JSON}" == "true" ]]; then
    JSON_RESULT="{\"command\":\"clean-cache\",\"runner_root\":\"$(json_escape "${RUNNER_ROOT}")\",\"removed_count\":${removed_count},\"skipped_count\":${skipped_count},\"dry_run\":${DRY_RUN}}"
    return 0
  fi

  if [[ "${DRY_RUN}" == "true" ]]; then
    log_info "clean-cache dry-run completed."
  elif [[ "${removed_count}" -gt 0 ]]; then
    log_info "clean-cache completed."
  else
    log_info "No runner cache directories found."
  fi
}

COMMAND="${1:-}"
[[ -n "${COMMAND}" ]] || {
  usage
  exit 1
}
shift || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runner-root)
      RUNNER_ROOT="${2:-}"
      shift 2
      ;;
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --name)
      TARGET_NAME="${2:-}"
      shift 2
      ;;
    --dir)
      TARGET_DIR="${2:-}"
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
    --strict)
      STRICT="true"
      shift
      ;;
    --json)
      JSON="true"
      shift
      ;;
    --skip-service-uninstall)
      SKIP_SERVICE_UNINSTALL="true"
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
    [[ -n "${TARGET_NAME}" || -n "${TARGET_DIR}" ]] || fail "delete-one requires --name or --dir"
    delete_one_runner
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

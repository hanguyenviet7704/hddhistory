#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

DEFAULT_GITHUB_URL="https://github.com"
DEFAULT_LABELS="self-hosted,linux"
DEFAULT_RUNNER_ROOT="${HOME}/actions-runners"
DEFAULT_WORK_DIR="_work"
DEFAULT_RUNNER_VERSION="2.327.1"

GITHUB_URL="${DEFAULT_GITHUB_URL}"
REPO=""
RUNNER_TOKEN=""
RUNNER_NAME=""
RUNNER_LABELS="${DEFAULT_LABELS}"
RUNNER_ROOT="${DEFAULT_RUNNER_ROOT}"
RUNNER_DIR=""
WORK_DIR="${DEFAULT_WORK_DIR}"
RUNNER_VERSION=""
SKIP_DOWNLOAD="false"
SKIP_SERVICE="false"
REPLACE="false"
STRICT="false"

usage() {
  cat <<EOF_USAGE
Usage: ./${SCRIPT_NAME} [options]

Set up this Linux machine as a GitHub self-hosted runner for a repository.

Options:
  --github-url <url>        GitHub base URL (default: ${DEFAULT_GITHUB_URL})
  --repo <owner/repo>       Target repository (auto-detected from git remote when possible)
  --runner-token <token>    Existing registration token
  --name <name>             Runner name/description
  --labels <labels>         Comma-separated labels (default: ${DEFAULT_LABELS})
  --runner-root <path>      Root directory for runner installs (default: ${DEFAULT_RUNNER_ROOT})
  --runner-dir <path>       Full runner directory (override runner-root)
  --work-dir <path>         Runner work directory (default: ${DEFAULT_WORK_DIR})
  --runner-version <ver>    Runner version (default: latest via API, fallback ${DEFAULT_RUNNER_VERSION})
  --skip-download           Skip runner download/extract
  --skip-service            Skip service install/start
  --replace                 Reconfigure existing runner with --replace
  --strict                  Fail when service start or remote verify fails
  -h, --help                Show this help message

Examples:
  ./${SCRIPT_NAME} --repo owner/repo
  ./${SCRIPT_NAME} --repo owner/repo --labels self-hosted,linux,flutter
  ./${SCRIPT_NAME} --repo owner/repo --runner-token xxx --name hddhistory-linux-runner
EOF_USAGE
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

validate_repo() {
  local repo="$1"
  [[ "${repo}" =~ ^[^/]+/[^/]+$ ]] || fail "Invalid --repo format: ${repo} (expected owner/repo)"
}

gh_auth_available() {
  command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1
}

detect_repo_from_git_remote() {
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

  if [[ -z "${REPO}" && "${path}" =~ ^[^/]+/[^/]+$ ]]; then
    REPO="${path}"
    log_info "Detected repo from git remote: ${REPO}"
  fi

  if [[ "${GITHUB_URL}" == "${DEFAULT_GITHUB_URL}" && "${host}" == *"github"* ]]; then
    GITHUB_URL="https://${host}"
  fi
}

resolve_runner_version() {
  if [[ -n "${RUNNER_VERSION}" ]]; then
    return 0
  fi

  if gh_auth_available && command -v jq >/dev/null 2>&1; then
    local tag
    tag="$(gh api repos/actions/runner/releases/latest 2>/dev/null | jq -r '.tag_name // empty' || true)"
    if [[ -n "${tag}" ]]; then
      RUNNER_VERSION="${tag#v}"
      log_info "Resolved runner version from API: ${RUNNER_VERSION}"
      return 0
    fi
  fi

  RUNNER_VERSION="${DEFAULT_RUNNER_VERSION}"
  log_warn "Falling back to default runner version: ${RUNNER_VERSION}"
}

linux_arch_suffix() {
  case "$(uname -m)" in
    arm64|aarch64) printf 'arm64' ;;
    x86_64|amd64) printf 'x64' ;;
    *) fail "Unsupported Linux architecture: $(uname -m)" ;;
  esac
}

ensure_runner_token() {
  [[ -n "${RUNNER_TOKEN}" ]] && return 0

  gh_auth_available || fail "gh auth required to create runner token. Run: gh auth login"
  validate_repo "${REPO}"

  RUNNER_TOKEN="$(gh api --method POST "repos/${REPO}/actions/runners/registration-token" --jq '.token' 2>/dev/null || true)"
  [[ -n "${RUNNER_TOKEN}" ]] || fail "Failed to create registration token for ${REPO}."
}

download_runner() {
  mkdir -p "${RUNNER_DIR}"

  if [[ -x "${RUNNER_DIR}/config.sh" ]]; then
    log_info "Runner files already present in ${RUNNER_DIR}; skip download."
    return 0
  fi

  [[ "${SKIP_DOWNLOAD}" == "false" ]] || fail "Runner files missing and --skip-download was provided."

  require_cmd curl
  resolve_runner_version

  local arch package_name package_url archive_path
  arch="$(linux_arch_suffix)"
  package_name="actions-runner-linux-${arch}-${RUNNER_VERSION}.tar.gz"
  package_url="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${package_name}"
  archive_path="${RUNNER_DIR}/${package_name}"

  log_info "Downloading GitHub Actions runner ${RUNNER_VERSION} (${arch})"
  curl -fsSL "${package_url}" -o "${archive_path}" || fail "Failed to download ${package_url}"

  tar -xzf "${archive_path}" -C "${RUNNER_DIR}" || fail "Failed to extract runner archive"
  rm -f "${archive_path}"

  chmod +x "${RUNNER_DIR}/config.sh" "${RUNNER_DIR}/run.sh" "${RUNNER_DIR}/svc.sh" >/dev/null 2>&1 || true
}

configure_runner() {
  [[ -x "${RUNNER_DIR}/config.sh" ]] || fail "Missing ${RUNNER_DIR}/config.sh"

  local existing_name=""
  if [[ -f "${RUNNER_DIR}/.runner" ]] && command -v jq >/dev/null 2>&1; then
    existing_name="$(jq -r '.AgentName // .agentName // empty' "${RUNNER_DIR}/.runner" 2>/dev/null || true)"
  fi

  if [[ -n "${existing_name}" && "${REPLACE}" != "true" ]]; then
    if [[ "${existing_name}" == "${RUNNER_NAME}" ]]; then
      log_info "Runner already configured with same name (${RUNNER_NAME}); skip config."
      return 0
    fi
    fail "Runner already configured as '${existing_name}'. Use --replace to reconfigure."
  fi

  ensure_runner_token

  log_info "Configuring runner '${RUNNER_NAME}' for ${REPO}"
  pushd "${RUNNER_DIR}" >/dev/null || fail "Cannot access ${RUNNER_DIR}"

  local cmd=(
    ./config.sh
    --unattended
    --url "${GITHUB_URL}/${REPO}"
    --token "${RUNNER_TOKEN}"
    --name "${RUNNER_NAME}"
    --labels "${RUNNER_LABELS}"
    --work "${WORK_DIR}"
  )

  if [[ "${REPLACE}" == "true" ]]; then
    cmd+=(--replace)
  fi

  "${cmd[@]}" >/dev/null || {
    popd >/dev/null || true
    fail "Runner configuration failed."
  }

  popd >/dev/null || true
}

setup_service() {
  [[ "${SKIP_SERVICE}" == "false" ]] || {
    log_warn "Skipping service setup/start."
    return 0
  }

  [[ -x "${RUNNER_DIR}/svc.sh" ]] || {
    if [[ "${STRICT}" == "true" ]]; then
      fail "svc.sh not found; strict mode requires successful service setup."
    fi
    log_warn "svc.sh not found; skip service setup."
    return 0
  }

  pushd "${RUNNER_DIR}" >/dev/null || fail "Cannot access ${RUNNER_DIR}"

  local started="false"

  if command -v sudo >/dev/null 2>&1; then
    sudo ./svc.sh install >/dev/null 2>&1 || true
    if sudo ./svc.sh start >/dev/null 2>&1; then
      started="true"
    fi
  fi

  if [[ "${started}" != "true" ]]; then
    ./svc.sh install >/dev/null 2>&1 || true
    if ./svc.sh start >/dev/null 2>&1; then
      started="true"
    fi
  fi

  popd >/dev/null || true

  if [[ "${started}" != "true" ]]; then
    if [[ "${STRICT}" == "true" ]]; then
      fail "Failed to start runner service in strict mode."
    fi
    log_warn "Failed to start runner service. You can run manually: ${RUNNER_DIR}/run.sh"
    return 0
  fi

  log_info "Runner service started."
}

verify_runner_registration() {
  [[ -f "${RUNNER_DIR}/.runner" ]] || {
    if [[ "${STRICT}" == "true" ]]; then
      fail "Local .runner file not found in strict mode."
    fi
    log_warn "Local .runner file not found."
    return 0
  }

  if gh_auth_available && command -v jq >/dev/null 2>&1; then
    local response
    response="$(gh api "repos/${REPO}/actions/runners?per_page=100" 2>/dev/null || true)"
    if [[ -n "${response}" ]] && printf '%s' "${response}" | jq -e --arg name "${RUNNER_NAME}" '.runners[]? | select(.name==$name)' >/dev/null; then
      log_info "Remote runner registration found in GitHub."
      return 0
    fi

    if [[ "${STRICT}" == "true" ]]; then
      fail "Runner not visible via GitHub API in strict mode."
    fi
    log_warn "Runner is not visible via GitHub API yet (eventual consistency)."
  fi
}

print_summary() {
  printf 'Runner setup completed.\n'
  printf '  Repo: %s\n' "${REPO}"
  printf '  URL: %s\n' "${GITHUB_URL}/${REPO}"
  printf '  Name: %s\n' "${RUNNER_NAME}"
  printf '  Labels: %s\n' "${RUNNER_LABELS}"
  printf '  Runner dir: %s\n' "${RUNNER_DIR}"
  printf '\n'
  printf 'Useful commands:\n'
  printf '  %s/run.sh\n' "${RUNNER_DIR}"
  printf '  %s/svc.sh status\n' "${RUNNER_DIR}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --github-url)
      GITHUB_URL="$(trim_slash "${2:-}")"
      shift 2
      ;;
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --runner-token)
      RUNNER_TOKEN="${2:-}"
      shift 2
      ;;
    --name)
      RUNNER_NAME="${2:-}"
      shift 2
      ;;
    --labels)
      RUNNER_LABELS="${2:-}"
      shift 2
      ;;
    --runner-root)
      RUNNER_ROOT="${2:-}"
      shift 2
      ;;
    --runner-dir)
      RUNNER_DIR="${2:-}"
      shift 2
      ;;
    --work-dir)
      WORK_DIR="${2:-}"
      shift 2
      ;;
    --runner-version)
      RUNNER_VERSION="${2:-}"
      shift 2
      ;;
    --skip-download)
      SKIP_DOWNLOAD="true"
      shift
      ;;
    --skip-service)
      SKIP_SERVICE="true"
      shift
      ;;
    --replace)
      REPLACE="true"
      shift
      ;;
    --strict)
      STRICT="true"
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

detect_repo_from_git_remote
[[ -n "${REPO}" ]] || fail "Missing --repo and could not auto-detect from git remote."
validate_repo "${REPO}"

if [[ -z "${RUNNER_NAME}" ]]; then
  RUNNER_NAME="github-runner-$(slugify "$(hostname -s)")-$(slugify "${REPO}")-linux"
fi

if [[ -z "${RUNNER_DIR}" ]]; then
  RUNNER_DIR="${RUNNER_ROOT}/$(slugify "${REPO}")-linux"
fi

mkdir -p "${RUNNER_DIR}"

download_runner
configure_runner
setup_service
verify_runner_registration
print_summary

#!/usr/bin/env bats

SCRIPT="/Users/biendh/StudioProjects/meup/tools/linux/git/runner/gitlab/manage_gitlab_runner.sh"

setup() {
  export TEST_TMP
  TEST_TMP="$(mktemp -d)"
  export HOME="${TEST_TMP}/home"
  export PATH="${TEST_TMP}/bin:/usr/bin:/bin"

  mkdir -p "${HOME}/.gitlab-runner" "${TEST_TMP}/bin"

  cat > "${HOME}/.gitlab-runner/config.toml" <<'CFG'
[[runners]]
  name = "runner-one"
  id = 111
  url = "https://gitlab.com"
  executor = "shell"

[[runners]]
  name = "runner-two"
  id = 222
  url = "https://gitlab.com"
  executor = "shell"
CFG

  cat > "${TEST_TMP}/bin/gitlab-runner" <<'MOCK'
#!/usr/bin/env bash
if [[ "${1:-}" == "unregister" ]]; then
  exit 0
fi
if [[ "${1:-}" == "install" || "${1:-}" == "start" || "${1:-}" == "stop" ]]; then
  exit 0
fi
exit 0
MOCK
  chmod +x "${TEST_TMP}/bin/gitlab-runner"

  cat > "${TEST_TMP}/bin/glab" <<'MOCK'
#!/usr/bin/env bash
if [[ "${1:-}" == "auth" && "${2:-}" == "status" ]]; then
  exit 0
fi
if [[ "${1:-}" == "api" ]]; then
  if [[ "${2:-}" == runners/* && "${3:-}" == "-X" && "${4:-}" == "DELETE" ]]; then
    exit 0
  fi
  if [[ "${2:-}" == runners/* ]]; then
    printf '{"status":"online","active":true,"paused":false,"tag_list":["linux"]}'
    exit 0
  fi
fi
exit 1
MOCK
  chmod +x "${TEST_TMP}/bin/glab"
}

teardown() {
  rm -rf "${TEST_TMP}"
}

@test "list --json returns runner_count" {
  run bash "${SCRIPT}" list --json
  [ "$status" -eq 0 ]
  [[ "$output" == *'"command":"list"'* ]]
  [[ "$output" == *'"runner_count":2'* ]]
}

@test "delete-one updates config and writes backup" {
  run bash "${SCRIPT}" delete-one --name runner-one --yes --strict --skip-service-restart --json
  [ "$status" -eq 0 ]
  [[ "$output" == *'"command":"delete-one"'* ]]

  run grep -q 'name = "runner-one"' "${HOME}/.gitlab-runner/config.toml"
  [ "$status" -ne 0 ]

  run bash -lc "ls '${HOME}/.gitlab-runner'/config.toml.bak.* >/dev/null"
  [ "$status" -eq 0 ]
}

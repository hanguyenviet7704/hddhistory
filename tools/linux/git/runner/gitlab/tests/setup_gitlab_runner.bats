#!/usr/bin/env bats

SCRIPT="/Users/biendh/StudioProjects/meup/tools/linux/git/runner/gitlab/setup_gitlab_runner.sh"

setup() {
  export TEST_TMP
  TEST_TMP="$(mktemp -d)"
  export HOME="${TEST_TMP}/home"
  export PATH="${TEST_TMP}/bin:/usr/bin:/bin"

  mkdir -p "${HOME}/.gitlab-runner" "${TEST_TMP}/bin"

  cat > "${HOME}/.gitlab-runner/config.toml" <<'CFG'
[[runners]]
  name = "runner-existing"
  id = 333
  url = "https://gitlab.com"
  executor = "shell"
  [runners.cache]
CFG

  cat > "${TEST_TMP}/bin/gitlab-runner" <<'MOCK'
#!/usr/bin/env bash
case "${1:-}" in
  register|verify|stop|install|start)
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
MOCK
  chmod +x "${TEST_TMP}/bin/gitlab-runner"
}

teardown() {
  rm -rf "${TEST_TMP}"
}

@test "invalid boolean option fails fast" {
  run bash "${SCRIPT}" --locked maybe --skip-install --skip-service --name runner-existing
  [ "$status" -ne 0 ]
}

@test "existing runner path injection creates backup" {
  run bash "${SCRIPT}" --name runner-existing --skip-install --skip-service --strict
  [ "$status" -eq 0 ]

  run grep -q 'environment = \["PATH=' "${HOME}/.gitlab-runner/config.toml"
  [ "$status" -eq 0 ]

  run bash -lc "ls '${HOME}/.gitlab-runner'/config.toml.bak.* >/dev/null"
  [ "$status" -eq 0 ]
}

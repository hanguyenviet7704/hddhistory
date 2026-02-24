#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNTIME_DIR="${ROOT_DIR}/build/ci"
RUNTIME_ENV="${RUNTIME_DIR}/runtime.env"

mkdir -p "${RUNTIME_DIR}" "${ROOT_DIR}/.env" "${ROOT_DIR}/.info/key"
: > "${RUNTIME_ENV}"
chmod 600 "${RUNTIME_ENV}"

log() {
  printf '[bootstrap-secrets] %s\n' "$1"
}

quote_for_env() {
  local value="$1"
  value=${value//"'"/"'\\''"}
  printf "'%s'" "$value"
}

append_runtime_env() {
  local key="$1"
  local value="$2"
  printf "%s=%s\n" "$key" "$(quote_for_env "$value")" >> "${RUNTIME_ENV}"
}

write_value_to_file() {
  local value="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"

  if [[ -f "$value" ]]; then
    cat "$value" > "$target"
  else
    printf '%s\n' "$value" > "$target"
  fi

  chmod 600 "$target"
}

get_var_value() {
  local var_name="$1"
  printf '%s' "${!var_name-}"
}

write_secret_target() {
  local file_var="$1"
  local content_var="$2"
  local target="$3"

  local file_value
  local content_value
  file_value="$(get_var_value "$file_var")"
  content_value="$(get_var_value "$content_var")"

  if [[ -n "$file_value" ]]; then
    write_value_to_file "$file_value" "$target"
    log "Wrote $(realpath --relative-to="$ROOT_DIR" "$target" 2>/dev/null || echo "$target") from $file_var"
    return 0
  fi

  if [[ -n "$content_value" ]]; then
    write_value_to_file "$content_value" "$target"
    log "Wrote $(realpath --relative-to="$ROOT_DIR" "$target" 2>/dev/null || echo "$target") from $content_var"
    return 0
  fi

  return 1
}

write_env_file() {
  local flavor="$1"
  local target_file="$2"
  local file_var="MEUP_ENV_${flavor}_FILE"
  local content_var="MEUP_ENV_${flavor}_CONTENT"

  if write_secret_target "$file_var" "$content_var" "$target_file"; then
    append_runtime_env "MEUP_ENV_${flavor}_PATH" "$target_file"
  elif [[ -f "$target_file" ]]; then
    log "Using existing ${target_file#${ROOT_DIR}/}"
    append_runtime_env "MEUP_ENV_${flavor}_PATH" "$target_file"
  else
    log "No runtime override for ${target_file#${ROOT_DIR}/}"
  fi
}

write_env_file "DEV" "${ROOT_DIR}/.env/.env.dev"
write_env_file "STG" "${ROOT_DIR}/.env/.env.stg"
write_env_file "PROD" "${ROOT_DIR}/.env/.env.prod"

if write_secret_target "MEUP_LOCALIZATION_SA_PATH" "MEUP_LOCALIZATION_SA_JSON" "${ROOT_DIR}/.info/key/ci-localization-sa.json"; then
  append_runtime_env "LOCALIZATION_SA_PATH" "${ROOT_DIR}/.info/key/ci-localization-sa.json"
elif [[ -n "${LOCALIZATION_SA_JSON:-}" ]]; then
  write_value_to_file "${LOCALIZATION_SA_JSON}" "${ROOT_DIR}/.info/key/ci-localization-sa.json"
  append_runtime_env "LOCALIZATION_SA_PATH" "${ROOT_DIR}/.info/key/ci-localization-sa.json"
  log "Wrote .info/key/ci-localization-sa.json from LOCALIZATION_SA_JSON"
fi

if write_secret_target "MEUP_PLAYSTORE_JSON_FILE" "MEUP_PLAYSTORE_JSON" "${ROOT_DIR}/.info/key/ci-fastlane-playstore.json"; then
  append_runtime_env "MEUP_PLAYSTORE_JSON_PATH" "${ROOT_DIR}/.info/key/ci-fastlane-playstore.json"
fi

if write_secret_target "MEUP_APPSTORE_P8_FILE" "MEUP_APPSTORE_P8" "${ROOT_DIR}/.info/key/ci-appstore-key.p8"; then
  append_runtime_env "MEUP_APPSTORE_P8_PATH" "${ROOT_DIR}/.info/key/ci-appstore-key.p8"
fi

if [[ -n "${MEUP_FIREBASE_TOKEN:-}" ]]; then
  append_runtime_env "FIREBASE_TOKEN" "${MEUP_FIREBASE_TOKEN}"
fi

if [[ -n "${MEUP_APPSTORE_ISSUER_ID:-}" ]]; then
  append_runtime_env "MEUP_APPSTORE_ISSUER_ID" "${MEUP_APPSTORE_ISSUER_ID}"
fi

if [[ -n "${MEUP_APPSTORE_KEY_ID:-}" ]]; then
  append_runtime_env "MEUP_APPSTORE_KEY_ID" "${MEUP_APPSTORE_KEY_ID}"
fi

log "Runtime bootstrap complete. Generated build/ci/runtime.env"

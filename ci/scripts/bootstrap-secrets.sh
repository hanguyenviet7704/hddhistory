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
  local file_var="ENV_${flavor}_FILE"
  local content_var="ENV_${flavor}_CONTENT"

  if write_secret_target "$file_var" "$content_var" "$target_file"; then
    append_runtime_env "ENV_${flavor}_PATH" "$target_file"
  elif [[ -f "$target_file" ]]; then
    log "Using existing ${target_file#${ROOT_DIR}/}"
    append_runtime_env "ENV_${flavor}_PATH" "$target_file"
  else
    log "No runtime override for ${target_file#${ROOT_DIR}/}"
  fi
}

write_env_file "DEV" "${ROOT_DIR}/.env/.env.dev"
write_env_file "STG" "${ROOT_DIR}/.env/.env.stg"
write_env_file "PROD" "${ROOT_DIR}/.env/.env.prod"

if write_secret_target "LOCALIZATION_SA_PATH" "LOCALIZATION_SA_JSON" "${ROOT_DIR}/.info/key/ci-localization-sa.json"; then
  append_runtime_env "LOCALIZATION_SA_PATH" "${ROOT_DIR}/.info/key/ci-localization-sa.json"
fi

if write_secret_target "PLAYSTORE_JSON_FILE" "PLAYSTORE_JSON" "${ROOT_DIR}/.info/key/ci-fastlane-playstore.json"; then
  append_runtime_env "PLAYSTORE_JSON_PATH" "${ROOT_DIR}/.info/key/ci-fastlane-playstore.json"
fi

if write_secret_target "APPSTORE_P8_FILE" "APPSTORE_P8" "${ROOT_DIR}/.info/key/ci-appstore-key.p8"; then
  append_runtime_env "APPSTORE_P8_PATH" "${ROOT_DIR}/.info/key/ci-appstore-key.p8"
fi

if [[ -n "${FIREBASE_TOKEN:-}" ]]; then
  append_runtime_env "FIREBASE_TOKEN" "${FIREBASE_TOKEN}"
elif [[ -f "${ROOT_DIR}/.info/app/firebase.json" ]] && command -v jq >/dev/null 2>&1; then
  firebase_token_from_file="$(jq -r '.firebaseToken // empty' "${ROOT_DIR}/.info/app/firebase.json" 2>/dev/null || true)"
  if [[ -n "${firebase_token_from_file}" ]]; then
    append_runtime_env "FIREBASE_TOKEN" "${firebase_token_from_file}"
    log "Loaded FIREBASE_TOKEN from .info/app/firebase.json"
  fi
fi

if [[ -n "${APPSTORE_ISSUER_ID:-}" ]]; then
  append_runtime_env "APPSTORE_ISSUER_ID" "${APPSTORE_ISSUER_ID}"
fi

if [[ -n "${APPSTORE_KEY_ID:-}" ]]; then
  append_runtime_env "APPSTORE_KEY_ID" "${APPSTORE_KEY_ID}"
fi

log "Runtime bootstrap complete. Generated build/ci/runtime.env"

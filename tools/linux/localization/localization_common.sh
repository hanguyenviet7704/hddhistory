#!/bin/bash

# Localization-specific configuration helper functions
# This extends the common configuration with localization-specific utilities

# Source the main common configuration once
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -z "${PROJECT_ROOT:-}" ]]; then
    # shellcheck source=../common/common.sh
    source "${SCRIPT_DIR}/../common/common.sh" || {
        echo "❌ Failed to load common configuration"
        exit 1
    }
fi

# Localization configuration file
readonly LOCALIZATION_CONFIG="${INFO_APP_DIR}/localization.json"

# Localization configuration functions
get_localization_config() {
    local key="$1"
    if [[ -f "$LOCALIZATION_CONFIG" ]]; then
        jq -r "$key // empty" "$LOCALIZATION_CONFIG" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Google Sheets configuration (active + legacy for migration)
get_active_sheet_id() {
    get_localization_config '.googleSheets.active.sheetId'
}

get_active_sheet_gids() {
    get_localization_config '.googleSheets.active.sheetGids[]' | tr '\n' ' '
}

get_active_sheet_tabs_json() {
    local value
    value=$(get_localization_config '.googleSheets.active.tabs')
    if [[ -z "$value" || "$value" == "null" ]]; then
        echo "[]"
    else
        echo "$value"
    fi
}

get_active_sheet_column() {
    local column="$1"
    get_localization_config ".googleSheets.active.columns.${column}"
}

get_legacy_sheet_id() {
    get_localization_config '.googleSheets.legacy.sheetId'
}

get_legacy_sheet_gids() {
    get_localization_config '.googleSheets.legacy.sheetGids[]' | tr '\n' ' '
}

get_legacy_sheet_column() {
    local column="$1"
    get_localization_config ".googleSheets.legacy.columns.${column}"
}

get_localization_sa_path() {
    local path
    path=$(get_localization_config '.googleSheets.auth.serviceAccountPath')
    if [[ -n "$path" && "$path" != "null" ]]; then
        get_relative_path "$path"
    else
        echo ""
    fi
}

get_localization_sa_path_env() {
    local env_name
    env_name=$(get_localization_config '.googleSheets.auth.serviceAccountPathEnv')
    if [[ -n "$env_name" && "$env_name" != "null" ]]; then
        echo "$env_name"
    else
        echo "LOCALIZATION_SA_PATH"
    fi
}

get_localization_sa_json_env() {
    local env_name
    env_name=$(get_localization_config '.googleSheets.auth.serviceAccountJsonEnv')
    if [[ -n "$env_name" && "$env_name" != "null" ]]; then
        echo "$env_name"
    else
        echo "LOCALIZATION_SA_JSON"
    fi
}

# Language configuration
get_language_mapping() {
    local language="$1"
    get_localization_config ".languages.mapping.${language}"
}

get_supported_languages() {
    get_localization_config '.languages.supported[]' | tr '\n' ' '
}

get_default_language() {
    get_localization_config '.languages.default'
}

# Path configuration
get_i18n_dir() {
    local path
    path=$(get_localization_config '.paths.i18nDir')
    get_relative_path "$path"
}

get_template_dir() {
    local path
    path=$(get_localization_config '.paths.templateDir')
    get_relative_path "$path"
}

get_temp_dir() {
    local path
    path=$(get_localization_config '.paths.tempDir')
    get_relative_path "$path"
}

get_legacy_arb_dir() {
    local path
    path=$(get_localization_config '.paths.legacyArbDir')
    get_relative_path "$path"
}

get_slang_config_path() {
    local path
    path=$(get_localization_config '.paths.slangConfig')
    get_relative_path "$path"
}

get_l10n_output_dir() {
    local path
    path=$(get_localization_config '.paths.outputDir')
    get_relative_path "$path"
}

# Generation configuration
get_generation_author() {
    get_localization_config '.generation.author'
}

get_generation_encoding() {
    get_localization_config '.generation.encoding'
}

# Validation functions
validate_localization_config() {
    log_step "Validating localization configuration..."

    if [[ ! -f "$LOCALIZATION_CONFIG" ]]; then
        log_error "Localization configuration not found: $LOCALIZATION_CONFIG"
        return 1
    fi

    local sheet_id
    sheet_id=$(get_active_sheet_id)
    local i18n_dir
    i18n_dir=$(get_i18n_dir)

    if [[ -z "$sheet_id" ]]; then
        log_error "Active sheet ID not configured in localization.json"
        return 1
    fi

    if [[ -z "$i18n_dir" ]]; then
        log_error "i18n directory not configured in localization.json"
        return 1
    fi

    log_success "Localization configuration is valid"
    return 0
}

# Show localization configuration summary
show_localization_config() {
    echo
    log_step "Localization Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Active Sheet ID: $(get_active_sheet_id)"
    echo "Active Sheet GIDs: $(get_active_sheet_gids)"
    echo "Active Sheet Tabs: $(get_active_sheet_tabs_json | jq -r '.[].module' 2>/dev/null | tr '\n' ',' | sed 's/,$//')"
    echo "Service Account Path: $(get_localization_sa_path)"
    echo "Service Account Env (path/json): $(get_localization_sa_path_env)/$(get_localization_sa_json_env)"
    echo "Legacy Sheet ID: $(get_legacy_sheet_id)"
    echo "Legacy Sheet GIDs: $(get_legacy_sheet_gids)"
    echo "Default Language: $(get_default_language)"
    echo "Supported Languages: $(get_supported_languages)"
    echo "i18n Directory: $(get_i18n_dir)"
    echo "Temp Directory: $(get_temp_dir)"
    echo "Template Directory: $(get_template_dir)"
    echo "Slang Config: $(get_slang_config_path)"
    echo "Generated Output: $(get_l10n_output_dir)"
    echo "Generation Author: $(get_generation_author)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
}

# Create Python configuration file for scripts
create_python_config() {
    local config_file="$PROJECT_ROOT/.localization_config.json"

    cat > "$config_file" << EOF
{
  "project_root": "$PROJECT_ROOT",
  "localization_config_path": "$(get_relative_path "$LOCALIZATION_CONFIG")",
  "active_sheet": {
    "sheet_id": "$(get_active_sheet_id)",
    "sheet_gids": [$(get_active_sheet_gids | sed 's/ /,/g' | sed 's/,$//')],
    "tabs": $(get_active_sheet_tabs_json),
    "columns": $(get_localization_config '.googleSheets.active.columns')
  },
  "legacy_sheet": {
    "sheet_id": "$(get_legacy_sheet_id)",
    "sheet_gids": [$(get_legacy_sheet_gids | sed 's/ /,/g' | sed 's/,$//')],
    "columns": $(get_localization_config '.googleSheets.legacy.columns')
  },
  "auth": {
    "service_account_path": "$(get_localization_sa_path)",
    "service_account_path_env": "$(get_localization_sa_path_env)",
    "service_account_json_env": "$(get_localization_sa_json_env)"
  },
  "languages": {
    "mapping": $(get_localization_config '.languages.mapping'),
    "supported": $(get_localization_config '.languages.supported'),
    "default": "$(get_default_language)"
  },
  "paths": {
    "i18n_dir": "$(get_i18n_dir)",
    "temp_dir": "$(get_temp_dir)",
    "template_dir": "$(get_template_dir)",
    "legacy_arb_dir": "$(get_legacy_arb_dir)",
    "slang_config": "$(get_slang_config_path)",
    "output_dir": "$(get_l10n_output_dir)"
  },
  "generation": {
    "author": "$(get_generation_author)",
    "encoding": "$(get_generation_encoding)"
  }
}
EOF

    echo "$config_file"
}

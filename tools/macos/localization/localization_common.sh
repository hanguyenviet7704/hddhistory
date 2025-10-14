#!/bin/bash

# Localization-specific configuration helper functions
# This extends the common configuration with localization-specific utilities

# Source the main common configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/common.sh" || {
    echo "❌ Failed to load common configuration"
    exit 1
}

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

# Google Sheets configuration
get_sheet_id() {
    get_localization_config '.googleSheets.sheetId'
}

get_sheet_gids() {
    get_localization_config '.googleSheets.sheetGids[]' | tr '\n' ' '
}

get_sheet_columns() {
    local column="$1"
    get_localization_config ".googleSheets.columns.${column}"
}

# Language configuration
get_language_mapping() {
    local language="$1"
    get_localization_config ".languages.mapping.${language}"
}

get_default_language() {
    get_localization_config '.languages.default'
}

# Path configuration
get_arb_dir() {
    local path=$(get_localization_config '.paths.arbDir')
    get_relative_path "$path"
}

get_module_dir() {
    local path=$(get_localization_config '.paths.moduleDir')
    get_relative_path "$path"
}

get_app_dir() {
    local path=$(get_localization_config '.paths.appDir')
    get_relative_path "$path"
}

get_l10n_config_path() {
    local path=$(get_localization_config '.paths.l10nConfig')
    get_relative_path "$path"
}

get_l10n_output_dir() {
    local path=$(get_localization_config '.paths.outputDir')
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

    # Check required fields
    local sheet_id=$(get_sheet_id)
    local arb_dir=$(get_arb_dir)

    if [[ -z "$sheet_id" ]]; then
        log_error "Sheet ID not configured in localization.json"
        return 1
    fi

    if [[ -z "$arb_dir" ]]; then
        log_error "ARB directory not configured in localization.json"
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
    echo "Sheet ID: $(get_sheet_id)"
    echo "Sheet GIDs: $(get_sheet_gids)"
    echo "Default Language: $(get_default_language)"
    echo "ARB Directory: $(get_arb_dir)"
    echo "Module Directory: $(get_module_dir)"
    echo "App Directory: $(get_app_dir)"
    echo "L10n Config: $(get_l10n_config_path)"
    echo "Output Directory: $(get_l10n_output_dir)"
    echo "Generation Author: $(get_generation_author)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
}

# Create Python configuration file for scripts
create_python_config() {
    local config_file="$PROJECT_ROOT/.localization_config.json"

    cat > "$config_file" << EOF
{
    "sheet_id": "$(get_sheet_id)",
    "sheet_gids": [$(get_sheet_gids | sed 's/ /,/g' | sed 's/,$//')],
    "columns": {
        "screen": "$(get_sheet_columns screen)",
        "key": "$(get_sheet_columns key)",
        "action": "$(get_sheet_columns action)",
        "en": "$(get_sheet_columns en)",
        "vi": "$(get_sheet_columns vi)",
        "zh": "$(get_sheet_columns zh)"
    },
    "languages": {
        "mapping": $(get_localization_config '.languages.mapping'),
        "default": "$(get_default_language)"
    },
    "paths": {
        "base_dir": "$PROJECT_ROOT",
        "arb_dir": "$(get_arb_dir)",
        "module_dir": "$(get_module_dir)",
        "app_dir": "$(get_app_dir)"
    },
    "generation": {
        "author": "$(get_generation_author)",
        "encoding": "$(get_generation_encoding)"
    }
}
EOF

    echo "$config_file"
}
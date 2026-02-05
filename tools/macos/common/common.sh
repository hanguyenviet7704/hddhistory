#!/bin/bash

# Common configuration helper functions for Artlexis Flutter project
# This library provides centralized access to all project configurations

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Project paths
readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
readonly INFO_DIR="${PROJECT_ROOT}/.info"
readonly INFO_APP_DIR="${INFO_DIR}/app"
readonly INFO_DIST_DIR="${INFO_DIR}/distribution"
readonly INFO_KEY_DIR="${INFO_DIR}/key"
readonly INFO_CACHE_DIR="${INFO_DIR}/cache"
readonly VERSION_MANAGER_CACHE="${INFO_CACHE_DIR}/version_manager.cache"

# Configuration files (updated paths)
readonly APP_CONFIG="${INFO_APP_DIR}/app.json"
readonly FIREBASE_CONFIG="${INFO_APP_DIR}/firebase.json"
readonly BUILD_CONFIG="${INFO_APP_DIR}/build.json"
readonly PATHS_CONFIG="${INFO_APP_DIR}/paths.json"

# Distribution data files
readonly TESTER_LIST_FILE="${INFO_DIST_DIR}/tester_list.txt"
readonly TESTER_GROUP_FILE="${INFO_DIST_DIR}/tester_group.txt"
readonly RELEASE_NOTE_FILE="${INFO_DIST_DIR}/release_note.txt"
readonly TEST_DEVICE_FILE="${INFO_DIST_DIR}/test_device.txt"
readonly TEST_PASSWORD_FILE="${INFO_DIST_DIR}/test_password.txt"

# Logging functions
log_info() {
    printf "${BLUE}ℹ️  %s${NC}\n" "$1"
}

log_success() {
    printf "${GREEN}✅ %s${NC}\n" "$1"
}

log_warning() {
    printf "${YELLOW}⚠️  %s${NC}\n" "$1"
}

log_error() {
    printf "${RED}❌ %s${NC}\n" "$1"
}

log_step() {
    printf "${PURPLE}🔸 %s${NC}\n" "$1"
}

# Validation functions
validate_flavor() {
    local flavor="$1"
    if [[ "$flavor" != "dev" && "$flavor" != "stg" && "$flavor" != "prod" ]]; then
        log_error "Invalid flavor: $flavor"
        log_info "Supported flavors: dev, stg, prod"
        return 1
    fi
    return 0
}

validate_platform() {
    local platform="$1"
    if [[ "$platform" != "android" && "$platform" != "ios" ]]; then
        log_error "Invalid platform: $platform"
        log_info "Supported platforms: android, ios"
        return 1
    fi
    return 0
}

# Get domain/BASE_URL from .env file for a given flavor
get_domain_from_env() {
    local flavor="$1"
    local env_file="${PROJECT_ROOT}/.env/.env.${flavor}"

    if [[ -f "$env_file" ]]; then
        local domain=$(grep "^BASE_URL=" "$env_file" | cut -d'=' -f2)
        echo "$domain"
    else
        echo "N/A"
    fi
}

# Generate release notes with domain replacement and platform information
# Parameters:
#   $1 - flavor (dev|stg|prod)
#   $2 - version
#   $3 - build_type (e.g., APK, IPA, App Bundle)
#   $4 - platform (e.g., "Android", "iOS", "Android (Linux)")
generate_release_notes() {
    local flavor="$1"
    local version="$2"
    local build_type="$3"
    local platform="$4"

    # Get domain from .env file
    local domain=$(get_domain_from_env "$flavor")

    # Use centralized function - checks text file first, then JSON template
    RELEASE_NOTES=$(get_all_release_notes "$flavor" "$version")

    # Replace {{domain}} variable in release notes
    RELEASE_NOTES="${RELEASE_NOTES//\{\{domain\}\}/$domain}"

    # Add build type and platform specific information
    RELEASE_NOTES="$RELEASE_NOTES\n\nBuild Type: $build_type\nPlatform: $platform"

    log_info "Generated release notes:"
    printf "${CYAN}%b${NC}\n" "$RELEASE_NOTES"
}

check_required_files() {
    local missing_files=()
    
    [[ ! -f "$APP_CONFIG" ]] && missing_files+=("$APP_CONFIG")
    [[ ! -f "$FIREBASE_CONFIG" ]] && missing_files+=("$FIREBASE_CONFIG")
    [[ ! -f "$BUILD_CONFIG" ]] && missing_files+=("$BUILD_CONFIG")
    [[ ! -f "$PATHS_CONFIG" ]] && missing_files+=("$PATHS_CONFIG")
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_error "Missing required configuration files:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        return 1
    fi
    return 0
}

# JSON reading functions using jq
get_app_config() {
    local key="$1"
    jq -r "$key // empty" "$APP_CONFIG" 2>/dev/null || echo ""
}

get_firebase_config() {
    local key="$1"
    jq -r "$key // empty" "$FIREBASE_CONFIG" 2>/dev/null || echo ""
}

get_build_config() {
    local key="$1"
    jq -r "$key // empty" "$BUILD_CONFIG" 2>/dev/null || echo ""
}

get_paths_config() {
    local key="$1"
    jq -r "$key // empty" "$PATHS_CONFIG" 2>/dev/null || echo ""
}

# App information functions
get_app_name() {
    get_app_config '.appName'
}

get_app_display_name() {
    local flavor="$1"
    if [[ -n "$flavor" ]]; then
        local display_name=$(get_app_config ".flavors.${flavor}.displayName")
        [[ -n "$display_name" && "$display_name" != "null" ]] && echo "$display_name" || get_app_config '.appDisplayName'
    else
        get_app_config '.appDisplayName'
    fi
}

get_app_version() {
    get_app_config '.version'
}

get_build_number() {
    get_app_config '.buildNumber'
}

# Get version from pubspec.yaml
get_pubspec_version() {
    local pubspec_path="${PROJECT_ROOT}/pubspec.yaml"
    if [[ -f "$pubspec_path" ]]; then
        grep "^version:" "$pubspec_path" | sed 's/version: //' | sed 's/#.*//' | xargs
    else
        echo ""
    fi
}

# Platform-specific functions
get_android_package_name() {
    local flavor="$1"
    if [[ -n "$flavor" ]]; then
        local package_name=$(get_app_config ".flavors.${flavor}.android.packageName")
        [[ -n "$package_name" && "$package_name" != "null" ]] && echo "$package_name" || get_app_config '.android.packageName'
    else
        get_app_config '.android.packageName'
    fi
}

get_ios_bundle_id() {
    local flavor="$1"
    if [[ -n "$flavor" ]]; then
        local bundle_id=$(get_app_config ".flavors.${flavor}.ios.bundleId")
        [[ -n "$bundle_id" && "$bundle_id" != "null" ]] && echo "$bundle_id" || get_app_config '.ios.bundleId'
    else
        get_app_config '.ios.bundleId'
    fi
}

get_ios_team_id() {
    get_app_config '.ios.teamId'
}

get_ios_issuer_id() {
    get_app_config '.ios.issuerId'
}

get_ios_key_id() {
    get_app_config '.ios.keyId'
}

get_ios_key_path() {
    local key_path=$(get_app_config '.ios.appStoreConnectAPIKeyPath')
    echo "${PROJECT_ROOT}/${key_path}"
}

# Firebase functions
get_firebase_project_id() {
    local flavor="$1"
    if [[ -n "$flavor" ]]; then
        local project_id=$(get_firebase_config ".projects.${flavor}")
        if [[ -n "$project_id" && "$project_id" != "null" ]]; then
            echo "$project_id"
        else
            # Fallback to legacy single projectId if exists
            get_firebase_config '.projectId'
        fi
    else
        # If no flavor specified, try to get default or first available
        local default_project=$(get_firebase_config '.projectId')
        if [[ -n "$default_project" && "$default_project" != "null" ]]; then
            echo "$default_project"
        else
            # Get the first project from projects object
            get_firebase_config '.projects.dev // .projects.stg // .projects.prod'
        fi
    fi
}

get_firebase_app_id() {
    local platform="$1"
    local flavor="$2"
    get_firebase_config ".apps.${platform}.${flavor}.appId"
}

# Cache management functions
ensure_cache_dir() {
    if [[ ! -d "$INFO_CACHE_DIR" ]]; then
        mkdir -p "$INFO_CACHE_DIR" 2>/dev/null || true
    fi
}

get_cached_version_manager() {
    if [[ -f "$VERSION_MANAGER_CACHE" ]]; then
        cat "$VERSION_MANAGER_CACHE" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

set_cached_version_manager() {
    local version_manager="$1"
    ensure_cache_dir
    echo "$version_manager" > "$VERSION_MANAGER_CACHE" 2>/dev/null || true
}

clear_version_manager_cache() {
    rm -f "$VERSION_MANAGER_CACHE" 2>/dev/null || true
}

# Check if version manager is installed
is_version_manager_available() {
    local vm="$1"
    case "$vm" in
        "puro"|"fvm")
            command -v "$vm" >/dev/null 2>&1
            ;;
        "none")
            return 0  # Always available
            ;;
        *)
            return 1
            ;;
    esac
}

# Detect version manager from configuration
detect_version_manager() {
    local use_cache="${1:-true}"

    # Check cache if enabled
    local cache_enabled=$(get_build_config '.flutter.versionManagerCache // true')
    if [[ "$use_cache" == "true" && "$cache_enabled" != "false" ]]; then
        local cached=$(get_cached_version_manager)
        if [[ -n "$cached" ]] && is_version_manager_available "$cached"; then
            echo "$cached"
            return 0
        fi
    fi

    # Get version manager configuration
    local version_manager_config=$(get_build_config '.flutter.versionManager')

    # Default to "none" if not configured
    if [[ -z "$version_manager_config" || "$version_manager_config" == "null" ]]; then
        set_cached_version_manager "none"
        echo "none"
        return 0
    fi

    # Check if it's an array or string
    local config_type=$(echo "$version_manager_config" | jq -r 'type' 2>/dev/null)

    if [[ "$config_type" == "array" ]]; then
        # Auto-detect mode: check each in order
        local managers=$(echo "$version_manager_config" | jq -r '.[]' 2>/dev/null)
        while IFS= read -r vm; do
            if is_version_manager_available "$vm"; then
                set_cached_version_manager "$vm"
                echo "$vm"
                return 0
            fi
        done <<< "$managers"

        # Nothing found, warn and use system flutter
        log_warning "No version manager found from configuration, using system flutter"
        set_cached_version_manager "none"
        echo "none"
        return 0
    else
        # Force mode: use specific version manager
        local vm="$version_manager_config"
        if is_version_manager_available "$vm"; then
            set_cached_version_manager "$vm"
            echo "$vm"
            return 0
        else
            # Configured but not found, warn but still use it
            log_warning "$vm configured but not found, falling back to system flutter"
            set_cached_version_manager "none"
            echo "none"
            return 0
        fi
    fi
}

# Build configuration functions
get_flutter_command() {
    local use_cache="${SKIP_VERSION_MANAGER_CACHE:-true}"
    local version_manager=$(detect_version_manager "$use_cache")

    case "$version_manager" in
        "puro")
            echo "puro flutter"
            ;;
        "fvm")
            echo "fvm flutter"
            ;;
        "none"|*)
            echo "flutter"
            ;;
    esac
}

get_dart_command() {
    local use_cache="${SKIP_VERSION_MANAGER_CACHE:-true}"
    local version_manager=$(detect_version_manager "$use_cache")

    case "$version_manager" in
        "puro")
            echo "puro dart"
            ;;
        "fvm")
            echo "fvm dart"
            ;;
        "none"|*)
            echo "dart"
            ;;
    esac
}

get_build_args() {
    local platform="$1"
    local build_type="$2"
    get_build_config ".flutter.buildArgs.${platform}.${build_type}[]" | jq -r '.' 2>/dev/null || echo ""
}

get_output_path() {
    local platform="$1"
    local build_type="$2"
    get_build_config ".flutter.outputPaths.${platform}.${build_type}"
}

get_debug_info_path() {
    get_build_config '.flutter.outputPaths.debugInfo'
}

# Environment file functions
get_env_file_path() {
    local flavor="$1"
    get_paths_config ".environment.files.${flavor}"
}

# Distribution functions - Read from JSON config
get_firebase_testers() {
    local flavor="$1"
    get_firebase_config ".distribution.testers.${flavor}[]" | tr '\n' ',' | sed 's/,$//'
}

get_firebase_groups() {
    local flavor="$1"
    get_firebase_config ".distribution.groups.${flavor}[]" | tr '\n' ',' | sed 's/,$//'
}

get_release_notes_template() {
    get_firebase_config '.distribution.releaseNotes.template'
}

# Distribution functions - Read from text files
get_tester_list_from_file() {
    if [[ -f "$TESTER_LIST_FILE" ]]; then
        grep -v '^#' "$TESTER_LIST_FILE" | grep -v '^[[:space:]]*$' | tr '\n' ',' | sed 's/,$//'
    fi
}

get_tester_groups_from_file() {
    if [[ -f "$TESTER_GROUP_FILE" ]]; then
        grep -v '^#' "$TESTER_GROUP_FILE" | grep -v '^[[:space:]]*$' | tr '\n' ',' | sed 's/,$//'
    fi
}

get_release_notes_from_file() {
    if [[ -f "$RELEASE_NOTE_FILE" ]]; then
        cat "$RELEASE_NOTE_FILE"
    fi
}

get_test_devices_from_file() {
    if [[ -f "$TEST_DEVICE_FILE" ]]; then
        grep -v '^#' "$TEST_DEVICE_FILE" | grep -v '^[[:space:]]*$'
    fi
}

get_test_password_from_file() {
    if [[ -f "$TEST_PASSWORD_FILE" ]]; then
        grep -v '^#' "$TEST_PASSWORD_FILE" | grep -v '^[[:space:]]*$' | tr -d '\n'
    fi
}

# Combined distribution functions - Merge JSON and text file data
get_all_testers() {
    local flavor="$1"
    
    # Get testers from JSON config (already comma-separated)
    local json_testers=$(get_firebase_testers "$flavor" 2>/dev/null)
    
    # Get testers from file
    local file_testers=$(get_tester_list_from_file)
    
    # Combine both sources
    local all_testers=""
    [[ -n "$json_testers" ]] && all_testers="$json_testers"
    [[ -n "$file_testers" ]] && all_testers="${all_testers}${all_testers:+,}${file_testers}"
    
    # Output combined testers (duplicates will be removed by Firebase)
    echo "$all_testers"
}

get_all_groups() {
    local flavor="$1"
    
    # Get groups from JSON config (already comma-separated)
    local json_groups=$(get_firebase_groups "$flavor" 2>/dev/null)
    
    # Get groups from file
    local file_groups=$(get_tester_groups_from_file)
    
    # Combine both sources
    local all_groups=""
    [[ -n "$json_groups" ]] && all_groups="$json_groups"
    [[ -n "$file_groups" ]] && all_groups="${all_groups}${all_groups:+,}${file_groups}"
    
    # Output combined groups (duplicates will be removed by Firebase)
    echo "$all_groups"
}

get_all_release_notes() {
    local flavor="$1"
    local version="$2"
    
    # Check if custom release notes exist in file
    local file_notes=$(get_release_notes_from_file)
    
    if [[ -n "$file_notes" ]]; then
        # Use file notes and replace variables
        local date=$(date +"%Y-%m-%d %H:%M:%S")
        echo "$file_notes" | \
            sed "s/{{version}}/$version/g" | \
            sed "s/{{flavor}}/$flavor/g" | \
            sed "s/{{date}}/$date/g"
    else
        # Fallback to template from JSON
        format_release_notes "$flavor" "$version"
    fi
}

# Utility functions
format_release_notes() {
    local flavor="$1"
    local version="$2"
    local template=$(get_release_notes_template)
    local date=$(date +"%Y-%m-%d %H:%M:%S")
    
    echo "$template" | \
        sed "s/{{version}}/$version/g" | \
        sed "s/{{flavor}}/$flavor/g" | \
        sed "s/{{date}}/$date/g"
}

# Path utilities
get_project_root() {
    echo "$PROJECT_ROOT"
}

get_relative_path() {
    local path="$1"
    if [[ "$path" == /* ]]; then
        echo "$path"
    else
        echo "${PROJECT_ROOT}/${path}"
    fi
}

# Validation and setup
validate_environment() {
    log_step "Validating environment..."
    
    # Check for required tools
    local missing_tools=()
    command -v jq >/dev/null 2>&1 || missing_tools+=("jq")
    command -v flutter >/dev/null 2>&1 || missing_tools+=("flutter")
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools:"
        for tool in "${missing_tools[@]}"; do
            echo "  - $tool"
        done
        return 1
    fi
    
    # Check for required configuration files
    if ! check_required_files; then
        return 1
    fi
    
    log_success "Environment validation passed"
    return 0
}

# Show configuration summary
show_config_summary() {
    local flavor="$1"
    local platform="$2"
    
    echo
    log_step "Configuration Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "App Name: $(get_app_display_name "$flavor")"
    echo "Version: $(get_pubspec_version)"
    echo "Flavor: $flavor"
    
    if [[ -n "$platform" ]]; then
        echo "Platform: $platform"
        
        if [[ "$platform" == "android" ]]; then
            echo "Package Name: $(get_android_package_name "$flavor")"
        elif [[ "$platform" == "ios" ]]; then
            echo "Bundle ID: $(get_ios_bundle_id "$flavor")"
            echo "Team ID: $(get_ios_team_id)"
        fi
    fi
    
    echo "Firebase Project: $(get_firebase_project_id "$flavor")"
    echo "Environment File: $(get_env_file_path "$flavor")"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
}

# Entry point validation
main() {
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        log_info "Common configuration library loaded"
        log_info "Usage: source this file from other scripts"
        log_info "Available functions:"
        echo "  - validate_environment"
        echo "  - get_app_name, get_app_version, etc."
        echo "  - get_android_package_name, get_ios_bundle_id"
        echo "  - get_firebase_project_id, get_firebase_app_id"
        echo "  - show_config_summary"
    fi
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

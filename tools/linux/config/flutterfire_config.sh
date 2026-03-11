#!/bin/bash

# Enhanced Firebase Configuration Script with Centralized Configuration (Linux)
# This script configures Firebase using configuration from .info/ directory

# Navigate to the root directory relative to the current script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../../.."
cd "${ROOT_DIR}" || {
    echo "❌ Failed to navigate to the project root directory."
    exit 1
}

# Load common configuration functions
source "${ROOT_DIR}/tools/linux/common/common.sh" || {
    echo "❌ Failed to load common configuration library."
    echo "Make sure tools/linux/common/common.sh exists and is readable."
    exit 1
}

readonly DEFAULT_FLAVORS=(dev stg prod)
FLAVORS=()
RUN_ALL=false
ARGS_PROVIDED=false

print_usage() {
    echo "Usage: $(basename "$0") [all|dev|stg|prod ...]"
    echo ""
    echo "Arguments:"
    echo "  all                  Configure all flavors (default when omitted)"
    echo "  dev|stg|prod         Configure one or more specific flavors"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "This script configures Firebase for Android only on Linux."
    echo "For iOS setup, use macOS tools."
}

ensure_flutterfire_cli() {
    if ! command -v flutterfire >/dev/null 2>&1; then
        log_error "FlutterFire CLI not found."
        log_info "Install it with: dart pub global activate flutterfire_cli"
        return 1
    fi

    return 0
}

normalize_flavors() {
    local normalized=()
    local flavor

    for flavor in "${FLAVORS[@]}"; do
        case " ${normalized[*]} " in
            *" ${flavor} "*) ;;
            *) normalized+=("$flavor") ;;
        esac
    done

    FLAVORS=("${normalized[@]}")
}

configure_flavor() {
    local flavor="$1"
    local project_id
    local android_package
    local flutterfire_args=()

    if ! validate_flavor "$flavor"; then
        return 1
    fi

    project_id=$(get_firebase_project_id "$flavor")
    android_package=$(get_android_package_name "$flavor")

    if [[ -z "$project_id" || "$project_id" == "null" ]]; then
        log_error "Firebase project ID not found in configuration."
        return 1
    fi

    if [[ -z "$android_package" || "$android_package" == "null" ]]; then
        log_error "Android package name not found for flavor: $flavor"
        return 1
    fi

    show_config_summary "$flavor" "android"
    log_step "Configuring Firebase for ${flavor} environment (Android only)..."

    flutterfire_args=(
        "config"
        "--yes"
        "--overwrite-firebase-options"
        "--project=${project_id}"
        "--out=lib/config/services/firebase/firebase_options_${flavor}.dart"
        "--android-package-name=${android_package}"
        "--android-out=android/app/src/${flavor}/google-services.json"
        "--platforms=android"
    )

    echo
    log_step "Executing FlutterFire configuration command:"
    echo "Command: flutterfire ${flutterfire_args[*]}"
    echo

    if ! flutterfire "${flutterfire_args[@]}"; then
        log_error "Firebase configuration for ${flavor} failed."
        return 1
    fi

    echo
    log_success "Firebase configuration completed successfully!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Project: ${project_id}"
    echo "Flavor: ${flavor}"
    echo "Platform: Android"
    echo "Android Package: ${android_package}"
    echo ""
    echo "Generated files:"
    echo "  - lib/config/services/firebase/firebase_options_${flavor}.dart"
    echo "  - android/app/src/${flavor}/google-services.json"
    echo ""
    echo "Note: iOS configuration is not supported on Linux."
    echo "      For iOS setup, use macOS tools."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    return 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        all)
            ARGS_PROVIDED=true
            RUN_ALL=true
            shift
            ;;
        dev|stg|prod)
            ARGS_PROVIDED=true
            FLAVORS+=("$1")
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

if ! validate_environment; then
    exit 1
fi

if ! ensure_flutterfire_cli; then
    exit 1
fi

if [[ "$RUN_ALL" == "true" || ${#FLAVORS[@]} -eq 0 ]]; then
    FLAVORS=("${DEFAULT_FLAVORS[@]}")
fi

normalize_flavors

if [[ "$ARGS_PROVIDED" == "false" ]]; then
    log_info "No flavor specified. Defaulting to all flavors: ${FLAVORS[*]}"
fi

for flavor in "${FLAVORS[@]}"; do
    if ! configure_flavor "$flavor"; then
        exit 1
    fi
done

echo
if [[ ${#FLAVORS[@]} -gt 1 ]]; then
    log_success "Firebase configuration completed for flavors: ${FLAVORS[*]}"
else
    log_success "Firebase configuration completed for flavor: ${FLAVORS[0]}"
fi

exit 0

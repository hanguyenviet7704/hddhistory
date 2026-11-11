#!/bin/bash

# Enhanced Firebase Configuration Script with Centralized Configuration
# This script configures Firebase using configuration from .info/ directory

# Navigate to the root directory relative to the current script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../../.."
cd "${ROOT_DIR}" || {
    echo "❌ Failed to navigate to the project root directory."
    exit 1
}

# Load common configuration functions
source "${ROOT_DIR}/tools/macos/common/common.sh" || {
    echo "❌ Failed to load common configuration library."
    echo "Make sure tools/macos/common/common.sh exists and is readable."
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
    echo "This script uses centralized configuration from .info/ directory."
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

sync_ios_build_configurations() {
    local flavor="$1"
    local project_id="$2"
    local ios_app_id="$3"
    local firebase_file="${ROOT_DIR}/firebase.json"
    local ios_output="ios/Runner/${flavor}/GoogleService-Info.plist"
    local generated_json
    local temp_file

    if [[ ! -f "$firebase_file" ]]; then
        log_warning "firebase.json not found. Skipping iOS build configuration sync for ${flavor}."
        return 0
    fi

    temp_file="$(mktemp)"

    if ! generated_json="$(
        jq -c \
        --arg flavor "$flavor" \
        --arg project_id "$project_id" \
        --arg app_id "$ios_app_id" \
        --arg file_output "$ios_output" \
        '
        (.flutter |= (. // {}))
        | (.flutter.platforms |= (. // {}))
        | (.flutter.platforms.ios |= (. // {}))
        | (.flutter.platforms.ios.buildConfigurations |= (. // {}))
        | .flutter.platforms.ios.buildConfigurations["Debug-\($flavor)"] = {
            projectId: $project_id,
            appId: $app_id,
            uploadDebugSymbols: true,
            fileOutput: $file_output
          }
        | .flutter.platforms.ios.buildConfigurations["Profile-\($flavor)"] = {
            projectId: $project_id,
            appId: $app_id,
            uploadDebugSymbols: true,
            fileOutput: $file_output
          }
        | .flutter.platforms.ios.buildConfigurations["Release-\($flavor)"] = {
            projectId: $project_id,
            appId: $app_id,
            uploadDebugSymbols: true,
            fileOutput: $file_output
          }
        ' \
        "$firebase_file"
    )"; then
        rm -f "$temp_file"
        log_error "Failed to sync iOS build configurations for ${flavor}."
        return 1
    fi

    printf '%s' "$generated_json" > "$temp_file"

    if cmp -s "$temp_file" "$firebase_file"; then
        rm -f "$temp_file"
        log_info "Debug/Profile/Release iOS build configurations already up to date for ${flavor}."
        return 0
    fi

    mv "$temp_file" "$firebase_file"
    log_info "Registered Debug/Profile/Release iOS build configurations for ${flavor}."
    return 0
}

configure_flavor() {
    local flavor="$1"
    local project_id
    local ios_bundle_id
    local android_package
    local ios_app_id
    local ios_build_config="Debug-${flavor}"
    local flutterfire_args=()

    if ! validate_flavor "$flavor"; then
        return 1
    fi

    project_id=$(get_firebase_project_id "$flavor")
    ios_bundle_id=$(get_ios_bundle_id "$flavor")
    android_package=$(get_android_package_name "$flavor")
    ios_app_id=$(get_firebase_app_id "ios" "$flavor")

    if [[ -z "$project_id" || "$project_id" == "null" ]]; then
        log_error "Firebase project ID not found in configuration."
        return 1
    fi

    if [[ -z "$ios_bundle_id" || "$ios_bundle_id" == "null" ]]; then
        log_error "iOS bundle ID not found for flavor: $flavor"
        return 1
    fi

    if [[ -z "$android_package" || "$android_package" == "null" ]]; then
        log_error "Android package name not found for flavor: $flavor"
        return 1
    fi

    if [[ -z "$ios_app_id" || "$ios_app_id" == "null" ]]; then
        log_error "iOS Firebase app ID not found for flavor: $flavor"
        return 1
    fi

    show_config_summary "$flavor"
    log_step "Configuring Firebase for ${flavor} environment..."

    # Use one deterministic build configuration to avoid CLI prompts, then
    # mirror the mapping to Profile/Release so every flavor works after one run.
    flutterfire_args=(
        "config"
        "--yes"
        "--overwrite-firebase-options"
        "--project=${project_id}"
        "--out=lib/config/services/firebase/firebase_options_${flavor}.dart"
        "--ios-bundle-id=${ios_bundle_id}"
        "--ios-build-config=${ios_build_config}"
        "--ios-out=ios/Runner/${flavor}/GoogleService-Info.plist"
        "--android-package-name=${android_package}"
        "--android-out=android/app/src/${flavor}/google-services.json"
        "--platforms=ios,android"
    )

    echo
    log_step "Executing FlutterFire configuration command:"
    echo "Command: flutterfire ${flutterfire_args[*]}"
    echo

    if ! flutterfire "${flutterfire_args[@]}"; then
        log_error "Firebase configuration for ${flavor} failed."
        return 1
    fi

    if ! sync_ios_build_configurations "$flavor" "$project_id" "$ios_app_id"; then
        return 1
    fi

    echo
    log_success "Firebase configuration completed successfully!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Project: ${project_id}"
    echo "Flavor: ${flavor}"
    echo "iOS Bundle ID: ${ios_bundle_id}"
    echo "Android Package: ${android_package}"
    echo "iOS Build Configs: Debug-${flavor}, Profile-${flavor}, Release-${flavor}"
    echo ""
    echo "Generated files:"
    echo "  - lib/config/services/firebase/firebase_options_${flavor}.dart"
    echo "  - ios/Runner/${flavor}/GoogleService-Info.plist"
    echo "  - android/app/src/${flavor}/google-services.json"
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

#!/bin/bash

# Enhanced IPA Build Script with Centralized Configuration
# This script builds iOS IPA files using configuration from .info/ directory

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

# Initialize variables
FLAVOR=""
OBFUSCATE=true
EXPORT_METHOD="app-store"  # Default to app-store for App Store Connect/TestFlight
UPLOAD_IOS_SYMBOLS=true

# Function to display usage information
show_usage() {
    echo "Usage: $(basename "$0") [dev|stg|prod] [options]"
    echo ""
    echo "Options:"
    echo "  -o, --no-obfuscate        Skip code obfuscation"
    echo "  --export-method METHOD    Export method: app-store (default), ad-hoc, development"
    echo "  --upload-ios-symbols V    Upload iOS dSYM to Crashlytics: true|false (default: true)"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "This script builds iOS IPA files using centralized configuration."
    echo "For distribution, use tools/macos/distribution/distribute_ios.sh"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") dev                         # Build IPA for App Store (default)"
    echo "  $(basename "$0") dev --export-method ad-hoc  # Build for Firebase Distribution"
    echo "  $(basename "$0") dev --no-obfuscate          # Build without obfuscation"
    echo "  $(basename "$0") dev --upload-ios-symbols false  # Skip dSYM upload"
    echo ""
    echo "To build and distribute:"
    echo "  tools/macos/distribution/distribute_ios.sh dev --build-first    # Firebase Distribution"
    exit 0
}

# Resolve GoogleService-Info.plist for a flavor (fallback to default)
get_ios_gsp_path() {
    local flavor="$1"
    local flavored_path="ios/Runner/${flavor}/GoogleService-Info.plist"
    local default_path="ios/Runner/GoogleService-Info.plist"

    if [[ -f "$flavored_path" ]]; then
        echo "$flavored_path"
        return 0
    fi

    if [[ -f "$default_path" ]]; then
        echo "$default_path"
        return 0
    fi

    return 1
}

# Find a directory containing dSYM files for iOS
find_ios_dsym_dir() {
    local archive_dir
    local ipa_dir
    local app_dir
    local search_dirs=()

    archive_dir=$(get_output_path "ios" "archive" 2>/dev/null)
    [[ -z "$archive_dir" ]] && archive_dir="build/ios/archive"

    ipa_dir=$(get_output_path "ios" "ipa" 2>/dev/null)
    [[ -z "$ipa_dir" ]] && ipa_dir="build/ios/ipa"

    app_dir=$(get_output_path "ios" "app" 2>/dev/null)
    [[ -z "$app_dir" ]] && app_dir="build/ios/iphoneos"

    # Prefer the archive dSYMs folder if available
    if [[ -d "$archive_dir/Runner.xcarchive/dSYMs" ]]; then
        echo "$archive_dir/Runner.xcarchive/dSYMs"
        return 0
    fi

    # Build a safe search list
    for dir in "$archive_dir" "$ipa_dir" "$app_dir" "build/ios"; do
        if [[ -d "$dir" ]]; then
            search_dirs+=("$dir")
        fi
    done

    if [[ ${#search_dirs[@]} -eq 0 ]]; then
        return 1
    fi

    local dsym_path
    dsym_path=$(find "${search_dirs[@]}" -name "Runner.app.dSYM" -type d 2>/dev/null | head -n 1)
    if [[ -n "$dsym_path" ]]; then
        dirname "$dsym_path"
        return 0
    fi

    dsym_path=$(find "${search_dirs[@]}" -name "*.dSYM" -type d 2>/dev/null | head -n 1)
    if [[ -n "$dsym_path" ]]; then
        dirname "$dsym_path"
        return 0
    fi

    return 1
}

# Upload iOS dSYM files to Crashlytics (explicit fallback)
upload_ios_symbols() {
    local flavor="$1"
    local upload_script="ios/Pods/FirebaseCrashlytics/upload-symbols"
    local gsp_path
    local dsym_dir

    if ! dsym_dir=$(find_ios_dsym_dir); then
        log_warning "No iOS dSYM files found; skipping Crashlytics symbol upload."
        return 0
    fi

    if ! gsp_path=$(get_ios_gsp_path "$flavor"); then
        log_warning "GoogleService-Info.plist not found; skipping Crashlytics symbol upload."
        return 0
    fi

    if [[ ! -f "$upload_script" ]]; then
        log_warning "Crashlytics upload-symbols script not found at: $upload_script"
        log_info "Run 'pod install' in ios/ to generate it."
        return 0
    fi

    log_step "Uploading iOS dSYM files to Crashlytics..."
    log_info "dSYM path: $dsym_dir"
    log_info "GoogleService-Info.plist: $gsp_path"

    if "$upload_script" -gsp "$gsp_path" -p ios "$dsym_dir"; then
        log_success "Crashlytics dSYM upload completed."
    else
        log_warning "Crashlytics dSYM upload failed. You can retry manually."
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        dev|stg|prod)
            if [[ -z "$FLAVOR" ]]; then
                FLAVOR="$1"
            else
                log_error "Multiple flavors specified"
                show_usage
            fi
            shift
            ;;
        -o|--no-obfuscate)
            OBFUSCATE=false
            shift
            ;;
        --export-method)
            EXPORT_METHOD="$2"
            shift 2
            ;;
        --upload-ios-symbols)
            if [[ -z "${2:-}" || "${2:-}" == -* ]]; then
                log_error "--upload-ios-symbols requires a value: true|false"
                exit 1
            fi
            case "$2" in
                true|TRUE|True|1|yes|YES|on|ON)
                    UPLOAD_IOS_SYMBOLS=true
                    ;;
                false|FALSE|False|0|no|NO|off|OFF)
                    UPLOAD_IOS_SYMBOLS=false
                    ;;
                *)
                    log_error "Invalid value for --upload-ios-symbols: $2"
                    log_info "Valid values: true|false"
                    exit 1
                    ;;
            esac
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Validate environment and parameters
if ! validate_environment; then
    exit 1
fi

if [[ -z "$FLAVOR" ]]; then
    log_error "No flavor specified."
    echo "Usage: $(basename "$0") [dev|stg|prod] [options]"
    echo "Use -h or --help for more information"
    exit 1
fi

if ! validate_flavor "$FLAVOR"; then
    exit 1
fi

# Get configuration from centralized configs
APP_NAME=$(get_app_display_name "$FLAVOR")
BUNDLE_ID=$(get_ios_bundle_id "$FLAVOR")
ENV_FILE=$(get_env_file_path "$FLAVOR")
IPA_OUTPUT_PATH=$(get_output_path "ios" "ipa")
DEBUG_INFO_PATH=$(get_debug_info_path)
FLUTTER_CMD=$(get_flutter_command)

# Set export options based on method and flavor
EXPORT_OPTIONS_DIR="${ROOT_DIR}/.info/key"
if [[ "$EXPORT_METHOD" == "ad-hoc" ]]; then
    # For ad-hoc (Firebase Distribution), use automatic signing
    # Manual provisioning profiles often cause certificate issues
    log_info "Using automatic signing for ad-hoc build"
    EXPORT_OPTIONS_PLIST=""
else
    # For app-store or other methods, let Flutter handle it automatically
    EXPORT_OPTIONS_PLIST=""
fi

# Get version from pubspec.yaml
APP_VERSION=$(get_pubspec_version)
if [[ -z "$APP_VERSION" ]]; then
    log_error "Could not read version from pubspec.yaml"
    exit 1
fi

# Validate required files
if [[ ! -f "$ENV_FILE" ]]; then
    log_error "Environment file not found: $ENV_FILE"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$IPA_OUTPUT_PATH"
mkdir -p "$DEBUG_INFO_PATH"

# Show configuration summary
show_config_summary "$FLAVOR" "ios"

# Display environment file contents
log_step "Environment Configuration"
echo "Using environment variables from: $ENV_FILE"
echo "Contents:"
cat "$ENV_FILE"
echo

# Build IPA with dynamic configuration
log_step "Building IPA for $FLAVOR flavor..."

# Get build arguments from configuration
BUILD_ARGS=(
    "--release"
    "--flavor" "$FLAVOR"
    "--dart-define-from-file=$ENV_FILE"
    "-t" "lib/main_$FLAVOR.dart"
    "--export-method=$EXPORT_METHOD"
    "--no-tree-shake-icons"
)

# Add obfuscation if enabled
if [[ "$OBFUSCATE" == "true" ]]; then
    log_info "Code obfuscation enabled"
    BUILD_ARGS+=("--obfuscate")
    BUILD_ARGS+=("--split-debug-info=$DEBUG_INFO_PATH")
else
    log_info "Code obfuscation disabled"
fi

# Add export options if specified
if [[ -n "$EXPORT_OPTIONS_PLIST" && -f "$EXPORT_OPTIONS_PLIST" ]]; then
    log_info "Using export options: $EXPORT_OPTIONS_PLIST"
    BUILD_ARGS+=("--export-options-plist=$EXPORT_OPTIONS_PLIST")
fi

# Print the complete command that will be executed
echo
log_step "Executing build command:"
echo "Command: $FLUTTER_CMD build ipa ${BUILD_ARGS[*]}"
echo "Export Method: $EXPORT_METHOD"
echo "Upload iOS symbols: $UPLOAD_IOS_SYMBOLS"
if [[ -n "$EXPORT_OPTIONS_PLIST" ]]; then
    echo "Export Options: $EXPORT_OPTIONS_PLIST"
fi
echo

# Execute build command
$FLUTTER_CMD build ipa "${BUILD_ARGS[@]}"

if [[ $? -ne 0 ]]; then
    log_error "IPA build failed for $FLAVOR flavor."
    exit 1
fi

log_success "IPA built successfully for $FLAVOR flavor."
log_info "Output location: $IPA_OUTPUT_PATH"

if [[ "$UPLOAD_IOS_SYMBOLS" == "true" ]]; then
    echo
    upload_ios_symbols "$FLAVOR"
else
    echo
    log_info "Skipping iOS dSYM upload to Crashlytics (--upload-ios-symbols false)."
fi

# Open the folder in Finder
echo
log_step "Opening IPA output folder..."
open "$IPA_OUTPUT_PATH" || log_warning "Could not open Finder. Navigate to $IPA_OUTPUT_PATH manually."

# Display build summary
echo
log_success "Build completed successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "App: $APP_NAME"
echo "Version: $APP_VERSION"
echo "Bundle ID: $BUNDLE_ID"
echo "Flavor: $FLAVOR"
echo "Output: $IPA_OUTPUT_PATH"
echo "Upload iOS symbols: $UPLOAD_IOS_SYMBOLS"
echo ""
echo "To distribute this build:"
echo "  Firebase only:  tools/macos/distribution/distribute_ios.sh $FLAVOR --ipa \"\$(find $IPA_OUTPUT_PATH -name '*.ipa' | head -n 1)\""
echo "  TestFlight only: tools/macos/distribution/distribute_ios.sh $FLAVOR --ipa \"\$(find $IPA_OUTPUT_PATH -name '*.ipa' | head -n 1)\" --method testflight"
echo "  Both platforms:  tools/macos/distribution/distribute_ios.sh $FLAVOR --ipa \"\$(find $IPA_OUTPUT_PATH -name '*.ipa' | head -n 1)\" --method both"
echo "  Manual upload:   tools/macos/distribution/upload_appstore.sh --file \"\$(find $IPA_OUTPUT_PATH -name '*.ipa' | head -n 1)\""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Build complete - no interactive prompt needed for automated scripts

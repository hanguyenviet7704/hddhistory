#!/bin/bash

# Enhanced APK Build Script with Centralized Configuration
# This script builds Android APK files using configuration from .info/ directory

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
NO_TREE_SHAKE=""
FLAVOR=""
DISTRIBUTE=false
DISTRIBUTION_GROUP=""
DISTRIBUTION_TESTERS=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-tree-shake-icons)
            NO_TREE_SHAKE="--no-tree-shake-icons"
            shift
            ;;
        --distribute)
            DISTRIBUTE=true
            shift
            ;;
        --group)
            DISTRIBUTION_GROUP="$2"
            shift 2
            ;;
        --testers)
            DISTRIBUTION_TESTERS="$2"
            shift 2
            ;;
        dev|stg|prod)
            FLAVOR="$1"
            shift
            ;;
        -h|--help)
            echo "Usage: $(basename "$0") [dev|stg|prod] [options]"
            echo ""
            echo "Arguments:"
            echo "  dev|stg|prod           Build flavor (required)"
            echo ""
            echo "Options:"
            echo "  --no-tree-shake-icons  Disable tree shaking for icons"
            echo "  --distribute           Distribute to Firebase App Distribution after build"
            echo "  --group <name>         Override distribution group (uses config by default)"
            echo "  --testers <emails>     Override testers list (comma-separated)"
            echo "  -h, --help            Show this help message"
            echo ""
            echo "Examples:"
            echo "  $(basename "$0") dev"
            echo "  $(basename "$0") prod --distribute"
            echo "  $(basename "$0") stg --distribute --group qa-team"
            echo ""
            echo "This script uses centralized configuration from .info/ directory."
            exit 0
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
    echo "Usage: $(basename "$0") [dev|stg|prod] [--no-tree-shake-icons]"
    echo "Use -h or --help for more information"
    exit 1
fi

if ! validate_flavor "$FLAVOR"; then
    exit 1
fi

# Get configuration from centralized configs
APP_NAME=$(get_app_display_name "$FLAVOR")
PACKAGE_NAME=$(get_android_package_name "$FLAVOR")
ENV_FILE=$(get_env_file_path "$FLAVOR")
APK_OUTPUT_PATH=$(get_output_path "android" "apk")
DEBUG_INFO_PATH=$(get_debug_info_path)
FLUTTER_CMD=$(get_flutter_command)

# Validate required files
if [[ ! -f "$ENV_FILE" ]]; then
    log_error "Environment file not found: $ENV_FILE"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$APK_OUTPUT_PATH"

# Show configuration summary
show_config_summary "$FLAVOR" "android"

# Display environment file contents
log_step "Environment Configuration"
echo "Using environment variables from: $ENV_FILE"
echo "Contents:"
cat "$ENV_FILE"
echo

# Build APK with dynamic configuration
log_step "Building APK for $FLAVOR flavor..."

# Get build arguments from configuration
BUILD_ARGS=(
    "--release"
    "--flavor" "$FLAVOR"
    "--dart-define-from-file=$ENV_FILE"
    "-t" "lib/main_$FLAVOR.dart"
    "--obfuscate"
    "--split-debug-info=$DEBUG_INFO_PATH"
)

# Add optional arguments
if [[ -n "$NO_TREE_SHAKE" ]]; then
    BUILD_ARGS+=("$NO_TREE_SHAKE")
fi

# Print the complete command that will be executed
echo
log_step "Executing build command:"
echo "Command: $FLUTTER_CMD build apk ${BUILD_ARGS[*]}"
echo

# Execute build command
$FLUTTER_CMD build apk "${BUILD_ARGS[@]}"

if [[ $? -ne 0 ]]; then
    log_error "APK build failed for $FLAVOR flavor."
    exit 1
fi

log_success "APK built successfully for $FLAVOR flavor."
log_info "Output location: $APK_OUTPUT_PATH"

# Automatically upload debug symbols to Firebase Crashlytics
echo
log_step "Uploading debug symbols to Firebase Crashlytics..."
FIREBASE_SETUP_SCRIPT="tools/macos/config/firebase_setup.sh"

if [[ -f "$FIREBASE_SETUP_SCRIPT" ]]; then
    "$FIREBASE_SETUP_SCRIPT" "$FLAVOR" "android"
    
    if [[ $? -eq 0 ]]; then
        log_success "Debug symbols uploaded successfully!"
    else
        log_warning "Debug symbols upload failed, but APK build was successful."
        log_info "You can manually upload later with: $FIREBASE_SETUP_SCRIPT $FLAVOR android"
    fi
else
    log_warning "Firebase setup script not found at: $FIREBASE_SETUP_SCRIPT"
    log_info "Debug symbols were not uploaded automatically."
fi

# Open the folder in Finder (macOS equivalent of Explorer)
echo
log_step "Opening APK output folder..."
open "$APK_OUTPUT_PATH"

# Display build summary
echo
log_success "Build completed successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "App: $APP_NAME"
echo "Package: $PACKAGE_NAME"
echo "Flavor: $FLAVOR"
echo "Output: $APK_OUTPUT_PATH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Distribute to Firebase App Distribution if requested
if [[ "$DISTRIBUTE" == true ]]; then
    echo
    log_step "Distributing to Firebase App Distribution..."
    
    # Prepare distribution command
    DIST_CMD="${SCRIPT_DIR}/../distribution/distribute_android.sh apk $FLAVOR"
    
    # Add custom group if specified
    if [[ -n "$DISTRIBUTION_GROUP" ]]; then
        export FIREBASE_DISTRIBUTION_GROUP="$DISTRIBUTION_GROUP"
    fi
    
    # Add custom testers if specified
    if [[ -n "$DISTRIBUTION_TESTERS" ]]; then
        export FIREBASE_DISTRIBUTION_TESTERS="$DISTRIBUTION_TESTERS"
    fi
    
    # Execute distribution
    if $DIST_CMD; then
        log_success "APK distributed to Firebase App Distribution!"
    else
        log_warning "Distribution failed but APK build was successful"
    fi
fi

# Pause for user removed for automation 
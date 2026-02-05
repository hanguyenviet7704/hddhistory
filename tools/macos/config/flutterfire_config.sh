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

# Parse command line arguments
FLAVOR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        dev|stg|prod)
            FLAVOR="$1"
            shift
            ;;
        -h|--help)
            echo "Usage: $(basename "$0") [dev|stg|prod]"
            echo ""
            echo "Arguments:"
            echo "  dev|stg|prod          Build flavor (required)"
            echo "  -h, --help           Show this help message"
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
    echo "Usage: $(basename "$0") [dev|stg|prod]"
    echo "Use -h or --help for more information"
    exit 1
fi

if ! validate_flavor "$FLAVOR"; then
    exit 1
fi

# Get configuration from centralized configs
PROJECT_ID=$(get_firebase_project_id "$FLAVOR")
IOS_BUNDLE_ID=$(get_ios_bundle_id "$FLAVOR")
ANDROID_PACKAGE=$(get_android_package_name "$FLAVOR")

# Validate required configurations
if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "null" ]]; then
    log_error "Firebase project ID not found in configuration."
    exit 1
fi

if [[ -z "$IOS_BUNDLE_ID" || "$IOS_BUNDLE_ID" == "null" ]]; then
    log_error "iOS bundle ID not found for flavor: $FLAVOR"
    exit 1
fi

if [[ -z "$ANDROID_PACKAGE" || "$ANDROID_PACKAGE" == "null" ]]; then
    log_error "Android package name not found for flavor: $FLAVOR"
    exit 1
fi

# Show configuration summary
show_config_summary "$FLAVOR"

# Execute FlutterFire configuration
log_step "Configuring Firebase for $FLAVOR environment..."

# Build the flutterfire config command with dynamic parameters
FLUTTERFIRE_ARGS=(
    "config"
    "--overwrite-firebase-options"
    "--project=$PROJECT_ID"
    "--out=lib/config/services/firebase/firebase_options_$FLAVOR.dart"
    "--ios-bundle-id=$IOS_BUNDLE_ID"
    "--ios-out=ios/flavors/$FLAVOR/GoogleService-Info.plist"
    "--android-package-name=$ANDROID_PACKAGE"
    "--android-out=android/app/src/$FLAVOR/google-services.json"
    "--platforms=ios,android"
)

# Print the command before execution
echo
log_step "Executing FlutterFire configuration command:"
echo "Command: flutterfire ${FLUTTERFIRE_ARGS[*]}"
echo

# Execute the command
flutterfire "${FLUTTERFIRE_ARGS[@]}"

if [[ $? -ne 0 ]]; then
    log_error "Firebase configuration for $FLAVOR failed."
    exit 1
fi

# Display success summary
echo
log_success "Firebase configuration completed successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Project: $PROJECT_ID"
echo "Flavor: $FLAVOR"
echo "iOS Bundle ID: $IOS_BUNDLE_ID"
echo "Android Package: $ANDROID_PACKAGE"
echo ""
echo "Generated files:"
echo "  - lib/config/services/firebase/firebase_options_$FLAVOR.dart"
echo "  - ios/flavors/$FLAVOR/GoogleService-Info.plist"
echo "  - android/app/src/$FLAVOR/google-services.json"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 0 
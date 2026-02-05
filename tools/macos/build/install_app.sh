#!/bin/bash

# Enhanced App Install Script with Centralized Configuration
# This script installs Flutter apps using configuration from .info/ directory

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

# Parse command line arguments
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
APP_NAME=$(get_app_display_name "$FLAVOR")
PACKAGE_NAME=$(get_android_package_name "$FLAVOR")
APK_OUTPUT_PATH=$(get_output_path "android" "apk")
FLUTTER_CMD=$(get_flutter_command)

# Show configuration summary
show_config_summary "$FLAVOR" "android"

# Install the app using Flutter
log_step "Installing $APP_NAME ($FLAVOR) to connected device..."

# Print the command that will be executed
echo
log_step "Executing install command:"
echo "Command: $FLUTTER_CMD install --flavor $FLAVOR"
echo

# Execute install command
$FLUTTER_CMD install --flavor "$FLAVOR"

if [[ $? -ne 0 ]]; then
    log_error "Failed to install app."
    log_info "Make sure you have a device connected and USB debugging enabled."
    exit 1
fi

log_success "App installed successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "App: $APP_NAME"
echo "Package: $PACKAGE_NAME"
echo "Flavor: $FLAVOR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" 
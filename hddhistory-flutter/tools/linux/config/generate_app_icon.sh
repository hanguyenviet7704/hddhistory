#!/bin/bash

# Enhanced App Icon Generation Script with Centralized Configuration (Linux)
# This script generates app icons using configuration from .info/ directory

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

# Validate environment
if ! validate_environment; then
    exit 1
fi

# Show basic app information
APP_NAME=$(get_app_name)
VERSION=$(get_pubspec_version)

log_info "🎨 Generating app icons with centralized configuration (Linux)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "App: $APP_NAME"
echo "Version: $VERSION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Define the flutter_launcher_icons command
FLUTTER_LAUNCHER_ICON_CMD="dart run flutter_launcher_icons"

# Print command before execution
log_step "Executing icon generation command:"
echo "Command: $FLUTTER_LAUNCHER_ICON_CMD"
echo

# Run the flutter_launcher_icons command
log_step "Running flutter_launcher_icons..."
$FLUTTER_LAUNCHER_ICON_CMD

if [[ $? -ne 0 ]]; then
    log_error "flutter_launcher_icons command failed."
    exit 1
fi

# Success message
echo
log_success "All platform icon generation complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Generated icons for:"
echo "  • Android (all densities)"
echo "  • iOS (all sizes - if configured)"
echo ""
echo "Note: iOS icons will be generated but iOS builds"
echo "      are not supported on Linux."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 0

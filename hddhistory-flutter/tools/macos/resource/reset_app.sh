#!/bin/bash

# Enhanced Flutter Reset Script with Centralized Configuration
# This script resets Flutter project using configuration from .info/ directory

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
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Usage: $(basename "$0") [--help]"
            echo ""
            echo "This script cleans and resets the Flutter project:"
            echo "  • Removes build directory"
            echo "  • Runs flutter clean"
            echo "  • Runs flutter pub get"
            echo "  • Optionally runs build_runner clean and build"
            echo ""
            echo "Options:"
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

# Get Flutter command from configuration
FLUTTER_CMD=$(get_flutter_command)
APP_NAME=$(get_app_name)

log_info "🔄 Resetting Flutter project: $APP_NAME"

# Validate environment (just check Flutter, not all dependencies)
log_step "Validating Flutter environment..."
if ! command -v flutter >/dev/null 2>&1; then
    log_error "Flutter is not installed or not added to PATH."
    log_info "Please ensure that Flutter is installed and added to your system PATH."
    exit 1
fi

# Show Flutter version
FLUTTER_VERSION=$(flutter --version | head -n 1)
log_success "Flutter found: $FLUTTER_VERSION"

# Clean the Flutter project
log_step "Cleaning Flutter project..."

# Remove build directories
log_info "Removing build directories..."
rm -rf "${ROOT_DIR}/build" 2>/dev/null
rm -rf "${ROOT_DIR}/.dart_tool" 2>/dev/null
rm -rf "${ROOT_DIR}/android/.gradle" 2>/dev/null
rm -rf "${ROOT_DIR}/ios/.symlinks" 2>/dev/null
rm -rf "${ROOT_DIR}/ios/Pods" 2>/dev/null

# Print and execute Flutter clean command
echo
log_step "Executing clean command:"
echo "Command: $FLUTTER_CMD clean"
echo

$FLUTTER_CMD clean

if [[ $? -ne 0 ]]; then
    log_error "Flutter clean failed."
    exit 1
fi

log_success "Project cleaned successfully."

# Get Flutter dependencies (pub get)
log_step "Fetching Flutter packages..."

# Print and execute pub get command
echo
log_step "Executing pub get command:"
echo "Command: $FLUTTER_CMD pub get"
echo

$FLUTTER_CMD pub get

if [[ $? -ne 0 ]]; then
    log_error "Flutter pub get failed."
    exit 1
fi

log_success "Dependencies fetched successfully."

# Clean and regenerate build_runner generated files
log_step "Cleaning and regenerating build_runner files..."

# Print and execute build_runner commands
echo
log_step "Executing build_runner commands:"
echo "Command: $FLUTTER_CMD pub run build_runner clean"
echo "Command: $FLUTTER_CMD pub run build_runner build --delete-conflicting-outputs"
echo

$FLUTTER_CMD pub run build_runner clean
$FLUTTER_CMD pub run build_runner build --delete-conflicting-outputs

if [[ $? -ne 0 ]]; then
    log_warning "Build runner failed, but project reset was successful."
else
    log_success "Build runner files regenerated successfully."
fi

# Final success message
echo
log_success "🎉 Flutter project reset completed successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Project: $APP_NAME"
echo "Actions completed:"
echo "  ✅ Build directories cleaned"
echo "  ✅ Flutter clean executed"
echo "  ✅ Dependencies refreshed"
echo "  ✅ Generated code refreshed"
echo ""
echo "Your project is now ready for development!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Pause for user removed for automation 
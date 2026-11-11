#!/bin/bash

# Enhanced Symbol Verification Script with Centralized Configuration (Linux)
# This script verifies debug symbols using configuration from .info/ directory

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

# Check for parameters
if [[ -z "$1" ]]; then
    log_error "No flavor specified."
    echo "Usage: $0 [dev|stg|prod]"
    echo "This script helps verify uploaded debug symbols in Firebase Console"
    exit 1
fi

FLAVOR="$1"

# Validate environment and parameters
if ! validate_environment; then
    exit 1
fi

if ! validate_flavor "$FLAVOR"; then
    exit 1
fi

# Get configuration from centralized configs
FIREBASE_PROJECT_ID=$(get_firebase_project_id "$FLAVOR")
EXPECTED_PACKAGE=$(get_android_package_name "$FLAVOR")
GOOGLE_SERVICES_FILE="android/app/src/$FLAVOR/google-services.json"
CONSOLE_URL="https://console.firebase.google.com/project/$FIREBASE_PROJECT_ID/crashlytics/app/android:$EXPECTED_PACKAGE"

# Try to get Firebase App ID from centralized config first
FIREBASE_APP_ID=$(get_firebase_app_id "android" "$FLAVOR")

if [[ -z "$FIREBASE_APP_ID" || "$FIREBASE_APP_ID" == "null" ]]; then
    log_warning "Firebase App ID not found in centralized config, extracting from google-services.json"

    # Extract Firebase App ID from google-services.json
    if command -v jq &> /dev/null; then
        log_info "Using jq to parse JSON..."
        echo "Command: jq -r --arg pkg \"$EXPECTED_PACKAGE\" '.client[] | select(.client_info.android_client_info.package_name == \$pkg) | .client_info.mobilesdk_app_id' \"$GOOGLE_SERVICES_FILE\""
        FIREBASE_APP_ID=$(jq -r --arg pkg "$EXPECTED_PACKAGE" '.client[] | select(.client_info.android_client_info.package_name == $pkg) | .client_info.mobilesdk_app_id' "$GOOGLE_SERVICES_FILE")
    else
        log_warning "jq not found, using grep/sed method..."
        echo "Command: grep -A 10 \"\\\"package_name\\\": \\\"$EXPECTED_PACKAGE\\\"\" \"$GOOGLE_SERVICES_FILE\" | grep -B 10 \"mobilesdk_app_id\" | grep \"mobilesdk_app_id\" | head -1 | sed 's/.*\"mobilesdk_app_id\": \"\\([^\"]*\\)\".*/\\1/'"
        FIREBASE_APP_ID=$(grep -A 10 "\"package_name\": \"$EXPECTED_PACKAGE\"" "$GOOGLE_SERVICES_FILE" | grep -B 10 "mobilesdk_app_id" | grep "mobilesdk_app_id" | head -1 | sed 's/.*"mobilesdk_app_id": "\([^"]*\)".*/\1/')
    fi
fi

# Show configuration summary
show_config_summary "$FLAVOR" "android"

echo
log_info "🔍 Debug symbols verification for $FLAVOR environment (Linux)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Project: $FIREBASE_PROJECT_ID"
echo "Package: $EXPECTED_PACKAGE"
echo "Firebase App ID: $FIREBASE_APP_ID"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

log_step "📍 Console Links:"
echo "• Main Dashboard: $CONSOLE_URL"
echo "• Debug Symbols: $CONSOLE_URL/settings/symbols"
echo "• Issues/Crashes: $CONSOLE_URL/issues"
echo

log_step "🔧 CLI Commands to check uploads:"
echo "Command: firebase crashlytics:symbols:list --app=\"$FIREBASE_APP_ID\""
echo

# Get debug symbols path from centralized configuration
DEBUG_SYMBOLS_PATH=$(get_debug_info_path)
if [[ -z "$DEBUG_SYMBOLS_PATH" ]]; then
    DEBUG_SYMBOLS_PATH=".obfuscation"  # fallback
fi

log_step "📁 Local debug symbols info:"
if [[ -d "$DEBUG_SYMBOLS_PATH" ]]; then
    log_success "Debug symbols directory: EXISTS"
    echo "Path: $DEBUG_SYMBOLS_PATH"
    echo "Files in $DEBUG_SYMBOLS_PATH:"
    ls -la "$DEBUG_SYMBOLS_PATH/" | grep -v "^total" | grep -v "^d"
else
    log_warning "Debug symbols directory: NOT FOUND"
    log_info "Path checked: $DEBUG_SYMBOLS_PATH"
    log_info "Run a build with obfuscation to generate symbols first"
fi

echo
log_step "🌐 Opening Firebase Console in browser..."
echo "Opening: $CONSOLE_URL/settings/symbols"

# Linux browser opening
if command -v xdg-open > /dev/null; then
    xdg-open "$CONSOLE_URL/settings/symbols"
elif command -v gnome-open > /dev/null; then
    gnome-open "$CONSOLE_URL/settings/symbols"
elif command -v kde-open > /dev/null; then
    kde-open "$CONSOLE_URL/settings/symbols"
else
    log_info "Could not open browser automatically. Please navigate to:"
    echo "$CONSOLE_URL/settings/symbols"
fi

#!/bin/bash

# Enhanced Firebase Setup Script with Centralized Configuration
# This script sets up Firebase services using configuration from .info/ directory

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

# Check for parameters immediately
if [[ -z "$1" ]]; then
    log_error "No environment specified."
    echo "Usage: $0 [dev|stg|prod] [android|ios]"
    exit 1
fi

FLAVOR="$1"
PLATFORM="${2:-android}"

# Validate environment and parameters
if ! validate_environment; then
    exit 1
fi

if ! validate_flavor "$FLAVOR"; then
    exit 1
fi

if ! validate_platform "$PLATFORM"; then
    exit 1
fi

# Skip manual upload for iOS since it's handled by Xcode build phases
if [[ "$PLATFORM" == "ios" ]]; then
    log_info "iOS Crashlytics symbol upload is automatically handled by Xcode build phases."
    log_success "No manual action needed for iOS - your debug symbols will be uploaded during the build process."
    log_info "This is configured in the project.pbxproj file in the FlutterFire upload-crashlytics-symbols build phase."
    exit 0
fi

# Get debug symbols path from centralized configuration
DEBUG_SYMBOLS_PATH=$(get_debug_info_path)
if [[ -z "$DEBUG_SYMBOLS_PATH" ]]; then
    DEBUG_SYMBOLS_PATH=".obfuscation"  # fallback
fi

# For Android only, ensure Flutter symbols directory exists
if [[ ! -d "$DEBUG_SYMBOLS_PATH" ]]; then
    log_error "Debug symbols directory '$DEBUG_SYMBOLS_PATH' not found."
    log_info "Please run a build with obfuscation first to generate debug symbols."
    log_info "Example: --obfuscate --split-debug-info=$DEBUG_SYMBOLS_PATH"
    exit 1
fi

# Get configuration from centralized configs
EXPECTED_PACKAGE=$(get_android_package_name "$FLAVOR")
GOOGLE_SERVICES_FILE="android/app/src/$FLAVOR/google-services.json"

log_info "Configuration loaded from centralized configs:"
log_info "Package name: $EXPECTED_PACKAGE"
log_info "Google services file: $GOOGLE_SERVICES_FILE"

# Check if Firebase configuration file exists
if [[ ! -f "$GOOGLE_SERVICES_FILE" ]]; then
    log_error "Firebase configuration file '$GOOGLE_SERVICES_FILE' not found."
    log_info "Please run flutterfire configuration first."
    exit 1
fi

# Show configuration summary
show_config_summary "$FLAVOR" "$PLATFORM"

log_step "Setting up Firebase services for $FLAVOR environment on $PLATFORM platform..."
log_info "Using configuration from: $GOOGLE_SERVICES_FILE"

# Try to get Firebase App ID from centralized config first
FIREBASE_APP_ID=$(get_firebase_app_id "$PLATFORM" "$FLAVOR")

if [[ -z "$FIREBASE_APP_ID" || "$FIREBASE_APP_ID" == "null" ]]; then
    log_warning "Firebase App ID not found in centralized config, extracting from google-services.json"
    
    # Extract mobilesdk_app_id for Android from google-services.json
    if command -v jq &> /dev/null; then
        log_info "Using jq to parse JSON..."
        echo "Command: jq -r --arg pkg \"$EXPECTED_PACKAGE\" '.client[] | select(.client_info.android_client_info.package_name == \$pkg) | .client_info.mobilesdk_app_id' \"$GOOGLE_SERVICES_FILE\""
        FIREBASE_APP_ID=$(jq -r --arg pkg "$EXPECTED_PACKAGE" '.client[] | select(.client_info.android_client_info.package_name == $pkg) | .client_info.mobilesdk_app_id' "$GOOGLE_SERVICES_FILE")
    else
        log_warning "jq not found, using grep/sed method..."
        echo "Command: grep -A 10 \"\\\"package_name\\\": \\\"$EXPECTED_PACKAGE\\\"\" \"$GOOGLE_SERVICES_FILE\" | grep -B 10 \"mobilesdk_app_id\" | grep \"mobilesdk_app_id\" | head -1 | sed 's/.*\"mobilesdk_app_id\": \"\\([^\"]*\\)\".*/\\1/'"
        # Fallback method using grep and sed
        FIREBASE_APP_ID=$(grep -A 10 "\"package_name\": \"$EXPECTED_PACKAGE\"" "$GOOGLE_SERVICES_FILE" | grep -B 10 "mobilesdk_app_id" | grep "mobilesdk_app_id" | head -1 | sed 's/.*"mobilesdk_app_id": "\([^"]*\)".*/\1/')
    fi
fi

# Validate that we found the Firebase App ID
if [[ -z "$FIREBASE_APP_ID" || "$FIREBASE_APP_ID" == "null" ]]; then
    log_error "Could not extract Firebase App ID from '$GOOGLE_SERVICES_FILE'"
    log_info "Please verify the google-services.json file contains the correct package configuration."
    exit 1
fi

log_success "Found Firebase App ID: $FIREBASE_APP_ID"

# Check if Firebase CLI is installed
log_step "Checking Firebase CLI..."
if ! command -v firebase &> /dev/null; then
    log_error "Firebase CLI is not installed."
    log_info "Please install it with: npm install -g firebase-tools"
    exit 1
fi

log_success "Firebase CLI found"

# Check if user is logged in to Firebase
log_step "Verifying Firebase CLI authentication..."
echo "Command: firebase projects:list"
if ! firebase projects:list &> /dev/null; then
    log_error "Not logged in to Firebase CLI."
    log_info "Please login with: firebase login"
    exit 1
fi

log_success "Firebase CLI authenticated"

# Create a temporary directory with only platform-specific symbols
TEMP_SYMBOLS_DIR=$(mktemp -d)
log_step "Creating temporary directory for filtered symbols: $TEMP_SYMBOLS_DIR"

log_info "Filtering Android symbols..."
echo "Command: find \"$DEBUG_SYMBOLS_PATH\" -name \"*.android-*\" -o -name \"app.symbols\" | xargs -I{} cp {} \"$TEMP_SYMBOLS_DIR/\""
find "$DEBUG_SYMBOLS_PATH" -name "*.android-*" -o -name "app.symbols" | xargs -I{} cp {} "$TEMP_SYMBOLS_DIR/"

# Get Firebase project ID from centralized config
FIREBASE_PROJECT_ID=$(get_firebase_project_id "$FLAVOR")

# Upload debug symbols to Firebase Crashlytics
log_step "Uploading Flutter debug symbols to Firebase Crashlytics (Android)..."
log_info "Filtered symbols path: $TEMP_SYMBOLS_DIR"
log_info "Firebase Project ID: $FIREBASE_PROJECT_ID"
log_info "Firebase App ID: $FIREBASE_APP_ID"

echo "Command: firebase crashlytics:symbols:upload --app=\"$FIREBASE_APP_ID\" \"$TEMP_SYMBOLS_DIR\""
firebase crashlytics:symbols:upload --app="$FIREBASE_APP_ID" "$TEMP_SYMBOLS_DIR"
UPLOAD_RESULT=$?

# Clean up temp directory
log_info "Cleaning up temporary directory: $TEMP_SYMBOLS_DIR"
rm -rf "$TEMP_SYMBOLS_DIR"

if [[ $UPLOAD_RESULT -ne 0 ]]; then
    log_error "Failed to upload Flutter debug symbols to Firebase Crashlytics (Android)."
    exit 1
fi

echo
log_success "Firebase Crashlytics Flutter debug symbols uploaded successfully for $FLAVOR environment on $PLATFORM platform!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Next steps:"
echo "1. Your Flutter symbols are now uploaded to Firebase Crashlytics"
echo "2. You can view crash reports with readable stack traces in the Firebase Console"
echo "3. Make sure Crashlytics is properly initialized in your Flutter app"
echo
echo "Firebase Console: https://console.firebase.google.com/project/$FIREBASE_PROJECT_ID/crashlytics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
exit 0 
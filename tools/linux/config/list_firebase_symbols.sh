#!/bin/bash

# Firebase Crashlytics Debug Symbols Checker (Linux)
# This script helps verify Firebase Crashlytics debug symbol configuration

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

# Display a colorful header
echo -e "\033[1;34m"
echo "🔍 Firebase Crashlytics Debug Symbols Checker (Linux) 🔍"
echo "========================================================="
echo -e "\033[0m"

# Check for parameters
if [[ -z "$1" ]]; then
    echo "Usage: $0 [dev|stg|prod] [android]"
    echo "  This tool helps verify Firebase Crashlytics debug symbol configuration"
    echo "  Note: iOS is not supported on Linux"
    exit 1
fi

FLAVOR="$1"
PLATFORM="${2:-android}"

# Validate inputs using common functions
if ! validate_flavor "$FLAVOR"; then
    exit 1
fi

if ! validate_platform "$PLATFORM"; then
    exit 1
fi

# Get configuration from centralized configs
log_step "Loading configuration for $FLAVOR environment..."

BUNDLE_ID=$(get_android_package_name "$FLAVOR")
FIREBASE_PROJECT_ID=$(get_firebase_project_id "$FLAVOR")
CONFIG_FILE="android/app/src/$FLAVOR/google-services.json"
DEBUG_SYMBOLS_PATH=$(get_debug_info_path)

if [[ -z "$DEBUG_SYMBOLS_PATH" ]]; then
    DEBUG_SYMBOLS_PATH=".obfuscation"  # fallback
fi

log_success "Configuration loaded:"
log_info "Package ID: $BUNDLE_ID"
log_info "Firebase Project: $FIREBASE_PROJECT_ID"
log_info "Config File: $CONFIG_FILE"
log_info "Debug Symbols Path: $DEBUG_SYMBOLS_PATH"

# Check if the configuration file exists
echo
log_step "Checking Firebase configuration file..."
if [[ -f "$CONFIG_FILE" ]]; then
    log_success "Configuration file found: $CONFIG_FILE"

    # Try to extract Firebase App ID
    if command -v jq &> /dev/null; then
        log_info "Using jq to parse configuration..."
        FIREBASE_APP_ID=$(jq -r --arg pkg "$BUNDLE_ID" '.client[] | select(.client_info.android_client_info.package_name == $pkg) | .client_info.mobilesdk_app_id' "$CONFIG_FILE")

        if [[ -n "$FIREBASE_APP_ID" && "$FIREBASE_APP_ID" != "null" ]]; then
            log_success "Firebase App ID: $FIREBASE_APP_ID"
        else
            log_error "Could not find Firebase App ID for package: $BUNDLE_ID"
        fi
    else
        log_warning "jq not installed - cannot parse configuration file"
        log_info "Install jq for detailed configuration analysis: sudo apt-get install jq"
    fi
else
    log_error "Configuration file not found: $CONFIG_FILE"
    log_info "Run flutterfire configure to generate this file"
fi

# Check debug symbols directory
echo
log_step "Checking debug symbols..."
if [[ -d "$DEBUG_SYMBOLS_PATH" ]]; then
    log_success "Debug symbols directory found: $DEBUG_SYMBOLS_PATH"

    # Count symbol files
    SYMBOL_COUNT=$(find "$DEBUG_SYMBOLS_PATH" -name "*.symbols" 2>/dev/null | wc -l)
    ANDROID_SYMBOL_COUNT=$(find "$DEBUG_SYMBOLS_PATH" -name "*.android-*" 2>/dev/null | wc -l)

    log_info "Symbol files found:"
    log_info "  Total .symbols files: $SYMBOL_COUNT"
    log_info "  Android-specific files: $ANDROID_SYMBOL_COUNT"

    if [[ $SYMBOL_COUNT -gt 0 || $ANDROID_SYMBOL_COUNT -gt 0 ]]; then
        log_success "Debug symbols are available for upload"

        echo
        log_step "Recent symbol files:"
        find "$DEBUG_SYMBOLS_PATH" -name "*.symbols" -o -name "*.android-*" 2>/dev/null | head -5 | while read -r file; do
            SIZE=$(ls -lh "$file" | awk '{print $5}')
            DATE=$(ls -l "$file" | awk '{print $6, $7, $8}')
            echo "  📄 $(basename "$file") ($SIZE, $DATE)"
        done
    else
        log_warning "No debug symbols found"
        log_info "Build your app with --obfuscate --split-debug-info=$DEBUG_SYMBOLS_PATH to generate symbols"
    fi
else
    log_warning "Debug symbols directory not found: $DEBUG_SYMBOLS_PATH"
    log_info "This directory will be created when you build with obfuscation enabled"
fi

# Check Firebase CLI
echo
log_step "Checking Firebase CLI..."
if command -v firebase &> /dev/null; then
    log_success "Firebase CLI is installed"

    # Check authentication
    if firebase projects:list &> /dev/null; then
        log_success "Firebase CLI is authenticated"

        # Try to list existing symbol uploads (if App ID is available)
        if [[ -n "$FIREBASE_APP_ID" && "$FIREBASE_APP_ID" != "null" ]]; then
            echo
            log_step "Checking existing symbol uploads..."
            echo "Command: firebase crashlytics:symbols:get --app=\"$FIREBASE_APP_ID\""

            if firebase crashlytics:symbols:get --app="$FIREBASE_APP_ID" 2>/dev/null; then
                log_success "Successfully retrieved symbol upload history"
            else
                log_info "No symbol uploads found or unable to retrieve history"
            fi
        fi
    else
        log_warning "Firebase CLI not authenticated"
        log_info "Run 'firebase login' to authenticate"
    fi
else
    log_warning "Firebase CLI not installed"
    log_info "Install with: npm install -g firebase-tools"
fi

# Summary and recommendations
echo
log_step "Summary and Recommendations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ -f "$CONFIG_FILE" ]]; then
    echo "✅ Firebase configuration is set up"
else
    echo "❌ Firebase configuration missing"
    echo "   → Run: flutterfire configure"
fi

if [[ -d "$DEBUG_SYMBOLS_PATH" ]] && [[ $(find "$DEBUG_SYMBOLS_PATH" -name "*.symbols" -o -name "*.android-*" 2>/dev/null | wc -l) -gt 0 ]]; then
    echo "✅ Debug symbols are available"
else
    echo "❌ Debug symbols not available"
    echo "   → Build with: tools/linux/build/build_apk.sh $FLAVOR"
fi

if command -v firebase &> /dev/null && firebase projects:list &> /dev/null; then
    echo "✅ Firebase CLI ready"
else
    echo "❌ Firebase CLI not ready"
    echo "   → Install: npm install -g firebase-tools"
    echo "   → Login: firebase login"
fi

echo
echo "To upload debug symbols:"
echo "  tools/linux/config/firebase_setup.sh $FLAVOR android"
echo
echo "Firebase Console:"
echo "  https://console.firebase.google.com/project/$FIREBASE_PROJECT_ID/crashlytics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 0
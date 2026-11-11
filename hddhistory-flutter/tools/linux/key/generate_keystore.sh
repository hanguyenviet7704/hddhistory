#!/bin/bash

# Enhanced Keystore Generation Script with Centralized Configuration (Linux)
# This script generates Android keystore files using configuration from .info/ directory

# Navigate to the root directory relative to the current script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/../../.." || {
    echo "❌ Failed to navigate to the project root directory."
    exit 1
}
ROOT_DIR="."

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

# Get app information for keystore generation
APP_NAME=$(get_app_name)
VERSION=$(get_pubspec_version)

# Set the path to the key.properties file
PROPERTIES_FILE="$ROOT_DIR/android/key.properties"

# Set the path for the new keystore
KEYSTORE_PATH="$ROOT_DIR/android/app/upload-keystore.jks"

log_info "🔐 Android Keystore Generation with Centralized Configuration (Linux)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "App: $APP_NAME"
echo "Version: $VERSION"
echo "Keystore Path: $KEYSTORE_PATH"
echo "Properties File: $PROPERTIES_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Read values from key.properties
log_step "Reading key.properties configuration..."
if [ -f "$PROPERTIES_FILE" ]; then
    log_success "Properties file found: $PROPERTIES_FILE"
    echo
    log_info "File contents:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat "$PROPERTIES_FILE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo

    # Source the file to load variables
    log_step "Loading configuration variables..."
    source "$PROPERTIES_FILE"

    # Display the loaded values (masking sensitive data)
    log_info "Loaded values:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "storeFile: ${storeFile:-<not set>}"
    echo "keyAlias: ${keyAlias:-<not set>}"
    echo "storePassword: ${storePassword:+<set>}"
    echo "keyPassword: ${keyPassword:+<set>}"
    echo "validity: ${validity:-7300} days"
    echo "keyCN: ${keyCN:-<not set>}"
    echo "keyOU: ${keyOU:-<not set>}"
    echo "keyO: ${keyO:-<not set>}"
    echo "keyL: ${keyL:-<not set>}"
    echo "keyS: ${keyS:-<not set>}"
    echo "keyC: ${keyC:-<not set>}"
    echo "keyAlgorithm: ${keyAlgorithm:-RSA}"
    echo "keySize: ${keySize:-2048}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo

    # Set default validity if not specified
    if [ -z "$validity" ]; then
        validity=7300  # 20 years
        log_info "Using default validity of $validity days (20 years)"
        echo
    fi

    # Confirm before proceeding
    read -p "Do you want to proceed with these values? (y/N): " CONFIRM
    if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
        log_warning "Operation cancelled by user."
        exit 0
    fi
else
    log_error "key.properties file not found at $PROPERTIES_FILE"
    log_info "Please create this file with the required keystore configuration."
    exit 1
fi

# Check if keystore already exists
log_step "Checking for existing keystore..."
if [ -f "$KEYSTORE_PATH" ]; then
    log_warning "Keystore already exists at: $KEYSTORE_PATH"
    read -p "Do you want to overwrite it? (y/N): " OVERWRITE
    if [[ ! $OVERWRITE =~ ^[Yy]$ ]]; then
        log_warning "Operation cancelled by user."
        exit 0
    fi
else
    log_info "No existing keystore found. Proceeding with generation."
fi

# Generate the keystore
echo
log_step "Generating Android keystore..."

# Set default values if not specified in properties file
KEY_ALGORITHM=${keyAlgorithm:-RSA}
KEY_SIZE=${keySize:-2048}

# Build dynamic distinguished name from properties
DNAME="CN=${keyCN:-dcore_artlexis}, OU=${keyOU:-dcore_artlexis}, O=${keyO:-dcore_artlexis}, L=${keyL:-dcore_artlexis}, S=${keyS:-dcore_artlexis}, C=${keyC:-dcore_artlexis}"

log_info "Using distinguished name: $DNAME"
echo

# Print the command before execution
KEYTOOL_ARGS=(
    "-genkeypair"
    "-keystore" "$KEYSTORE_PATH"
    "-alias" "$keyAlias"
    "-keyalg" "$KEY_ALGORITHM"
    "-keysize" "$KEY_SIZE"
    "-validity" "$validity"
    "-storepass" "$storePassword"
    "-keypass" "$keyPassword"
    "-dname" "$DNAME"
    "-noprompt"
)

log_info "Executing keytool command:"
echo "Command: keytool ${KEYTOOL_ARGS[*]}"
echo

# Execute the command
keytool "${KEYTOOL_ARGS[@]}"

if [ $? -ne 0 ]; then
    log_error "Failed to generate keystore."
    exit 1
fi

echo
log_success "Keystore generated successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Keystore Details:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "App: $APP_NAME"
echo "Version: $VERSION"
echo "Path: $KEYSTORE_PATH"
echo "Alias: $keyAlias"
echo "Algorithm: $KEY_ALGORITHM"
echo "Key Size: $KEY_SIZE bits"
echo "Validity: $validity days (~$((validity / 365)) years)"
echo "Distinguished Name: $DNAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

log_step "Verification Commands:"
echo "• List keystore details:"
echo "  keytool -list -v -keystore \"$KEYSTORE_PATH\" -alias \"$keyAlias\""
echo
echo "• Verify keystore integrity:"
echo "  keytool -list -keystore \"$KEYSTORE_PATH\""
echo

log_info "📝 Next Steps:"
echo "1. Update your build.gradle file with the keystore information"
echo "2. Ensure key.properties is properly configured"
echo "3. Test the keystore with a release build"

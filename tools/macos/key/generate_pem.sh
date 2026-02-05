#!/bin/bash

# Enhanced PEM Certificate Generation Script with Centralized Configuration
# This script generates PEM certificates from Android keystores using configuration from .info/ directory

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

# Validate environment
if ! validate_environment; then
    exit 1
fi

# Get app information for PEM generation
APP_NAME=$(get_app_name)
VERSION=$(get_pubspec_version)

# Set the path to the key.properties file
PROPERTIES_FILE="$ROOT_DIR/android/key.properties"

# Set the path for the keystore
KEYSTORE_PATH="$ROOT_DIR/android/app/upload-keystore.jks"

# Set the path for the output PEM file
PEM_OUTPUT_PATH="$ROOT_DIR/android/app/upload-key.pem"

log_info "🔑 PEM Certificate Generation with Centralized Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "App: $APP_NAME"
echo "Version: $VERSION"
echo "Keystore Path: $KEYSTORE_PATH"
echo "PEM Output Path: $PEM_OUTPUT_PATH"
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
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
else
    log_error "key.properties file not found at $PROPERTIES_FILE"
    log_info "Please create this file with the required keystore configuration."
    exit 1
fi

# Check if keystore exists
log_step "Validating keystore file..."
if [ ! -f "$KEYSTORE_PATH" ]; then
    log_error "Keystore not found at $KEYSTORE_PATH"
    log_info "Please run generate_keystore.sh first to create the keystore."
    exit 1
fi
log_success "Keystore found: $KEYSTORE_PATH"

# Check if PEM file already exists
log_step "Checking for existing PEM file..."
if [ -f "$PEM_OUTPUT_PATH" ]; then
    log_warning "PEM file already exists at: $PEM_OUTPUT_PATH"
    read -p "Do you want to overwrite it? (y/N): " OVERWRITE
    if [[ ! $OVERWRITE =~ ^[Yy]$ ]]; then
        log_warning "Operation cancelled by user."
        exit 0
    fi
else
    log_info "No existing PEM file found. Proceeding with generation."
fi

# Display information about the operation
echo
log_step "PEM Certificate Information"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "This PEM file is used for:"
echo "• Resetting your upload key in Google Play Console"
echo "• Requesting Google to reset your app signing key"
echo "• Certificate verification and validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Generate the PEM certificate
log_step "Extracting certificate from keystore..."

# Print the command before execution
KEYTOOL_ARGS=(
    "-export"
    "-keystore" "$KEYSTORE_PATH"
    "-alias" "$keyAlias"
    "-storepass" "$storePassword"
    "-rfc"
    "-file" "$PEM_OUTPUT_PATH"
)

log_info "Executing keytool command:"
echo "Command: keytool ${KEYTOOL_ARGS[*]}"
echo

# Execute the command
keytool "${KEYTOOL_ARGS[@]}"

if [ $? -ne 0 ]; then
    log_error "Failed to generate PEM certificate."
    exit 1
fi

echo
log_success "PEM certificate generated successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Certificate Details:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "App: $APP_NAME"
echo "Version: $VERSION"
echo "PEM File: $PEM_OUTPUT_PATH"
echo "Keystore: $KEYSTORE_PATH"
echo "Alias: $keyAlias"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

log_step "Certificate Information:"
echo "Command: keytool -printcert -file \"$PEM_OUTPUT_PATH\""
keytool -printcert -file "$PEM_OUTPUT_PATH" | grep -E "Owner:|Issuer:|Serial number:|Valid from:"
echo

log_step "PEM File Preview (first 5 lines):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
head -n 5 "$PEM_OUTPUT_PATH"
echo "..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

log_step "📱 Google Play Console Instructions:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "To reset your upload key in Google Play Console:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Go to Google Play Console"
echo "2. Select your app"
echo "3. Navigate to Setup > App integrity"
echo "4. In the 'App signing' section, click 'Request upload key reset'"
echo "5. Upload this PEM file: $PEM_OUTPUT_PATH"
echo "6. Follow the remaining instructions in Play Console"
echo
echo "⏰ Note: Key reset requests may take up to 48 hours to process."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

log_step "Verification Commands:"
echo "• Verify PEM certificate:"
echo "  openssl x509 -in \"$PEM_OUTPUT_PATH\" -text -noout"
echo
echo "• View certificate details:"
echo "  keytool -printcert -file \"$PEM_OUTPUT_PATH\""
echo

log_info "📝 Next Steps:"
echo "1. Upload the PEM file to Google Play Console for key reset"
echo "2. Wait for approval from Google Play team"
echo "3. Test with new keystore after approval" 
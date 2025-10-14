#!/bin/bash

# Enhanced App Store Upload Script with Centralized Configuration
# This script uploads iOS apps using configuration from .info/ directory

# Navigate to the root directory relative to the current script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/../../.." || {
    echo "❌ Failed to navigate to the project root directory."
    exit 1
}
ROOT_DIR="."

# Load common configuration functions
source "${ROOT_DIR}/tools/macos/common/common.sh" || {
    echo "❌ Failed to load common configuration library."
    echo "Make sure tools/macos/common/common.sh exists and is readable."
    exit 1
}

# Get default values from centralized configuration
DEFAULT_IPA_PATH=$(get_output_path "ios" "ipa")
DEFAULT_API_KEY=$(get_ios_key_path)
DEFAULT_ISSUER_ID=$(get_ios_issuer_id)
DEFAULT_DISTRIBUTION="appstore"

# Function to display usage information
show_usage() {
    echo "Usage: $(basename "$0") [options]"
    echo ""
    echo "Options:"
    echo "  -f, --file <path>      Path to IPA file or directory containing IPA"
    echo "  -k, --api-key <path>   Path to App Store Connect API key file (.p8)"
    echo "  -i, --issuer-id <id>   App Store Connect API key issuer ID"
    echo "  -d, --distribution <method>  Distribution method (default: $DEFAULT_DISTRIBUTION)"
    echo "                         Available methods:"
    echo "                           - appstore: App Store Connect (production)"
    echo "                           - testflight: TestFlight Internal Testing"
    echo "                           - testing: Release Testing"
    echo "                           - enterprise: Enterprise Distribution"
    echo "                           - debug: Debugging"
    echo "                           - custom: Custom Distribution"
    echo "  -v, --verbose          Enable verbose output"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "This script uses centralized configuration from .info/ directory."
    echo "Default values are read from .info/app/app.json and .info/app/build.json"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") --file=build/ios/ipa/MyApp.ipa"
    echo "  $(basename "$0") --distribution=testflight"
    echo "  $(basename "$0") --api-key=/path/to/AuthKey.p8 --issuer-id=your-issuer-id"
    exit 0
}

# Parse command-line arguments
IPA_PATH="$DEFAULT_IPA_PATH"
API_KEY="$DEFAULT_API_KEY"
ISSUER_ID="$DEFAULT_ISSUER_ID"
DISTRIBUTION="$DEFAULT_DISTRIBUTION"
VERBOSE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f=*|--file=*)
      IPA_PATH="${1#*=}"
      shift
      ;;
    -f|--file)
      IPA_PATH="$2"
      shift 2
      ;;
    -k=*|--api-key=*)
      API_KEY="${1#*=}"
      shift
      ;;
    -k|--api-key)
      API_KEY="$2"
      shift 2
      ;;
    -i=*|--issuer-id=*)
      ISSUER_ID="${1#*=}"
      shift
      ;;
    -i|--issuer-id)
      ISSUER_ID="$2"
      shift 2
      ;;
    -d=*|--distribution=*)
      DISTRIBUTION="${1#*=}"
      shift
      ;;
    -d|--distribution)
      DISTRIBUTION="$2"
      shift 2
      ;;
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    -h|--help)
      show_usage
      ;;
    *)
      log_error "Unknown option: $1"
      echo "Use -h or --help for usage information"
      exit 1
      ;;
  esac
done

# Show configuration summary
log_info "🚀 App Store Upload Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "IPA Path: $IPA_PATH"
echo "API Key: $API_KEY"
echo "Issuer ID: $ISSUER_ID"
echo "Distribution: $DISTRIBUTION"
echo "Verbose: $([ $VERBOSE -eq 1 ] && echo "Yes" || echo "No")"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Validate distribution method
case "$DISTRIBUTION" in
  appstore|testflight|testing|enterprise|debug|custom)
    log_success "Valid distribution method: $DISTRIBUTION"
    ;;
  *)
    log_error "Invalid distribution method: $DISTRIBUTION"
    echo "Available methods: appstore, testflight, testing, enterprise, debug, custom"
    exit 1
    ;;
esac

# Validate API key file
log_step "Validating API key file..."
if [ ! -f "$API_KEY" ]; then
    log_error "API key file not found: $API_KEY"
    
    # Get dynamic key ID from configuration
    KEY_ID=$(get_ios_key_id)
    
    # Check common locations where the key might be
    POSSIBLE_LOCATIONS=(
        ".info/AuthKey_${KEY_ID}.p8"
        "$HOME/private_keys/AuthKey_${KEY_ID}.p8"
        "$HOME/.private_keys/AuthKey_${KEY_ID}.p8"
        "$HOME/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8"
    )
    
    log_info "Checking alternative locations..."
    for LOCATION in "${POSSIBLE_LOCATIONS[@]}"; do
        if [ -f "$LOCATION" ]; then
            log_success "Found API key at: $LOCATION"
            API_KEY="$LOCATION"
            break
        fi
    done
    
    if [ ! -f "$API_KEY" ]; then
        log_error "Could not find API key in any known location."
        log_info "Please ensure the API key file exists and is readable."
        echo "Expected locations:"
        echo "  - .info/AuthKey_${KEY_ID}.p8"
        echo "  - $HOME/private_keys/AuthKey_${KEY_ID}.p8"
        echo "  - $HOME/.private_keys/AuthKey_${KEY_ID}.p8"
        echo "  - $HOME/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8"
        echo ""
        log_info "Update the key path in .info/app/app.json if your key is in a different location."
        exit 1
    fi
fi

log_success "API key validated: $API_KEY"
log_info "Using issuer ID: $ISSUER_ID"

# Find the IPA file
log_step "Locating IPA file..."
if [ -d "$IPA_PATH" ]; then
    log_info "Searching for IPA files in directory: $IPA_PATH"
    IPA_FILE=$(find "$IPA_PATH" -name "*.ipa" | head -n 1)
else
    IPA_FILE="$IPA_PATH"
fi

if [ ! -f "$IPA_FILE" ]; then
    log_error "No IPA file found at path: $IPA_PATH"
    exit 1
fi

log_success "IPA file found: $IPA_FILE"

# Check the bundle version of the IPA
log_step "Checking IPA bundle version..."
# Create a temporary directory
TMP_DIR=$(mktemp -d)
# Unzip the IPA to extract Info.plist
unzip -q "$IPA_FILE" -d "$TMP_DIR"
# Find the Info.plist in the Payload directory
INFO_PLIST=$(find "$TMP_DIR/Payload" -name "Info.plist" | head -n 1)
if [ -f "$INFO_PLIST" ]; then
    # Extract the bundle version and bundle short version string
    BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST" 2>/dev/null)
    BUNDLE_SHORT_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null)
    log_info "📦 IPA App Version: $BUNDLE_SHORT_VERSION (Build $BUNDLE_VERSION)"
else
    log_warning "Could not extract version information from IPA"
    BUNDLE_VERSION="unknown"
    BUNDLE_SHORT_VERSION="unknown"
fi
# Clean up the temporary directory
rm -rf "$TMP_DIR"

# Also get the current version from pubspec.yaml for reference
PUBSPEC_VERSION=$(get_pubspec_version)
if [[ -n "$PUBSPEC_VERSION" ]]; then
    log_info "📄 Current pubspec.yaml version: $PUBSPEC_VERSION"
    
    # If IPA version seems incorrect or unknown, use pubspec version
    if [[ "$BUNDLE_SHORT_VERSION" == "unknown" || "$BUNDLE_SHORT_VERSION" == "9.0.3" ]]; then
        log_warning "IPA version appears incorrect. Using pubspec.yaml version for display."
        # Parse version and build number from pubspec
        if [[ "$PUBSPEC_VERSION" =~ ^([0-9.]+)\+([0-9]+) ]]; then
            BUNDLE_SHORT_VERSION="${BASH_REMATCH[1]}"
            BUNDLE_VERSION="${BASH_REMATCH[2]}"
            log_info "Using version: $BUNDLE_SHORT_VERSION (Build $BUNDLE_VERSION)"
        fi
    fi
fi

# Copy API key to a known location expected by altool
log_step "Preparing API key for altool..."
ALTOOL_KEY_DIR="$HOME/.appstoreconnect/private_keys"
mkdir -p "$ALTOOL_KEY_DIR"

# Get key ID from centralized configuration instead of extracting from filename
KEY_ID=$(get_ios_key_id)

if [[ -z "$KEY_ID" || "$KEY_ID" == "null" ]]; then
    log_error "Key ID not found in configuration"
    log_info "Please ensure ios.keyId is set in .info/app/app.json"
    exit 1
fi

log_info "Using Key ID from configuration: $KEY_ID"

# Extract just the key filename for copying
KEY_FILENAME=$(basename "$API_KEY")

# Copy the key to the expected location
cp "$API_KEY" "$ALTOOL_KEY_DIR/AuthKey_${KEY_ID}.p8"
log_success "API key copied to $ALTOOL_KEY_DIR/AuthKey_${KEY_ID}.p8"

# Get dynamic configuration values
TEAM_ID=$(get_ios_team_id)
BUNDLE_ID=$(get_ios_bundle_id "prod")  # Use prod bundle ID for App Store uploads

# Use xcrun altool to upload to App Store Connect
log_step "🚀 Uploading with distribution method: $DISTRIBUTION..."

# Build upload command using array for proper argument handling
UPLOAD_ARGS=(
    "xcrun" "altool"
    "-f" "$IPA_FILE"
    "--apiKey" "$KEY_ID"
    "--apiIssuer" "$ISSUER_ID"
)

# Configure command based on distribution method
case "$DISTRIBUTION" in
    appstore)
        UPLOAD_ARGS+=("--upload-app" "--type" "ios")
        log_info "📱 Distribution target: App Store Connect (Production)"
        ;;
    testflight)
        UPLOAD_ARGS+=("--upload-app" "--type" "ios")
        if [[ "$BUNDLE_VERSION" != "unknown" ]]; then
            UPLOAD_ARGS+=("--bundle-version" "$BUNDLE_VERSION")
        fi
        if [[ "$BUNDLE_SHORT_VERSION" != "unknown" ]]; then
            UPLOAD_ARGS+=("--bundle-short-version-string" "$BUNDLE_SHORT_VERSION")
        fi
        log_info "✈️ Distribution target: TestFlight Internal Testing"
        ;;
    testing)
        UPLOAD_ARGS+=("--upload-app" "--type" "ios")
        if [[ "$BUNDLE_VERSION" != "unknown" ]]; then
            UPLOAD_ARGS+=("--bundle-version" "$BUNDLE_VERSION")
        fi
        if [[ "$BUNDLE_SHORT_VERSION" != "unknown" ]]; then
            UPLOAD_ARGS+=("--bundle-short-version-string" "$BUNDLE_SHORT_VERSION")
        fi
        log_info "🧪 Distribution target: Release Testing"
        ;;
    enterprise)
        UPLOAD_ARGS+=("--notarize-app" "--primary-bundle-id" "$BUNDLE_ID" "--team-id" "$TEAM_ID")
        log_info "🏢 Distribution target: Enterprise"
        ;;
    debug)
        # For debugging, we'll just validate the app instead of uploading
        UPLOAD_ARGS+=("--validate-app" "--type" "ios")
        log_info "🐞 Distribution target: Debugging (Validation only)"
        ;;
    custom)
        # For custom, we'll provide the most flexible options
        UPLOAD_ARGS+=("--upload-app" "--type" "ios")
        log_info "🔧 Distribution target: Custom"
        ;;
esac

# Add verbose flag if requested
if [ $VERBOSE -eq 1 ]; then
    UPLOAD_ARGS+=("--verbose")
fi

# Print the complete command that will be executed
echo
log_step "Executing upload command:"
echo "Command: ${UPLOAD_ARGS[*]}"
echo

# Use a temporary file to capture output
TEMP_OUTPUT=$(mktemp)
"${UPLOAD_ARGS[@]}" > "$TEMP_OUTPUT" 2>&1
UPLOAD_STATUS=$?

# Check for version conflict error
if grep -q "bundle version must be higher" "$TEMP_OUTPUT"; then
    log_error "Version conflict detected!"
    echo
    log_info "🔍 Diagnosis: You're trying to upload a build with the same version number as one that's already in App Store Connect."
    echo
    
    # Extract the previous version from the error message if possible
    PREV_VERSION=$(grep -o "previously uploaded version: '[0-9]*'" "$TEMP_OUTPUT" | grep -o "'[0-9]*'" | tr -d "'")
    if [ -n "$PREV_VERSION" ]; then
        log_info "Current build number in App Store Connect: $PREV_VERSION"
        log_info "Your IPA build number: $BUNDLE_VERSION"
        echo
        log_warning "You need to increase your build number to at least $((PREV_VERSION+1))"
    fi
    
    echo
    log_info "📝 How to fix this issue:"
    echo "1. Open your project in Xcode"
    echo "2. Select your target"
    echo "3. Go to the 'General' tab"
    echo "4. Increase the 'Build' number (not the 'Version' number)"
    echo "5. Rebuild your IPA with the new build number"
    echo
    echo "Alternatively, update the build number in Flutter:"
    echo "1. Edit ios/Runner/Info.plist or"
    echo "2. Update version in pubspec.yaml to a higher build number:"
    echo "   version: $BUNDLE_SHORT_VERSION+$((BUNDLE_VERSION+1))"
  
    # Output the actual error for reference
    echo
    echo "📋 Original error:"
    cat "$TEMP_OUTPUT"
    
    # Clean up
    rm "$TEMP_OUTPUT"
    exit 1
elif [ $UPLOAD_STATUS -ne 0 ]; then
    log_error "Failed to upload to App Store Connect (error code: $UPLOAD_STATUS)."
    echo
    echo "📋 Error details:"
    cat "$TEMP_OUTPUT"
    echo
    log_info "Common issues:"
    echo "1. API key or issuer ID might be incorrect"
    echo "2. The API key may not have sufficient permissions"
    echo "3. The API key file format might be incorrect"
    echo "4. There might be networking issues"
    echo
    log_info "For more details, try running with --verbose flag"
    
    # Clean up
    rm "$TEMP_OUTPUT"
    exit 1
else
    # Success - display output
    cat "$TEMP_OUTPUT"
    rm "$TEMP_OUTPUT"
    
    echo
    log_success "🎉 Successfully uploaded to App Store Connect!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "App Version: $BUNDLE_SHORT_VERSION (Build $BUNDLE_VERSION)"
    echo "Distribution: $DISTRIBUTION"
    echo "Bundle ID: $BUNDLE_ID"
    echo "Status: Upload Complete"
    echo ""
    echo "Next steps:"
    echo "• Check App Store Connect: https://appstoreconnect.apple.com"
    echo "• Monitor processing status for your build"
    echo "• Submit for review when ready"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi 
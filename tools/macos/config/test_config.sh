#!/bin/bash

# Configuration Testing Script
# This script validates the centralized configuration setup

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

log_info "🧪 Testing centralized configuration setup..."

# Test 1: Environment validation
echo
log_step "Test 1: Environment Validation"
if validate_environment; then
    log_success "Environment validation passed"
else
    log_error "Environment validation failed"
    exit 1
fi

# Test 2: Configuration reading
echo
log_step "Test 2: Configuration Reading"

# Test app configuration
APP_NAME=$(get_app_name)
if [[ -n "$APP_NAME" && "$APP_NAME" != "null" ]]; then
    log_success "App name: $APP_NAME"
else
    log_error "Failed to read app name"
fi

# Test version reading from pubspec.yaml
PUBSPEC_VERSION=$(get_pubspec_version)
if [[ -n "$PUBSPEC_VERSION" ]]; then
    log_success "Version from pubspec.yaml: $PUBSPEC_VERSION"
else
    log_error "Failed to read version from pubspec.yaml"
fi

# Test Firebase configuration (legacy format)
FIREBASE_PROJECT=$(get_firebase_project_id)
if [[ -n "$FIREBASE_PROJECT" && "$FIREBASE_PROJECT" != "null" ]]; then
    log_success "Firebase project (default): $FIREBASE_PROJECT"
else
    log_warning "Default Firebase project ID not found (using per-flavor projects)"
fi

# Test per-flavor Firebase projects
for flavor in dev stg prod; do
    FLAVOR_PROJECT=$(get_firebase_project_id "$flavor")
    if [[ -n "$FLAVOR_PROJECT" && "$FLAVOR_PROJECT" != "null" ]]; then
        log_success "Firebase project ($flavor): $FLAVOR_PROJECT"
    else
        log_warning "Firebase project for $flavor not configured"
    fi
done

# Test 3: Flavor configurations
echo
log_step "Test 3: Flavor Configurations"

for flavor in dev stg prod; do
    log_info "Testing $flavor flavor..."
    
    # Test package names
    ANDROID_PACKAGE=$(get_android_package_name "$flavor")
    IOS_BUNDLE=$(get_ios_bundle_id "$flavor")
    ENV_FILE=$(get_env_file_path "$flavor")
    
    if [[ -n "$ANDROID_PACKAGE" && "$ANDROID_PACKAGE" != "null" ]]; then
        log_success "$flavor Android package: $ANDROID_PACKAGE"
    else
        log_warning "$flavor Android package not configured"
    fi
    
    if [[ -n "$IOS_BUNDLE" && "$IOS_BUNDLE" != "null" ]]; then
        log_success "$flavor iOS bundle: $IOS_BUNDLE"
    else
        log_warning "$flavor iOS bundle not configured"
    fi
    
    if [[ -f "$ENV_FILE" ]]; then
        log_success "$flavor environment file exists: $ENV_FILE"
    else
        log_warning "$flavor environment file missing: $ENV_FILE"
    fi
done

# Test 4: Build configuration
echo
log_step "Test 4: Build Configuration"

FLUTTER_CMD=$(get_flutter_command)
log_info "Flutter command: $FLUTTER_CMD"

# Test output paths
APK_PATH=$(get_output_path "android" "apk")
BUNDLE_PATH=$(get_output_path "android" "appbundle")
IOS_PATH=$(get_output_path "ios" "app")

log_info "Android APK output: $APK_PATH"
log_info "Android Bundle output: $BUNDLE_PATH"
log_info "iOS output: $IOS_PATH"

# Test 5: Script permissions
echo
log_step "Test 5: Script Permissions"

SCRIPT_COUNT=0
EXECUTABLE_COUNT=0

for script in $(find tools/macos -name "*.sh" -type f); do
    SCRIPT_COUNT=$((SCRIPT_COUNT + 1))
    if [[ -x "$script" ]]; then
        EXECUTABLE_COUNT=$((EXECUTABLE_COUNT + 1))
    else
        log_warning "Script not executable: $script"
    fi
done

log_info "Found $SCRIPT_COUNT scripts, $EXECUTABLE_COUNT executable"

if [[ $SCRIPT_COUNT -eq $EXECUTABLE_COUNT ]]; then
    log_success "All scripts are executable"
else
    log_warning "Some scripts may need chmod +x"
fi

# Test 6: Required tools
echo
log_step "Test 6: Required Tools"

TOOLS_OK=true

# Check Flutter
if command -v flutter >/dev/null 2>&1; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    log_success "Flutter: $FLUTTER_VERSION"
else
    log_error "Flutter not found"
    TOOLS_OK=false
fi

# Check jq
if command -v jq >/dev/null 2>&1; then
    JQ_VERSION=$(jq --version)
    log_success "jq: $JQ_VERSION"
else
    log_error "jq not found - install with: brew install jq"
    TOOLS_OK=false
fi

# Check Firebase CLI (optional)
if command -v firebase >/dev/null 2>&1; then
    FIREBASE_VERSION=$(firebase --version)
    log_success "Firebase CLI: $FIREBASE_VERSION"
else
    log_warning "Firebase CLI not found (optional) - install with: npm install -g firebase-tools"
fi

# Check version manager configuration
VERSION_MANAGER_CONFIG=$(get_build_config '.flutter.versionManager')
CONFIG_TYPE=$(echo "$VERSION_MANAGER_CONFIG" | jq -r 'type' 2>/dev/null)

if [[ "$CONFIG_TYPE" == "array" ]]; then
    log_info "Version manager mode: Auto-detect"
    log_info "Priority order: $(echo "$VERSION_MANAGER_CONFIG" | jq -r 'join(", ")' 2>/dev/null)"
elif [[ -n "$VERSION_MANAGER_CONFIG" && "$VERSION_MANAGER_CONFIG" != "null" ]]; then
    log_info "Version manager mode: Force ($VERSION_MANAGER_CONFIG)"
else
    log_info "Version manager mode: Default (system Flutter)"
fi

# Test auto-detection
DETECTED_VM=$(detect_version_manager false)
log_success "Detected version manager: $DETECTED_VM"

# Check cache configuration
CACHE_ENABLED=$(get_build_config '.flutter.versionManagerCache // true')
if [[ "$CACHE_ENABLED" != "false" ]]; then
    log_success "Cache: Enabled"
    CACHED_VM=$(get_cached_version_manager)
    if [[ -n "$CACHED_VM" ]]; then
        log_info "Cached version manager: $CACHED_VM"
    else
        log_info "Cache empty (will be populated on first use)"
    fi
else
    log_info "Cache: Disabled"
fi

# Check what's actually installed
echo
log_step "Available version managers:"
if command -v puro >/dev/null 2>&1; then
    PURO_VERSION=$(puro --version 2>&1 | head -n 1)
    log_success "Puro: $PURO_VERSION"
else
    log_info "Puro: Not installed"
fi

if command -v fvm >/dev/null 2>&1; then
    FVM_VERSION=$(fvm --version)
    log_success "FVM: $FVM_VERSION"
else
    log_info "FVM: Not installed"
fi

# Final result
echo
if [[ "$TOOLS_OK" == "true" ]]; then
    log_success "🎉 Configuration test completed successfully!"
    echo
    echo "Your project is ready to use the enhanced tools:"
    echo "  • Build APK: ./tools/macos/build/build_apk.sh dev"
    echo "  • Build Bundle: ./tools/macos/build/build_appbundle.sh prod"
    echo "  • Build iOS: ./tools/macos/build/build_ios.sh stg"
    echo "  • Setup Project: ./tools/macos/config/setup_project.sh"
    echo
else
    log_error "❌ Configuration test failed!"
    echo "Please install missing tools and run this test again."
    exit 1
fi

# Display configuration summary for dev flavor
echo
show_config_summary "dev"
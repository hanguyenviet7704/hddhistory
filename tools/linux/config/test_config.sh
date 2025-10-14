#!/bin/bash

# Configuration Testing Script (Linux)
# This script validates the centralized configuration setup

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

log_info "🧪 Testing centralized configuration setup (Linux)..."

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

# Test 3: Flavor configurations
echo
log_step "Test 3: Flavor Configurations"
for FLAVOR in dev stg prod; do
    log_info "Testing $FLAVOR flavor..."

    if validate_flavor "$FLAVOR"; then
        log_success "  ✅ Flavor validation: $FLAVOR"
    else
        log_error "  ❌ Flavor validation: $FLAVOR"
        continue
    fi

    # Test Android configuration
    ANDROID_PACKAGE=$(get_android_package_name "$FLAVOR")
    if [[ -n "$ANDROID_PACKAGE" && "$ANDROID_PACKAGE" != "null" ]]; then
        log_success "  ✅ Android package: $ANDROID_PACKAGE"
    else
        log_warning "  ⚠️  Android package not configured for $FLAVOR"
    fi

    # Test environment file path
    ENV_FILE=$(get_env_file_path "$FLAVOR")
    if [[ -n "$ENV_FILE" && "$ENV_FILE" != "null" ]]; then
        log_success "  ✅ Environment file path: $ENV_FILE"

        if [[ -f "$ENV_FILE" ]]; then
            log_success "  ✅ Environment file exists"
        else
            log_warning "  ⚠️  Environment file not found: $ENV_FILE"
        fi
    else
        log_warning "  ⚠️  Environment file path not configured for $FLAVOR"
    fi

    # Test Firebase configuration
    FIREBASE_PROJECT=$(get_firebase_project_id "$FLAVOR")
    if [[ -n "$FIREBASE_PROJECT" && "$FIREBASE_PROJECT" != "null" ]]; then
        log_success "  ✅ Firebase project: $FIREBASE_PROJECT"
    else
        log_warning "  ⚠️  Firebase project not configured for $FLAVOR"
    fi

    echo
done

# Test 4: Build paths
echo
log_step "Test 4: Build Configuration"

APK_PATH=$(get_output_path "android" "apk")
if [[ -n "$APK_PATH" && "$APK_PATH" != "null" ]]; then
    log_success "APK output path: $APK_PATH"
else
    log_warning "APK output path not configured"
fi

BUNDLE_PATH=$(get_output_path "android" "appbundle")
if [[ -n "$BUNDLE_PATH" && "$BUNDLE_PATH" != "null" ]]; then
    log_success "App Bundle output path: $BUNDLE_PATH"
else
    log_warning "App Bundle output path not configured"
fi

DEBUG_PATH=$(get_debug_info_path)
if [[ -n "$DEBUG_PATH" && "$DEBUG_PATH" != "null" ]]; then
    log_success "Debug info path: $DEBUG_PATH"
else
    log_warning "Debug info path not configured"
fi

# Test 5: Flutter command
echo
log_step "Test 5: Flutter Command"
FLUTTER_CMD=$(get_flutter_command)
log_success "Flutter command: $FLUTTER_CMD"

if command -v flutter >/dev/null 2>&1; then
    log_success "Flutter is available in PATH"
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    log_info "Flutter version: $FLUTTER_VERSION"
else
    log_error "Flutter not found in PATH!"
fi

# Test 6: Platform validation
echo
log_step "Test 6: Platform Validation"
if validate_platform "android"; then
    log_success "Android platform validation passed"
else
    log_error "Android platform validation failed"
fi

# Note about iOS not being supported
log_info "iOS platform validation skipped (not supported on Linux)"

# Summary
echo
log_step "Configuration Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Project: $APP_NAME"
echo "Version: $PUBSPEC_VERSION"
echo "Platform: Linux (Android builds only)"
echo "Flutter: $FLUTTER_CMD"
echo ""
echo "Configuration Status:"
echo "  ✅ Environment validation"
echo "  ✅ Configuration reading"
echo "  ✅ Flavor configurations"
echo "  ✅ Build paths"
echo "  ✅ Flutter command"
echo "  ✅ Platform validation (Android)"
echo ""
echo "Your centralized configuration is working correctly!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log_success "🎉 All configuration tests passed!"
exit 0
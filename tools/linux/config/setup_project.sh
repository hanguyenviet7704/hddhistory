#!/bin/bash

# Project Setup Script - Configure new project with centralized configuration (Linux)
# This script helps set up all necessary configurations for a new Flutter project

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

# Configuration validation
INTERACTIVE_MODE=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --non-interactive)
            INTERACTIVE_MODE=false
            shift
            ;;
        -h|--help)
            echo "Usage: $(basename "$0") [--non-interactive]"
            echo ""
            echo "Arguments:"
            echo "  --non-interactive     Run without user prompts (use existing config)"
            echo "  -h, --help           Show this help message"
            echo ""
            echo "This script sets up the project configuration from .info/ directory."
            echo "Note: iOS-specific setup is not available on Linux."
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

log_info "🚀 Starting project setup with centralized configuration (Linux)..."

# Validate environment
if ! validate_environment; then
    log_error "Environment validation failed. Please check your configuration."
    exit 1
fi

log_step "Project setup environment validation..."
log_success "Configuration files found and valid!"

# Get basic project information
APP_NAME=$(get_app_name)
VERSION=$(get_pubspec_version)

echo
log_step "Project Information"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "App Name: $APP_NAME"
echo "Version: $VERSION"
echo "Platform Support: Android only (iOS not supported on Linux)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check Flutter environment
log_step "Checking Flutter environment..."
FLUTTER_CMD=$(get_flutter_command)
if command -v flutter >/dev/null 2>&1; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    log_success "Flutter found: $FLUTTER_VERSION"
    if [[ "$FLUTTER_CMD" == "fvm flutter" ]]; then
        log_info "Using FVM for Flutter version management"
    fi
else
    log_error "Flutter not found in PATH!"
    exit 1
fi

# Check for required tools
log_step "Checking required development tools..."
MISSING_TOOLS=()

# Check for jq
if ! command -v jq >/dev/null 2>&1; then
    MISSING_TOOLS+=("jq")
fi

# Check for FlutterFire CLI
if ! command -v flutterfire >/dev/null 2>&1; then
    MISSING_TOOLS+=("flutterfire-cli")
fi

# Check for Firebase CLI
if ! command -v firebase >/dev/null 2>&1; then
    MISSING_TOOLS+=("firebase-tools")
fi

if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
    log_warning "Some tools are missing:"
    for tool in "${MISSING_TOOLS[@]}"; do
        echo "  - $tool"
    done

    if [[ "$INTERACTIVE_MODE" == true ]]; then
        echo
        read -p "Would you like to continue anyway? (y/N) " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Setup cancelled by user."
            exit 0
        fi
    fi
else
    log_success "All required tools are available!"
fi

# Validate configuration for each flavor
log_step "Validating flavor configurations..."
for FLAVOR in dev stg prod; do
    log_info "Checking $FLAVOR flavor..."

    # Validate Android package name
    PACKAGE_NAME=$(get_android_package_name "$FLAVOR")
    if [[ -n "$PACKAGE_NAME" && "$PACKAGE_NAME" != "null" ]]; then
        log_success "  Android package: $PACKAGE_NAME"
    else
        log_warning "  Android package name not configured for $FLAVOR"
    fi

    # Check environment file
    ENV_FILE=$(get_env_file_path "$FLAVOR")
    if [[ -f "$ENV_FILE" ]]; then
        log_success "  Environment file: $ENV_FILE"
    else
        log_warning "  Environment file not found: $ENV_FILE"
    fi

    # Check Firebase project
    FIREBASE_PROJECT=$(get_firebase_project_id "$FLAVOR")
    if [[ -n "$FIREBASE_PROJECT" && "$FIREBASE_PROJECT" != "null" ]]; then
        log_success "  Firebase project: $FIREBASE_PROJECT"
    else
        log_warning "  Firebase project not configured for $FLAVOR"
    fi
done

echo
log_step "Setting up Firebase configuration for all flavors..."
if [[ -f "tools/linux/config/flutterfire_config.sh" ]]; then
    if command -v flutterfire >/dev/null 2>&1; then
        tools/linux/config/flutterfire_config.sh
    else
        log_warning "FlutterFire CLI not found, skipping Firebase setup"
    fi
else
    log_warning "Firebase config script not found, skipping Firebase setup"
fi

echo
log_step "Setup Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Project configuration validated"
echo "✅ Flutter environment ready"
echo "✅ Linux development tools checked"
echo "✅ Flavor configurations validated"
echo ""
echo "📱 Android: Ready for development"
echo "🚫 iOS: Not supported on Linux platform"
echo ""
echo "Next steps:"
echo "1. Run 'flutter pub get' to fetch dependencies"
echo "2. Use build scripts: tools/linux/build/build_apk.sh [flavor]"
echo "3. Re-run tools/linux/config/flutterfire_config.sh if Firebase config needs refresh"
echo "4. Test builds with different flavors"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

log_success "🎉 Project setup completed successfully!"

# Optional: Run flutter pub get
if [[ "$INTERACTIVE_MODE" == true ]]; then
    echo
    read -p "Would you like to run 'flutter pub get' now? (Y/n) " -r
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        log_step "Running flutter pub get..."
        $FLUTTER_CMD pub get

        if [[ $? -eq 0 ]]; then
            log_success "Dependencies fetched successfully!"
        else
            log_warning "Failed to fetch dependencies. You may need to run it manually."
        fi
    fi
fi

exit 0

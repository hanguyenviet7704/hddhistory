#!/bin/bash

# Project Setup Script - Configure new project with centralized configuration
# This script helps set up all necessary configurations for a new Flutter project

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
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

log_info "🚀 Starting project setup with centralized configuration..."

# Validate environment
if ! validate_environment; then
    log_error "Environment validation failed. Please check your configuration files."
    exit 1
fi

# Function to prompt for user input (if interactive)
prompt_user() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    if [[ "$INTERACTIVE_MODE" == "true" ]]; then
        read -p "$prompt [$default]: " user_input
        if [[ -z "$user_input" ]]; then
            eval "$var_name=\"$default\""
        else
            eval "$var_name=\"$user_input\""
        fi
    else
        eval "$var_name=\"$default\""
    fi
}

# Display current configuration
log_step "Current Project Configuration"
show_config_summary "dev"

if [[ "$INTERACTIVE_MODE" == "true" ]]; then
    echo
    read -p "Do you want to continue with this configuration? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "Setup cancelled by user."
        exit 0
    fi
fi

# Setup Flutter environment
log_step "Setting up Flutter environment..."

# Check Flutter version
FLUTTER_CMD=$(get_flutter_command)
log_info "Using Flutter command: $FLUTTER_CMD"

$FLUTTER_CMD --version

# Get dependencies
log_step "Getting Flutter dependencies..."
$FLUTTER_CMD pub get

# Generate code
log_step "Generating code (build_runner)..."
$FLUTTER_CMD pub run build_runner build --delete-conflicting-outputs

# Setup Firebase for all flavors
log_step "Setting up Firebase configuration for all flavors..."

for flavor in dev stg prod; do
    log_info "Configuring Firebase for $flavor..."
    
    if [[ -f "tools/macos/config/flutterfire_config.sh" ]]; then
        tools/macos/config/flutterfire_config.sh "$flavor"
    else
        log_warning "Firebase config script not found, skipping $flavor"
    fi
done

# Generate app icons
log_step "Generating app icons..."
if command -v flutter_launcher_icons >/dev/null 2>&1; then
    $FLUTTER_CMD pub run flutter_launcher_icons
else
    log_warning "flutter_launcher_icons not found, skipping icon generation"
fi

# Generate localization
log_step "Generating localization..."
if [[ -f "l10n.yaml" ]]; then
    $FLUTTER_CMD gen-l10n
else
    log_warning "l10n.yaml not found, skipping localization generation"
fi

# Validate environment files
log_step "Validating environment files..."
for flavor in dev stg prod; do
    ENV_FILE=$(get_env_file_path "$flavor")
    if [[ -f "$ENV_FILE" ]]; then
        log_success "Environment file exists: $ENV_FILE"
    else
        log_warning "Environment file missing: $ENV_FILE"
    fi
done

# Create output directories
log_step "Creating build output directories..."
mkdir -p "$(get_output_path "android" "apk")"
mkdir -p "$(get_output_path "android" "appbundle")"
mkdir -p "$(get_output_path "ios" "app")"
mkdir -p "$(get_output_path "ios" "ipa")"
mkdir -p "$(get_debug_info_path)"

# Set proper permissions for scripts
log_step "Setting executable permissions for scripts..."
find tools/macos -name "*.sh" -type f -exec chmod +x {} \;

# Final validation
log_step "Running final validation..."

# Check if all flavors can be built (dry run)
for flavor in dev stg prod; do
    log_info "Validating $flavor flavor configuration..."
    
    # Check environment file
    ENV_FILE=$(get_env_file_path "$flavor")
    if [[ ! -f "$ENV_FILE" ]]; then
        log_error "Missing environment file for $flavor: $ENV_FILE"
        continue
    fi
    
    # Check Firebase configuration
    FIREBASE_OPTIONS_FILE="lib/config/services/firebase/firebase_options_$flavor.dart"
    if [[ ! -f "$FIREBASE_OPTIONS_FILE" ]]; then
        log_warning "Missing Firebase options for $flavor: $FIREBASE_OPTIONS_FILE"
    fi
    
    log_success "$flavor flavor configuration validated"
done

# Display setup summary
echo
log_success "🎉 Project setup completed successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Project: $(get_app_name)"
echo "Firebase Project: $(get_firebase_project_id)"
echo ""
echo "Available commands:"
echo "  🔨 Build APK:        ./tools/macos/build/build_apk.sh [flavor]"
echo "  📦 Build Bundle:     ./tools/macos/build/build_appbundle.sh [flavor]"
echo "  🍎 Build iOS:        ./tools/macos/build/build_ios.sh [flavor]"
echo "  🔥 Configure Firebase: ./tools/macos/config/flutterfire_config.sh [flavor]"
echo ""
echo "Available flavors: dev, stg, prod"
echo ""
echo "📝 To customize for a new project:"
echo "  1. Edit configurations in .info/ directory"
echo "  2. Update environment files in .env/ directory"
echo "  3. Run this setup script again"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Optional: Run a test build
if [[ "$INTERACTIVE_MODE" == "true" ]]; then
    echo
    read -p "Would you like to run a test build for dev flavor? (y/n): " test_build
    if [[ "$test_build" == "y" || "$test_build" == "Y" ]]; then
        log_step "Running test build for dev flavor..."
        tools/macos/build/build_apk.sh dev
    fi
fi

log_success "Setup complete! Your project is ready for development."
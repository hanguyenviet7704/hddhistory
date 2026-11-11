#!/bin/bash
#
# Enhanced Common paths configuration for Artlexis scripts (Linux)
# This file defines standard paths used across all scripts and integrates with centralized configuration
# Usage: source "$(dirname "$0")/../common/paths.sh"
#

# Determine script locations
CALLING_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${CALLING_SCRIPT_DIR}"

# Define standard directory structure
# COMMON_DIR is tools/linux/common, so go up two levels to get to tools
TOOLS_DIR="$(cd "${COMMON_DIR}/../.." && pwd)"

# Use PROJECT_ROOT from common.sh if available, otherwise calculate ROOT_DIR
if [[ -n "${PROJECT_ROOT}" ]]; then
    ROOT_DIR="${PROJECT_ROOT}"
else
    ROOT_DIR="$(cd "${TOOLS_DIR}/.." && pwd)"
fi

# Platform-specific tools directories
MACOS_TOOLS_DIR="${TOOLS_DIR}/macos"
LINUX_TOOLS_DIR="${TOOLS_DIR}/linux"
WINDOWS_TOOLS_DIR="${TOOLS_DIR}/windows"

# Functional directories (Linux specific)
BUILD_DIR="${LINUX_TOOLS_DIR}/build"
CONFIG_DIR="${LINUX_TOOLS_DIR}/config"
DISTRIBUTION_DIR="${LINUX_TOOLS_DIR}/distribution"
KEY_DIR="${LINUX_TOOLS_DIR}/key"

# Load centralized configuration (only if not already loaded)
if [[ -z "${PROJECT_ROOT}" ]] && [[ -f "${ROOT_DIR}/tools/linux/common/common.sh" ]]; then
    source "${ROOT_DIR}/tools/linux/common/common.sh"
fi

# Set configuration file paths
if [[ -n "${PROJECT_ROOT}" ]]; then
    # Use paths from common.sh if available
    FIREBASE_INFO_FILE="${PROJECT_ROOT}/.info/app/firebase.json"
    APP_CONFIG_FILE="${PROJECT_ROOT}/.info/app/app.json"
    BUILD_CONFIG_FILE="${PROJECT_ROOT}/.info/app/build.json"
    PATHS_CONFIG_FILE="${PROJECT_ROOT}/.info/app/paths.json"
else
    # Fallback to hardcoded paths if centralized config is not available
    FIREBASE_INFO_FILE="${ROOT_DIR}/.info/firebase_info.json"
    APP_CONFIG_FILE="${ROOT_DIR}/.info/app/app.json"
    BUILD_CONFIG_FILE=""
    PATHS_CONFIG_FILE=""
fi

# Project paths
PUBSPEC_FILE="${ROOT_DIR}/pubspec.yaml"
L10N_FILE="${ROOT_DIR}/l10n.yaml"
FLAVORIZR_FILE="${ROOT_DIR}/flavorizr.yaml"

# Build output directories (with fallbacks) - Android only for Linux
if command -v jq >/dev/null 2>&1 && [[ -f "$BUILD_CONFIG_FILE" ]]; then
    ANDROID_APK_OUTPUT=$(jq -r '.flutter.outputPaths.android.apk // "build/app/outputs/flutter-apk"' "$BUILD_CONFIG_FILE")
    ANDROID_BUNDLE_OUTPUT=$(jq -r '.flutter.outputPaths.android.appbundle // "build/app/outputs/bundle"' "$BUILD_CONFIG_FILE")
    DEBUG_SYMBOLS_DIR=$(jq -r '.flutter.outputPaths.debugInfo // ".obfuscation"' "$BUILD_CONFIG_FILE")
else
    # Fallback to hardcoded paths
    ANDROID_APK_OUTPUT="${ROOT_DIR}/build/app/outputs/flutter-apk"
    ANDROID_BUNDLE_OUTPUT="${ROOT_DIR}/build/app/outputs/bundle"
    DEBUG_SYMBOLS_DIR="${ROOT_DIR}/.obfuscation"
fi

# Legacy compatibility
ANDROID_OUTPUT_DIR="${ROOT_DIR}/build/app/outputs"

# Environment files directory
ENV_DIR="${ROOT_DIR}/.env"

# Export paths so they're available in sourced scripts
export ROOT_DIR TOOLS_DIR
export MACOS_TOOLS_DIR LINUX_TOOLS_DIR WINDOWS_TOOLS_DIR
export BUILD_DIR CONFIG_DIR DISTRIBUTION_DIR KEY_DIR
export FIREBASE_INFO_FILE APP_CONFIG_FILE BUILD_CONFIG_FILE PATHS_CONFIG_FILE
export PUBSPEC_FILE L10N_FILE FLAVORIZR_FILE
export ANDROID_OUTPUT_DIR ANDROID_APK_OUTPUT ANDROID_BUNDLE_OUTPUT
export DEBUG_SYMBOLS_DIR
export ENV_DIR

# Convenience function to display current paths configuration
show_paths_config() {
    echo "=== Project Paths Configuration (Linux) ==="
    echo "Root Directory: $ROOT_DIR"
    echo "Tools Directory: $TOOLS_DIR"
    echo "Info Directory: ${ROOT_DIR}/.info"
    echo ""
    echo "=== Configuration Files ==="
    echo "App Config: $APP_CONFIG_FILE"
    echo "Firebase Config: $FIREBASE_INFO_FILE"
    echo "Build Config: $BUILD_CONFIG_FILE"
    echo "Paths Config: $PATHS_CONFIG_FILE"
    echo ""
    echo "=== Build Output Paths ==="
    echo "Android APK: $ANDROID_APK_OUTPUT"
    echo "Android Bundle: $ANDROID_BUNDLE_OUTPUT"
    echo "Debug Symbols: $DEBUG_SYMBOLS_DIR"
    echo "Note: iOS builds not supported on Linux"
    echo "=================================="
}
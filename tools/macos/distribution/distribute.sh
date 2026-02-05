#!/bin/bash

# Enable strict error handling
set -e

# Define directory structure with clean paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ROOT_DIR="$(cd "${TOOLS_DIR}/.." && pwd)"

# Use clean path references
MACOS_TOOLS_DIR="${TOOLS_DIR}/macos"
DISTRIBUTION_DIR="${MACOS_TOOLS_DIR}/distribution"
FIREBASE_INFO_FILE="${ROOT_DIR}/.info/firebase_info.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Function to show usage
show_usage() {
    echo "🚀 Firebase App Distribution - Universal Tool"
    echo ""
    echo "Usage: $(basename "$0") [platform] [build_type] [flavor] [options]"
    echo ""
    echo "Arguments:"
    echo "  platform:     android, ios, or both"
    echo "  build_type:   For Android: apk, appbundle, or both"
    echo "                For iOS: ipa"
    echo "  flavor:       dev, stg, or prod"
    echo ""
    echo "Options:"
    echo "  build_first   Build before distributing"
    echo "  file_path     Specific path to build file (for single file distribution)"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") android apk dev build_first          # Build and distribute APK for dev"
    echo "  $(basename "$0") ios ipa prod                         # Distribute existing IPA for prod"
    echo "  $(basename "$0") both both stg build_first            # Build and distribute all formats for staging"
    echo "  $(basename "$0") android appbundle dev path/to.aab    # Distribute specific App Bundle"
    echo ""
    echo "Quick Commands:"
    echo "  $(basename "$0") quick-dev      # Build and distribute APK for dev (quick testing)"
    echo "  $(basename "$0") quick-stg      # Build and distribute App Bundle for staging"
    echo "  $(basename "$0") quick-prod     # Build and distribute both platforms for production"
}

# Function to check if Firebase info is configured
check_firebase_config() {
    if [[ ! -f "$FIREBASE_INFO_FILE" ]]; then
        print_error "Firebase configuration not found!"
        print_info "Please run the setup script first:"
        print_info "  $DISTRIBUTION_DIR/setup_firebase.sh"
        exit 1
    fi
    
    # Check if it's still using placeholder values
    local project_id=$(jq -r '.projectId' "$FIREBASE_INFO_FILE")
    if [[ "$project_id" == "your-firebase-project-id" ]]; then
        print_warning "Firebase configuration contains placeholder values."
        print_info "Please update .info/firebase_info.json with your actual Firebase project information."
        print_info "Or run the setup script: $DISTRIBUTION_DIR/setup_firebase.sh"
        exit 1
    fi
}

# Function to distribute Android
distribute_android() {
    local build_type="$1"
    local flavor="$2"
    local should_build="$3"
    local file_path="$4"
    
    print_info "📱 Starting Android distribution..."
    
    if [[ "$build_type" == "both" ]]; then
        # Distribute both APK and App Bundle
        print_info "Distributing both APK and App Bundle..."
        
        "$DISTRIBUTION_DIR/distribute_android.sh" "apk" "$flavor" "$should_build"
        if [[ $? -eq 0 ]]; then
            print_success "APK distribution completed!"
        else
            print_error "APK distribution failed!"
            return 1
        fi
        
        "$DISTRIBUTION_DIR/distribute_android.sh" "appbundle" "$flavor" "$should_build"
        if [[ $? -eq 0 ]]; then
            print_success "App Bundle distribution completed!"
        else
            print_error "App Bundle distribution failed!"
            return 1
        fi
    else
        # Distribute specific build type
        if [[ -n "$file_path" ]]; then
            # TODO: Implement specific file path handling
            print_warning "Specific file path not yet implemented for Android script"
        fi
        
        "$DISTRIBUTION_DIR/distribute_android.sh" "$build_type" "$flavor" "$should_build"
        if [[ $? -eq 0 ]]; then
            print_success "Android distribution completed!"
        else
            print_error "Android distribution failed!"
            return 1
        fi
    fi
}

# Function to distribute iOS
distribute_ios() {
    local flavor="$1"
    local should_build="$2"
    local file_path="$3"
    
    print_info "🍎 Starting iOS distribution..."
    
    local args=("$flavor")
    
    if [[ -n "$should_build" ]]; then
        args+=("$should_build")
    fi
    
    if [[ -n "$file_path" ]]; then
        args+=("$file_path")
    fi
    
    "$DISTRIBUTION_DIR/distribute_ios.sh" "${args[@]}"
    if [[ $? -eq 0 ]]; then
        print_success "iOS distribution completed!"
    else
        print_error "iOS distribution failed!"
        return 1
    fi
}

# Function to handle quick commands
handle_quick_command() {
    local command="$1"
    
    case "$command" in
        "quick-dev")
            print_info "🚀 Quick Dev Distribution (APK only)"
            distribute_android "apk" "dev" "build_first"
            ;;
        "quick-stg")
            print_info "🚀 Quick Staging Distribution (App Bundle)"
            distribute_android "appbundle" "stg" "build_first"
            ;;
        "quick-prod")
            print_info "🚀 Quick Production Distribution (Both platforms)"
            distribute_android "appbundle" "prod" "build_first"
            if [[ $? -eq 0 && "$(uname)" == "Darwin" ]]; then
                distribute_ios "prod" "build_first"
            fi
            ;;
        *)
            print_error "Unknown quick command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Main function
main() {
    # Check for quick commands first
    if [[ $# -eq 1 && "$1" =~ ^quick- ]]; then
        check_firebase_config
        handle_quick_command "$1"
        return $?
    fi
    
    # Check arguments
    if [[ $# -lt 3 ]]; then
        show_usage
        exit 1
    fi
    
    local platform="$1"
    local build_type="$2"
    local flavor="$3"
    local should_build="$4"
    local file_path="$5"
    
    # Validate platform
    if [[ "$platform" != "android" && "$platform" != "ios" && "$platform" != "both" ]]; then
        print_error "Invalid platform. Use 'android', 'ios', or 'both'"
        exit 1
    fi
    
    # Validate flavor
    if [[ "$flavor" != "dev" && "$flavor" != "stg" && "$flavor" != "prod" ]]; then
        print_error "Invalid flavor. Use 'dev', 'stg', or 'prod'"
        exit 1
    fi
    
    # Navigate to root directory
    cd "$ROOT_DIR" || {
        print_error "Failed to navigate to the project root directory."
        exit 1
    }
    
    # Check Firebase configuration
    check_firebase_config
    
    print_info "🚀 Starting Firebase App Distribution"
    print_info "Platform: $platform | Build Type: $build_type | Flavor: $flavor"
    
    # Handle distribution based on platform
    case "$platform" in
        "android")
            if [[ "$build_type" != "apk" && "$build_type" != "appbundle" && "$build_type" != "both" ]]; then
                print_error "Invalid build type for Android. Use 'apk', 'appbundle', or 'both'"
                exit 1
            fi
            distribute_android "$build_type" "$flavor" "$should_build" "$file_path"
            ;;
        "ios")
            if [[ "$build_type" != "ipa" ]]; then
                print_error "Invalid build type for iOS. Use 'ipa'"
                exit 1
            fi
            distribute_ios "$flavor" "$should_build" "$file_path"
            ;;
        "both")
            # Distribute Android first
            local android_build_type="$build_type"
            if [[ "$build_type" == "both" ]]; then
                android_build_type="both"
            elif [[ "$build_type" == "ipa" ]]; then
                android_build_type="appbundle"  # Default to App Bundle for production
            fi
            
            distribute_android "$android_build_type" "$flavor" "$should_build"
            
            # Distribute iOS if on macOS
            if [[ "$(uname)" == "Darwin" ]]; then
                distribute_ios "$flavor" "$should_build"
            else
                print_warning "Skipping iOS distribution (not running on macOS)"
            fi
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        print_success "🎉 All distributions completed successfully!"
    else
        print_error "❌ Some distributions failed!"
        exit 1
    fi
}

# Run main function with all arguments
main "$@" 
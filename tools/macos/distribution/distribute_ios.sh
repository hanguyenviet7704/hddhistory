#!/bin/bash

# Firebase App Distribution - iOS Distribution Script
# This script distributes iOS IPA files to Firebase App Distribution using centralized configuration

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the common configuration
source "${SCRIPT_DIR}/../common/common.sh" || {
    echo "❌ Failed to load common configuration"
    exit 1
}

# Additional source for paths if needed
source "${SCRIPT_DIR}/../common/paths.sh" 2>/dev/null || true

# Use centralized build tools directory
BUILD_TOOLS_DIR="${SCRIPT_DIR}/../build"

# Function to show usage
show_usage() {
    echo "Usage: $(basename "$0") [dev|stg|prod] [options]"
    echo ""
    echo "Arguments:"
    echo "  dev|stg|prod     Environment flavor"
    echo ""
    echo "Options:"
    echo "  --build-first           Build IPA before distributing"
    echo "  --ipa <path>            Specific path to IPA file"
    echo "  --method <type>         Distribution method: testflight (default), firebase, both"
    echo "  --dry-run               Show commands without executing"
    echo "  --verbose               Show detailed output"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") dev --build-first                        # TestFlight only (default)"
    echo "  $(basename "$0") dev --build-first --method firebase     # Firebase only"
    echo "  $(basename "$0") dev --build-first --method both         # Both Firebase and TestFlight"
    echo "  $(basename "$0") prod --ipa path/to/app.ipa"
    echo "  $(basename "$0") stg --dry-run"
}

# Function to check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if Firebase CLI is installed
    if ! command -v firebase &> /dev/null; then
        log_error "Firebase CLI is not installed. Please install it first:"
        echo "npm install -g firebase-tools"
        exit 1
    fi
    
    # Check if running on macOS (required for iOS builds)
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "iOS distribution requires macOS"
        exit 1
    fi
    
    # Validate environment using centralized function
    if ! validate_environment; then
        exit 1
    fi
    
    log_success "All prerequisites are met!"
}

# Function to load Firebase configuration
load_firebase_config() {
    local flavor="$1"
    local platform="$2"
    
    PROJECT_ID=$(get_firebase_project_id "$flavor")
    APP_ID=$(get_firebase_app_id "$platform" "$flavor")
    
    # Get testers and groups - combines JSON config and text files
    TESTERS=$(get_all_testers "$flavor")
    FIREBASE_GROUPS=$(get_all_groups "$flavor")
    
    # Allow environment overrides
    TESTERS="${FIREBASE_DISTRIBUTION_TESTERS:-$TESTERS}"
    FIREBASE_GROUPS="${FIREBASE_DISTRIBUTION_GROUP:-$FIREBASE_GROUPS}"
    
    if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "null" || -z "$APP_ID" || "$APP_ID" == "null" ]]; then
        log_error "Firebase configuration not found for flavor: $flavor, platform: $platform"
        exit 1
    fi
    
    log_info "Loaded Firebase config:"
    echo "  ${CYAN}Project ID:${NC} $PROJECT_ID"
    echo "  ${CYAN}App ID:${NC} $APP_ID"
    echo "  ${CYAN}Testers:${NC} ${TESTERS:-'(none)'}"
    echo "  ${CYAN}Groups:${NC} ${FIREBASE_GROUPS:-'(none)'}"
}

# Function to get app version (using centralized function)
get_app_version() {
    get_pubspec_version
}

# Function to distribute to Firebase
distribute_to_firebase() {
    local file_path="$1"
    local flavor="$2"
    local build_type="$3"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "Build file not found: $file_path"
        return 1
    fi
    
    log_info "Distributing $build_type to Firebase App Distribution..."
    
    # Load Firebase configuration
    load_firebase_config "$flavor" "ios"
    
    # Get app version
    local version=$(get_app_version)
    
    # Generate release notes
    generate_release_notes "$flavor" "$version" "$build_type" "iOS"
    
    # Create a temporary file for release notes
    local release_notes_file=$(mktemp)
    printf "%b\n" "$RELEASE_NOTES" > "$release_notes_file"
    
    # Build Firebase distribution command
    local firebase_cmd="firebase appdistribution:distribute \"$file_path\" --project \"$PROJECT_ID\" --app \"$APP_ID\" --release-notes-file \"$release_notes_file\""
    
    # Add testers if configured
    if [[ -n "$TESTERS" && "$TESTERS" != "null" ]]; then
        firebase_cmd="$firebase_cmd --testers \"$TESTERS\""
    fi
    
    # Add groups if configured
    if [[ -n "$FIREBASE_GROUPS" && "$FIREBASE_GROUPS" != "null" ]]; then
        firebase_cmd="$firebase_cmd --groups \"$FIREBASE_GROUPS\""
    fi
    
    # Print the command that will be executed
    log_step "Executing Firebase App Distribution command:"
    echo "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${CYAN}$firebase_cmd${NC}"
    echo "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Execute the Firebase distribution command
    if eval "$firebase_cmd"; then
        log_success "$build_type distributed to Firebase successfully!"
        log_info "Check Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID/appdistribution"
    else
        log_error "Failed to distribute $build_type to Firebase"
        rm -f "$release_notes_file"
        return 1
    fi
    
    # Clean up
    rm -f "$release_notes_file"
    return 0
}

# Function to distribute to TestFlight
distribute_to_testflight() {
    local file_path="$1"
    local flavor="$2"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "Build file not found: $file_path"
        return 1
    fi
    
    log_info "Distributing to TestFlight/App Store Connect..."
    
    # Use the upload_appstore.sh script
    local upload_script="${SCRIPT_DIR}/upload_appstore.sh"
    
    if [[ ! -f "$upload_script" ]]; then
        log_error "Upload script not found: $upload_script"
        return 1
    fi
    
    log_step "Executing TestFlight upload command:"
    echo "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${CYAN}$upload_script --file \"$file_path\"${NC}"
    echo "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if "$upload_script" --file "$file_path"; then
        log_success "IPA uploaded to TestFlight successfully!"
        log_info "Check App Store Connect: https://appstoreconnect.apple.com"
    else
        log_error "Failed to upload to TestFlight"
        return 1
    fi
    
    return 0
}

# Resolve GoogleService-Info.plist for a flavor (fallback to default)
get_ios_gsp_path() {
    local flavor="$1"
    local flavored_path="ios/Runner/${flavor}/GoogleService-Info.plist"
    local default_path="ios/Runner/GoogleService-Info.plist"

    if [[ -f "$flavored_path" ]]; then
        echo "$flavored_path"
        return 0
    fi

    if [[ -f "$default_path" ]]; then
        echo "$default_path"
        return 0
    fi

    return 1
}

# Find a directory containing dSYM files for iOS
find_ios_dsym_dir() {
    local archive_dir
    local ipa_dir
    local app_dir
    local search_dirs=()

    archive_dir=$(get_output_path "ios" "archive" 2>/dev/null)
    [[ -z "$archive_dir" ]] && archive_dir="build/ios/archive"

    ipa_dir=$(get_output_path "ios" "ipa" 2>/dev/null)
    [[ -z "$ipa_dir" ]] && ipa_dir="build/ios/ipa"

    app_dir=$(get_output_path "ios" "app" 2>/dev/null)
    [[ -z "$app_dir" ]] && app_dir="build/ios/iphoneos"

    # Prefer the archive dSYMs folder if available
    if [[ -d "$archive_dir/Runner.xcarchive/dSYMs" ]]; then
        echo "$archive_dir/Runner.xcarchive/dSYMs"
        return 0
    fi

    # Build a safe search list
    for dir in "$archive_dir" "$ipa_dir" "$app_dir" "build/ios"; do
        if [[ -d "$dir" ]]; then
            search_dirs+=("$dir")
        fi
    done

    if [[ ${#search_dirs[@]} -eq 0 ]]; then
        return 1
    fi

    local dsym_path
    dsym_path=$(find "${search_dirs[@]}" -name "Runner.app.dSYM" -type d 2>/dev/null | head -n 1)
    if [[ -n "$dsym_path" ]]; then
        dirname "$dsym_path"
        return 0
    fi

    dsym_path=$(find "${search_dirs[@]}" -name "*.dSYM" -type d 2>/dev/null | head -n 1)
    if [[ -n "$dsym_path" ]]; then
        dirname "$dsym_path"
        return 0
    fi

    return 1
}

# Upload iOS dSYM files to Crashlytics (explicit fallback)
upload_ios_symbols() {
    local flavor="$1"
    local upload_script="ios/Pods/FirebaseCrashlytics/upload-symbols"
    local gsp_path
    local dsym_dir

    if ! dsym_dir=$(find_ios_dsym_dir); then
        log_warning "No iOS dSYM files found; skipping Crashlytics symbol upload."
        return 0
    fi

    if ! gsp_path=$(get_ios_gsp_path "$flavor"); then
        log_warning "GoogleService-Info.plist not found; skipping Crashlytics symbol upload."
        return 0
    fi

    if [[ ! -f "$upload_script" ]]; then
        log_warning "Crashlytics upload-symbols script not found at: $upload_script"
        log_info "Run 'pod install' in ios/ to generate it."
        return 0
    fi

    log_step "Uploading iOS dSYM files to Crashlytics..."
    log_info "dSYM path: $dsym_dir"
    log_info "GoogleService-Info.plist: $gsp_path"

    if "$upload_script" -gsp "$gsp_path" -p ios "$dsym_dir"; then
        log_success "Crashlytics dSYM upload completed."
    else
        log_warning "Crashlytics dSYM upload failed. You can retry manually."
    fi
}

# Main function
main() {
    log_info "🚀 iOS App Distribution"
    
    # Parse arguments
    local flavor=""
    local should_build=false
    local custom_ipa_path=""
    local distribution_method="testflight"  # Default to TestFlight
    local dry_run=false
    local verbose=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            dev|stg|prod)
                flavor="$1"
                shift
                ;;
            --build-first)
                should_build=true
                shift
                ;;
            --ipa)
                custom_ipa_path="$2"
                shift 2
                ;;
            --method)
                distribution_method="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Validate distribution method
    if [[ "$distribution_method" != "firebase" && "$distribution_method" != "testflight" && "$distribution_method" != "both" ]]; then
        log_error "Invalid distribution method: $distribution_method"
        log_info "Valid methods are: firebase, testflight, both"
        exit 1
    fi
    
    # Validate required arguments
    if [[ -z "$flavor" ]]; then
        log_error "Missing required flavor argument"
        show_usage
        exit 1
    fi
    
    # Validate flavor using centralized function
    if ! validate_flavor "$flavor"; then
        exit 1
    fi
    
    # Show configuration summary
    show_config_summary "$flavor" "ios"
    
    # Navigate to root directory
    cd "$PROJECT_ROOT" || {
        log_error "Failed to navigate to the project root directory."
        exit 1
    }
    
    # Check prerequisites
    check_prerequisites
    
    # Build first if requested
    if [[ "$should_build" == true ]]; then
        log_step "Building IPA for $flavor flavor..."
        
        # Determine export method based on distribution method
        local export_method="app-store"  # Default for TestFlight
        if [[ "$distribution_method" == "firebase" ]]; then
            export_method="ad-hoc"
        elif [[ "$distribution_method" == "both" ]]; then
            # For both, we need to build twice (different export methods)
            log_warning "Building for both Firebase and TestFlight requires two builds with different export methods"
            
            # Build for Firebase first (ad-hoc)
            log_info "Building ad-hoc version for Firebase..."
            local firebase_build_cmd="$BUILD_TOOLS_DIR/build_ipa.sh $flavor --export-method ad-hoc"
            
            if [[ "$dry_run" == true ]]; then
                log_info "[DRY RUN] Would execute: $firebase_build_cmd"
            else
                log_step "Executing Firebase build command:"
                echo "${CYAN}$firebase_build_cmd${NC}"
                
                if ! $firebase_build_cmd; then
                    log_error "Firebase build failed!"
                    exit 1
                fi

                upload_ios_symbols "$flavor"
                
                # Save the ad-hoc IPA path
                local ipa_output_dir=$(get_output_path "ios" "ipa" 2>/dev/null || echo "build/ios/ipa")
                local firebase_ipa_path=$(find "$ipa_output_dir" -name "*.ipa" -type f 2>/dev/null | head -n 1)
            fi
            
            # Build for TestFlight (app-store)
            log_info "Building app-store version for TestFlight..."
            export_method="app-store"
        fi
        
        local build_cmd="$BUILD_TOOLS_DIR/build_ipa.sh $flavor --export-method $export_method"
        
        if [[ "$dry_run" == true ]]; then
            log_info "[DRY RUN] Would execute: $build_cmd"
        else
            log_step "Executing build command:"
            echo "${CYAN}$build_cmd${NC}"
            
            if ! $build_cmd; then
                log_error "Build failed!"
                exit 1
            fi

            upload_ios_symbols "$flavor"
        fi
    fi
    
    # Determine IPA path
    local ipa_path
    if [[ -n "$custom_ipa_path" ]]; then
        ipa_path="$custom_ipa_path"
    else
        # Use default build output path from centralized config
        local ipa_output_dir=$(get_output_path "ios" "ipa" 2>/dev/null || echo "build/ios/ipa")
        
        # Determine the expected IPA filename based on flavor
        # For prod, look for files without flavor suffix first (e.g., "Artlexis.ipa")
        # For dev/stg, look for files with flavor suffix (e.g., "Artlexis Dev.ipa", "Artlexis Stg.ipa")
        local expected_patterns=()
        if [[ "$flavor" == "prod" ]]; then
            # For production, prioritize files without flavor suffix
            expected_patterns=("Artlexis.ipa" "artlexis.ipa" "*prod*.ipa" "*Prod*.ipa")
        elif [[ "$flavor" == "dev" ]]; then
            expected_patterns=("*Dev.ipa" "*dev.ipa" "Artlexis Dev.ipa")
        elif [[ "$flavor" == "stg" ]]; then
            expected_patterns=("*Stg.ipa" "*stg.ipa" "*Staging.ipa" "Artlexis Stg.ipa")
        fi
        
        # Try to find the IPA file with the expected pattern
        for pattern in "${expected_patterns[@]}"; do
            ipa_path=$(find "$ipa_output_dir" -name "$pattern" -type f 2>/dev/null | head -n 1)
            if [[ -n "$ipa_path" && -f "$ipa_path" ]]; then
                log_info "Found matching IPA for $flavor: $(basename "$ipa_path")"
                break
            fi
        done
        
        # If no flavor-specific IPA found, try generic patterns
        if [[ -z "$ipa_path" || ! -f "$ipa_path" ]]; then
            # Try specific flavor-based name
            ipa_path="$ipa_output_dir/app-$flavor.ipa"
            
            if [[ ! -f "$ipa_path" ]]; then
                # For production, avoid selecting dev/stg files
                if [[ "$flavor" == "prod" ]]; then
                    # Find any .ipa but exclude dev and stg versions
                    ipa_path=$(find "$ipa_output_dir" -name "*.ipa" -type f 2>/dev/null | grep -v -i "dev\|stg\|staging" | head -n 1)
                else
                    # For dev/stg, just find any .ipa
                    ipa_path=$(find "$ipa_output_dir" -name "*.ipa" -type f 2>/dev/null | head -n 1)
                fi
                
                if [[ -z "$ipa_path" || ! -f "$ipa_path" ]]; then
                    # Try Runner.app for direct distribution
                    ipa_path="build/ios/iphoneos/Runner.app"
                    
                    if [[ ! -e "$ipa_path" ]]; then
                        log_error "IPA file not found in $ipa_output_dir"
                        log_info "Please specify path with --ipa or build first with --build-first"
                        
                        # Show available IPA files for debugging
                        local available_ipas=$(find "$ipa_output_dir" -name "*.ipa" -type f 2>/dev/null)
                        if [[ -n "$available_ipas" ]]; then
                            log_warning "Available IPA files:"
                            echo "$available_ipas" | while read -r file; do
                                echo "  - $(basename "$file")"
                            done
                            log_info "Consider using --ipa <path> to specify the correct file"
                        fi
                        exit 1
                    fi
                fi
            fi
        fi
    fi
    
    # Check if file exists before distribution
    if [[ ! -f "$ipa_path" && ! -d "$ipa_path" ]]; then
        log_error "Build file not found: $ipa_path"
        log_info "Please build the IPA first or use --build-first option"
        exit 1
    fi
    
    log_info "Found build file: $ipa_path"
    if [[ -f "$ipa_path" ]]; then
        log_info "File size: $(du -h "$ipa_path" | cut -f1)"
    fi
    
    if [[ "$dry_run" == true ]]; then
        log_warning "[DRY RUN MODE] - Commands will be shown but not executed"
        exit 0
    fi
    
    # Distribute based on selected method
    local distribution_success=true
    
    case "$distribution_method" in
        firebase)
            if ! distribute_to_firebase "$ipa_path" "$flavor" "IPA"; then
                distribution_success=false
            fi
            ;;
        testflight)
            if ! distribute_to_testflight "$ipa_path" "$flavor"; then
                distribution_success=false
            fi
            ;;
        both)
            # Distribute to Firebase first (using ad-hoc build)
            if [[ -n "$firebase_ipa_path" ]]; then
                log_step "Distributing to Firebase..."
                if ! distribute_to_firebase "$firebase_ipa_path" "$flavor" "IPA"; then
                    distribution_success=false
                fi
            fi
            
            # Then distribute to TestFlight (using app-store build)
            echo ""
            log_step "Distributing to TestFlight..."
            if ! distribute_to_testflight "$ipa_path" "$flavor"; then
                distribution_success=false
            fi
            ;;
    esac
    
    if [[ "$distribution_success" == true ]]; then
        log_success "🎉 Distribution completed successfully!"
    else
        log_error "Distribution failed or completed with errors"
        exit 1
    fi
    
    # Show next steps based on distribution method
    echo ""
    log_info "Next steps:"
    
    if [[ "$distribution_method" == "firebase" || "$distribution_method" == "both" ]]; then
        echo "  📱 Firebase App Distribution:"
        echo "     - Check console: https://console.firebase.google.com/project/$PROJECT_ID/appdistribution"
        echo "     - Testers will receive email invitations"
        echo "     - Monitor installation and feedback"
    fi
    
    if [[ "$distribution_method" == "testflight" || "$distribution_method" == "both" ]]; then
        if [[ "$distribution_method" == "both" ]]; then
            echo ""
        fi
        echo "  ✈️  TestFlight:"
        echo "     - Check App Store Connect: https://appstoreconnect.apple.com"
        echo "     - Add testers in TestFlight"
        echo "     - Submit for external testing (if needed)"
    fi
}

# Run main function with all arguments
main "$@"

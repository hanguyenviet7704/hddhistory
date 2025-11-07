#!/bin/bash

# Enable strict error handling
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

# Function to check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if Firebase CLI is installed
    if ! command -v firebase &> /dev/null; then
        log_error "Firebase CLI is not installed. Please install it first:"
        echo "npm install -g firebase-tools"
        exit 1
    fi
    
    # Validate environment
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
    TESTER_GROUPS=$(get_all_groups "$flavor")
    
    if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "null" || -z "$APP_ID" || "$APP_ID" == "null" ]]; then
        log_error "Firebase configuration not found for flavor: $flavor, platform: $platform"
        exit 1
    fi
    
    log_info "Loaded Firebase config:"
    echo "  ${CYAN}Project ID:${NC} $PROJECT_ID"
    echo "  ${CYAN}App ID:${NC} $APP_ID"
    echo "  ${CYAN}Testers:${NC} ${TESTERS:-'(none)'}"
    echo "  ${CYAN}Groups:${NC} ${TESTER_GROUPS:-'(none)'}"
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
    local dry_run="${4:-false}"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "Build file not found: $file_path"
        exit 1
    fi
    
    log_info "Distributing $build_type to Firebase App Distribution..."
    
    # Load Firebase configuration
    load_firebase_config "$flavor" "android"
    
    # Get app version
    local version=$(get_app_version)
    
    # Generate release notes
    generate_release_notes "$flavor" "$version" "$build_type" "Android"
    
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
    if [[ -n "$TESTER_GROUPS" && "$TESTER_GROUPS" != "null" ]]; then
        firebase_cmd="$firebase_cmd --groups \"$TESTER_GROUPS\""
    fi
    
    # Print the command that will be executed
    log_step "Firebase App Distribution command:"
    echo "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${CYAN}$firebase_cmd${NC}"
    echo "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Execute the Firebase distribution command (skip if dry-run)
    if [[ "$dry_run" == "true" ]]; then
        log_warning "[DRY RUN] Command not executed"
        log_success "Dry-run completed successfully!"
    elif eval "$firebase_cmd"; then
        log_success "$build_type distributed successfully!"
        log_info "Check Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID/appdistribution"
    else
        log_error "Failed to distribute $build_type"
        rm -f "$release_notes_file"
        exit 1
    fi
    
    # Clean up
    rm -f "$release_notes_file"
}

# Function to send Slack notification
send_slack_notification() {
    local flavor="$1"
    local build_type="$2"
    local status="$3"
    
    local webhook_url=$(jq -r '.slack.webhookUrl' "$FIREBASE_INFO_FILE")
    local channel=$(jq -r ".slack.channels.$flavor" "$FIREBASE_INFO_FILE")
    
    if [[ -n "$webhook_url" && "$webhook_url" != "null" && "$webhook_url" != "" ]]; then
        local version=$(get_app_version)
        local emoji="✅"
        local color="good"
        
        if [[ "$status" != "success" ]]; then
            emoji="❌"
            color="danger"
        fi
        
        local payload=$(cat <<EOF
{
    "channel": "$channel",
    "attachments": [
        {
            "color": "$color",
            "title": "$emoji Firebase App Distribution - $build_type",
            "fields": [
                {
                    "title": "Version",
                    "value": "$version",
                    "short": true
                },
                {
                    "title": "Flavor",
                    "value": "$flavor",
                    "short": true
                },
                {
                    "title": "Status",
                    "value": "$status",
                    "short": true
                },
                {
                    "title": "Platform",
                    "value": "Android",
                    "short": true
                }
            ]
        }
    ]
}
EOF
)
        
        curl -X POST -H 'Content-type: application/json' --data "$payload" "$webhook_url" > /dev/null 2>&1 || true
        log_info "Slack notification sent to $channel"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $(basename "$0") [apk|appbundle] [dev|stg|prod] [options]"
    echo ""
    echo "Arguments:"
    echo "  apk|appbundle    Type of build to distribute"
    echo "  dev|stg|prod     Environment flavor"
    echo ""
    echo "Options:"
    echo "  --build-first    Build before distributing"
    echo "  --dry-run        Show what would be executed without actually doing it"
    echo "  --verbose        Show detailed output"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") apk dev --build-first    # Build and distribute APK for dev"
    echo "  $(basename "$0") appbundle prod           # Distribute existing App Bundle for prod"
    echo "  $(basename "$0") apk stg --dry-run        # Show distribution commands without executing"
}

# Main function
main() {
    log_info "🚀 Firebase App Distribution - Android"
    
    # Parse arguments
    local build_type=""
    local flavor=""
    local should_build=false
    local dry_run=false
    local verbose=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            apk|appbundle)
                build_type="$1"
                shift
                ;;
            dev|stg|prod)
                flavor="$1"
                shift
                ;;
            --build-first)
                should_build=true
                shift
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
    
    # Validate required arguments
    if [[ -z "$build_type" || -z "$flavor" ]]; then
        log_error "Missing required arguments"
        show_usage
        exit 1
    fi
    
    # Validate build type
    if [[ "$build_type" != "apk" && "$build_type" != "appbundle" ]]; then
        log_error "Invalid build type. Use 'apk' or 'appbundle'"
        exit 1
    fi
    
    # Validate flavor using centralized function
    if ! validate_flavor "$flavor"; then
        exit 1
    fi
    
    # Show configuration summary
    show_config_summary "$flavor" "android"
    
    # Navigate to root directory
    cd "$PROJECT_ROOT" || {
        log_error "Failed to navigate to the project root directory."
        exit 1
    }
    
    # Check prerequisites
    check_prerequisites
    
    # Build first if requested
    if [[ "$should_build" == true ]]; then
        log_step "Building $build_type for $flavor flavor..."
        
        local build_script=""
        if [[ "$build_type" == "apk" ]]; then
            build_script="$BUILD_DIR/build_apk.sh"
        else
            build_script="$BUILD_DIR/build_appbundle.sh"
        fi
        
        if [[ "$dry_run" == true ]]; then
            log_info "[DRY RUN] Would execute: $build_script $flavor"
        else
            log_step "Executing build command:"
            echo "${CYAN}$build_script $flavor${NC}"
            
            if ! "$build_script" "$flavor"; then
                log_error "Build failed!"
                send_slack_notification "$flavor" "$build_type" "build_failed"
                exit 1
            fi
        fi
    fi
    
    # Determine file path based on build type
    local file_path
    if [[ "$build_type" == "apk" ]]; then
        file_path="$ANDROID_OUTPUT_DIR/flutter-apk/app-$flavor-release.apk"
    else
        file_path="$ANDROID_OUTPUT_DIR/bundle/${flavor}Release/app-$flavor-release.aab"
    fi
    
    # Check if file exists before distribution
    if [[ ! -f "$file_path" ]]; then
        log_error "Build file not found: $file_path"
        log_info "Please build the $build_type first or use --build-first option"
        exit 1
    fi
    
    log_info "Found build file: $file_path"
    log_info "File size: $(du -h "$file_path" | cut -f1)"
    
    if [[ "$dry_run" == true ]]; then
        log_warning "[DRY RUN MODE] - Commands will be shown but not executed"
    fi
    
    # Distribute to Firebase
    distribute_to_firebase "$file_path" "$flavor" "$build_type" "$dry_run"
    
    # Send success notification
    send_slack_notification "$flavor" "$build_type" "success"
    
    log_success "🎉 Distribution completed successfully!"
    
    # Show next steps
    echo ""
    log_info "Next steps:"
    echo "  1. Check Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID/appdistribution"
    echo "  2. Testers will receive email invitations"
    echo "  3. Monitor installation and feedback"
}

# Run main function with all arguments
main "$@" 
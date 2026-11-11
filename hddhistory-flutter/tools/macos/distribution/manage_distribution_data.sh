#!/bin/bash

# Distribution Data File Manager
# This script manages tester lists, groups, release notes, and test devices in text files

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the common configuration
source "${SCRIPT_DIR}/../common/common.sh" || {
    echo "❌ Failed to load common configuration"
    exit 1
}

# Function to show usage
show_usage() {
    echo "Usage: $(basename "$0") <command> [options]"
    echo ""
    echo "Commands:"
    echo "  init                      Initialize distribution data files with examples"
    echo "  sync-app-ids              Sync Firebase app IDs from firebase.json"
    echo "  edit <file>               Edit a distribution data file"
    echo "  show [file]               Show content of distribution data files"
    echo "  add-tester <email>        Add tester to tester_list.txt"
    echo "  add-group <group>         Add group to tester_group.txt"
    echo "  set-release-note          Set custom release notes"
    echo "  add-device <device>       Add test device"
    echo "  set-password              Set test password"
    echo "  sync-to-firebase          Sync data files to Firebase"
    echo "  validate                  Validate all data files"
    echo ""
    echo "File options:"
    echo "  tester-list       Tester email addresses"
    echo "  tester-group      Distribution group names"
    echo "  release-note      Custom release notes"
    echo "  test-device       Test devices for automation"
    echo "  test-password     Test account password"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") init"
    echo "  $(basename "$0") sync-app-ids"
    echo "  $(basename "$0") show"
    echo "  $(basename "$0") add-tester user@example.com"
    echo "  $(basename "$0") add-group qa-team"
    echo "  $(basename "$0") edit tester-list"
    echo "  $(basename "$0") sync-to-firebase --flavor dev"
}

# Function to sync app IDs from firebase.json to .info/app/firebase.json
sync_firebase_app_ids() {
    local root_firebase_json="${PROJECT_ROOT}/firebase.json"
    local info_firebase_json="${FIREBASE_CONFIG}"
    
    if [[ ! -f "$root_firebase_json" ]]; then
        log_warning "Root firebase.json not found, skipping app ID sync"
        return 0
    fi
    
    log_step "Syncing Firebase app IDs from firebase.json..."
    
    # Extract app IDs for each flavor and platform
    for flavor in dev stg prod; do
        # Android app ID - try both path formats (forward slash and backslash)
        local android_app_id=$(jq -r ".flutter.platforms.android.buildConfigurations[\"src/${flavor}\"].appId // .flutter.platforms.android.buildConfigurations[\"src\\\\${flavor}\"].appId // empty" "$root_firebase_json")
        
        # iOS app ID - try Release, Debug, and Profile build configurations
        local ios_app_id=$(jq -r ".flutter.platforms.ios.buildConfigurations[\"Release-${flavor}\"].appId // .flutter.platforms.ios.buildConfigurations[\"Debug-${flavor}\"].appId // .flutter.platforms.ios.buildConfigurations[\"Profile-${flavor}\"].appId // empty" "$root_firebase_json")
        
        # Update .info/app/firebase.json if app IDs are found
        if [[ -n "$android_app_id" && "$android_app_id" != "null" ]]; then
            jq ".apps.android.${flavor}.appId = \"$android_app_id\"" "$info_firebase_json" > "${info_firebase_json}.tmp" && mv "${info_firebase_json}.tmp" "$info_firebase_json"
            log_success "Updated Android $flavor app ID: $android_app_id"
        else
            log_warning "Android app ID not found for $flavor"
        fi
        
        if [[ -n "$ios_app_id" && "$ios_app_id" != "null" ]]; then
            jq ".apps.ios.${flavor}.appId = \"$ios_app_id\"" "$info_firebase_json" > "${info_firebase_json}.tmp" && mv "${info_firebase_json}.tmp" "$info_firebase_json"
            log_success "Updated iOS $flavor app ID: $ios_app_id"
        else
            log_warning "iOS app ID not found for $flavor"
        fi
    done
    
    log_success "Firebase app IDs synced successfully!"
}

# Function to initialize data files with examples
init_data_files() {
    log_step "Initializing distribution data files..."
    
    # Create tester_list.txt with examples
    cat > "$TESTER_LIST_FILE" <<'EOF'
# Tester List - One email per line
# Lines starting with # are comments and will be ignored
# Empty lines are also ignored
#
# Example:
# tester1@example.com
# tester2@example.com
# qa-team@example.com

EOF
    log_success "Created: $TESTER_LIST_FILE"
    
    # Create tester_group.txt with examples
    cat > "$TESTER_GROUP_FILE" <<'EOF'
# Tester Groups - One group name per line
# Lines starting with # are comments and will be ignored
# Empty lines are also ignored
#
# Example:
# qa-team
# dev-team
# beta-testers

EOF
    log_success "Created: $TESTER_GROUP_FILE"
    
    # Create release_note.txt with template
    cat > "$RELEASE_NOTE_FILE" <<'EOF'
# Custom Release Notes
# Variables available: {{version}}, {{flavor}}, {{date}}
#
# Example release notes:

Version {{version}} - {{flavor}} Build

What's New:
- Bug fixes and performance improvements
- UI/UX enhancements
- New features added

Build Date: {{date}}

For testing purposes only.
EOF
    log_success "Created: $RELEASE_NOTE_FILE"
    
    # Create test_device.txt with examples
    cat > "$TEST_DEVICE_FILE" <<'EOF'
# Test Devices - One device per line
# Format: DeviceName|DeviceID|Platform
# Lines starting with # are comments
#
# Example:
# iPhone 14 Pro|00008110-001234567890001E|iOS
# Pixel 7 Pro|emulator-5554|Android
# Samsung Galaxy S23|R3CR40ABCDE|Android

EOF
    log_success "Created: $TEST_DEVICE_FILE"
    
    # Create test_password.txt (empty by default)
    cat > "$TEST_PASSWORD_FILE" <<'EOF'
# Test Account Password
# Store the test account password here (no comments, just the password)
# This file should be added to .gitignore for security

EOF
    log_success "Created: $TEST_PASSWORD_FILE"
    
    # Sync Firebase app IDs from root firebase.json
    sync_firebase_app_ids
    
    log_success "All distribution data files initialized!"
    echo ""
    log_info "Next steps:"
    echo "  1. Edit files to add your testers, groups, and devices"
    echo "  2. Run: $(basename "$0") validate"
    echo "  3. Run: $(basename "$0") show"
}

# Function to edit a data file
edit_data_file() {
    local file_type="$1"
    local file_path=""
    
    case "$file_type" in
        tester-list)
            file_path="$TESTER_LIST_FILE"
            ;;
        tester-group)
            file_path="$TESTER_GROUP_FILE"
            ;;
        release-note)
            file_path="$RELEASE_NOTE_FILE"
            ;;
        test-device)
            file_path="$TEST_DEVICE_FILE"
            ;;
        test-password)
            file_path="$TEST_PASSWORD_FILE"
            ;;
        *)
            log_error "Unknown file type: $file_type"
            show_usage
            exit 1
            ;;
    esac
    
    if [[ ! -f "$file_path" ]]; then
        log_warning "File does not exist: $file_path"
        log_info "Run 'init' command first to create template files"
        exit 1
    fi
    
    log_info "Opening: $file_path"
    
    # Use default editor or nano
    "${EDITOR:-nano}" "$file_path"
    
    log_success "File edited"
}

# Function to show data files
show_data_files() {
    local file_type="$1"
    
    if [[ -z "$file_type" ]]; then
        # Show all files
        log_step "Distribution Data Files:"
        echo ""
        
        echo "${CYAN}=== Tester List ===${NC}"
        if [[ -f "$TESTER_LIST_FILE" ]]; then
            cat "$TESTER_LIST_FILE"
        else
            echo "(not initialized)"
        fi
        echo ""
        
        echo "${CYAN}=== Tester Groups ===${NC}"
        if [[ -f "$TESTER_GROUP_FILE" ]]; then
            cat "$TESTER_GROUP_FILE"
        else
            echo "(not initialized)"
        fi
        echo ""
        
        echo "${CYAN}=== Release Notes ===${NC}"
        if [[ -f "$RELEASE_NOTE_FILE" ]]; then
            cat "$RELEASE_NOTE_FILE"
        else
            echo "(not initialized)"
        fi
        echo ""
        
        echo "${CYAN}=== Test Devices ===${NC}"
        if [[ -f "$TEST_DEVICE_FILE" ]]; then
            cat "$TEST_DEVICE_FILE"
        else
            echo "(not initialized)"
        fi
        echo ""
        
        echo "${CYAN}=== Test Password ===${NC}"
        if [[ -f "$TEST_PASSWORD_FILE" ]]; then
            local password=$(get_test_password_from_file)
            if [[ -n "$password" ]]; then
                echo "(password is set - ${#password} characters)"
            else
                echo "(not set)"
            fi
        else
            echo "(not initialized)"
        fi
    else
        # Show specific file
        local file_path=""
        case "$file_type" in
            tester-list) file_path="$TESTER_LIST_FILE" ;;
            tester-group) file_path="$TESTER_GROUP_FILE" ;;
            release-note) file_path="$RELEASE_NOTE_FILE" ;;
            test-device) file_path="$TEST_DEVICE_FILE" ;;
            test-password) file_path="$TEST_PASSWORD_FILE" ;;
            *)
                log_error "Unknown file type: $file_type"
                exit 1
                ;;
        esac
        
        if [[ -f "$file_path" ]]; then
            cat "$file_path"
        else
            log_error "File not found: $file_path"
            exit 1
        fi
    fi
}

# Function to add a tester
add_tester() {
    local email="$1"
    
    if [[ -z "$email" ]]; then
        log_error "Email address required"
        exit 1
    fi
    
    # Validate email format
    if [[ ! "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        log_error "Invalid email format: $email"
        exit 1
    fi
    
    # Check if already exists
    if grep -q "^${email}$" "$TESTER_LIST_FILE" 2>/dev/null; then
        log_warning "Tester already exists: $email"
        exit 0
    fi
    
    # Add tester
    echo "$email" >> "$TESTER_LIST_FILE"
    log_success "Added tester: $email"
}

# Function to add a group
add_group() {
    local group="$1"
    
    if [[ -z "$group" ]]; then
        log_error "Group name required"
        exit 1
    fi
    
    # Check if already exists
    if grep -q "^${group}$" "$TESTER_GROUP_FILE" 2>/dev/null; then
        log_warning "Group already exists: $group"
        exit 0
    fi
    
    # Add group
    echo "$group" >> "$TESTER_GROUP_FILE"
    log_success "Added group: $group"
}

# Function to set release notes
set_release_note() {
    log_step "Enter release notes (press Ctrl+D when done):"
    echo ""
    
    cat > "$RELEASE_NOTE_FILE"
    
    log_success "Release notes saved"
}

# Function to add device
add_device() {
    local device_info="$1"
    
    if [[ -z "$device_info" ]]; then
        log_error "Device info required"
        log_info "Format: DeviceName|DeviceID|Platform"
        exit 1
    fi
    
    echo "$device_info" >> "$TEST_DEVICE_FILE"
    log_success "Added device: $device_info"
}

# Function to set password
set_password() {
    log_step "Enter test account password:"
    read -s password
    echo ""
    
    if [[ -z "$password" ]]; then
        log_error "Password cannot be empty"
        exit 1
    fi
    
    echo -n "$password" > "$TEST_PASSWORD_FILE"
    log_success "Password saved (${#password} characters)"
    log_warning "Make sure $TEST_PASSWORD_FILE is in .gitignore!"
}

# Function to sync to Firebase
sync_to_firebase() {
    local flavor="$1"
    
    if [[ -z "$flavor" ]]; then
        log_error "Flavor required. Use --flavor option"
        exit 1
    fi
    
    log_step "Syncing distribution data to Firebase..."
    
    # Get project ID
    local project_id=$(get_firebase_project_id "$flavor")
    
    if [[ -z "$project_id" || "$project_id" == "null" ]]; then
        log_error "Firebase project ID not found for flavor: $flavor"
        exit 1
    fi
    
    log_info "Using project: $project_id"
    
    # Sync testers
    local testers=$(get_tester_list_from_file)
    if [[ -n "$testers" ]]; then
        log_step "Syncing testers..."
        
        # Convert comma-separated to array
        IFS=',' read -ra TESTER_ARRAY <<< "$testers"
        
        for tester in "${TESTER_ARRAY[@]}"; do
            log_info "Adding tester: $tester"
            firebase appdistribution:testers:add "$tester" --project "$project_id" || log_warning "Failed to add: $tester"
        done
    fi
    
    # Sync groups
    local groups=$(get_tester_groups_from_file)
    if [[ -n "$groups" ]]; then
        log_step "Syncing groups..."
        
        # Convert comma-separated to array
        IFS=',' read -ra GROUP_ARRAY <<< "$groups"
        
        for group in "${GROUP_ARRAY[@]}"; do
            log_info "Creating group: $group"
            # Generate display name from alias
            local display_name=$(echo "$group" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
            firebase appdistribution:groups:create "$display_name" "$group" --project "$project_id" 2>/dev/null || log_info "Group may already exist: $group"
        done
    fi
    
    log_success "Sync completed"
}

# Function to validate data files
validate_data_files() {
    log_step "Validating distribution data files..."
    
    local errors=0
    
    # Validate tester list
    if [[ -f "$TESTER_LIST_FILE" ]]; then
        local testers=$(get_tester_list_from_file)
        if [[ -n "$testers" ]]; then
            log_success "Tester list: Found $(echo "$testers" | tr ',' '\n' | wc -l | tr -d ' ') testers"
            
            # Validate email formats
            IFS=',' read -ra TESTER_ARRAY <<< "$testers"
            for tester in "${TESTER_ARRAY[@]}"; do
                if [[ ! "$tester" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                    log_error "Invalid email format: $tester"
                    ((errors++))
                fi
            done
        else
            log_warning "Tester list is empty"
        fi
    else
        log_warning "Tester list file not found"
    fi
    
    # Validate tester groups
    if [[ -f "$TESTER_GROUP_FILE" ]]; then
        local groups=$(get_tester_groups_from_file)
        if [[ -n "$groups" ]]; then
            log_success "Tester groups: Found $(echo "$groups" | tr ',' '\n' | wc -l | tr -d ' ') groups"
        else
            log_warning "Tester groups file is empty"
        fi
    else
        log_warning "Tester groups file not found"
    fi
    
    # Validate release notes
    if [[ -f "$RELEASE_NOTE_FILE" ]]; then
        local notes=$(get_release_notes_from_file)
        if [[ -n "$notes" ]]; then
            log_success "Release notes: Configured ($(echo "$notes" | wc -l | tr -d ' ') lines)"
        else
            log_warning "Release notes file is empty"
        fi
    else
        log_warning "Release notes file not found"
    fi
    
    # Validate test devices
    if [[ -f "$TEST_DEVICE_FILE" ]]; then
        local devices=$(get_test_devices_from_file)
        if [[ -n "$devices" ]]; then
            local device_count=$(echo "$devices" | wc -l | tr -d ' ')
            log_success "Test devices: Found $device_count devices"
        else
            log_warning "Test devices file is empty"
        fi
    else
        log_warning "Test devices file not found"
    fi
    
    # Validate test password
    if [[ -f "$TEST_PASSWORD_FILE" ]]; then
        local password=$(get_test_password_from_file)
        if [[ -n "$password" ]]; then
            log_success "Test password: Set (${#password} characters)"
        else
            log_warning "Test password is empty"
        fi
    else
        log_warning "Test password file not found"
    fi
    
    echo ""
    if [[ $errors -eq 0 ]]; then
        log_success "Validation completed with no errors"
    else
        log_error "Validation completed with $errors errors"
        exit 1
    fi
}

# Main function
main() {
    log_info "📝 Distribution Data File Manager"
    
    # Check if command provided
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 1
    fi
    
    local command="$1"
    
    # Check for help flag first
    if [[ "$command" == "-h" || "$command" == "--help" ]]; then
        show_usage
        exit 0
    fi
    
    shift
    
    # Parse options
    local flavor=""
    while [[ $# -gt 0 ]]; do
        case $1 in
            --flavor)
                flavor="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Execute command
    case "$command" in
        init)
            init_data_files
            ;;
        sync-app-ids)
            sync_firebase_app_ids
            ;;
        edit)
            if [[ $# -eq 0 ]]; then
                log_error "File type required"
                show_usage
                exit 1
            fi
            edit_data_file "$1"
            ;;
        show)
            show_data_files "$1"
            ;;
        add-tester)
            if [[ $# -eq 0 ]]; then
                log_error "Email required"
                show_usage
                exit 1
            fi
            add_tester "$1"
            ;;
        add-group)
            if [[ $# -eq 0 ]]; then
                log_error "Group name required"
                show_usage
                exit 1
            fi
            add_group "$1"
            ;;
        set-release-note)
            set_release_note
            ;;
        add-device)
            if [[ $# -eq 0 ]]; then
                log_error "Device info required"
                show_usage
                exit 1
            fi
            add_device "$1"
            ;;
        set-password)
            set_password
            ;;
        sync-to-firebase)
            sync_to_firebase "$flavor"
            ;;
        validate)
            validate_data_files
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
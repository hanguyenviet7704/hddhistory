#!/bin/bash

# Distribution Data File Manager (Linux)
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
    echo ""
    echo "Note: Uses Linux text editors (nano, vim, or default EDITOR)"
}

# Function to ensure distribution directory exists
ensure_distribution_dir() {
    if [[ ! -d "$INFO_DIST_DIR" ]]; then
        log_info "Creating distribution data directory: $INFO_DIST_DIR"
        mkdir -p "$INFO_DIST_DIR"
    fi
}

# Function to initialize distribution data files
init_distribution_files() {
    log_step "Initializing distribution data files..."
    ensure_distribution_dir

    # Create tester list file
    if [[ ! -f "$TESTER_LIST_FILE" ]]; then
        cat > "$TESTER_LIST_FILE" << 'EOF'
# Tester Email List
# Add one email address per line
# Lines starting with # are comments and will be ignored
#
# Example:
# user1@example.com
# user2@example.com
# qa-team@company.com

EOF
        log_success "Created: $TESTER_LIST_FILE"
    else
        log_info "Already exists: $TESTER_LIST_FILE"
    fi

    # Create tester group file
    if [[ ! -f "$TESTER_GROUP_FILE" ]]; then
        cat > "$TESTER_GROUP_FILE" << 'EOF'
# Tester Group List
# Add one group name per line
# Lines starting with # are comments and will be ignored
#
# Example:
# qa-team
# beta-users
# internal-testers

EOF
        log_success "Created: $TESTER_GROUP_FILE"
    else
        log_info "Already exists: $TESTER_GROUP_FILE"
    fi

    # Create release notes file
    if [[ ! -f "$RELEASE_NOTE_FILE" ]]; then
        cat > "$RELEASE_NOTE_FILE" << 'EOF'
# Custom Release Notes
# This file contains custom release notes for Firebase App Distribution
# You can use variables: {{version}}, {{flavor}}, {{date}}
#
# Example:
Version {{version}} for {{flavor}} environment

🚀 New Features:
- Feature description here

🐛 Bug Fixes:
- Bug fix description here

📱 Built on Linux: {{date}}

EOF
        log_success "Created: $RELEASE_NOTE_FILE"
    else
        log_info "Already exists: $RELEASE_NOTE_FILE"
    fi

    # Create test device file
    if [[ ! -f "$TEST_DEVICE_FILE" ]]; then
        cat > "$TEST_DEVICE_FILE" << 'EOF'
# Test Device List
# Add device identifiers for automated testing
# Lines starting with # are comments and will be ignored
#
# Example:
# emulator-5554
# device-serial-123
# android-device-1

EOF
        log_success "Created: $TEST_DEVICE_FILE"
    else
        log_info "Already exists: $TEST_DEVICE_FILE"
    fi

    # Create test password file
    if [[ ! -f "$TEST_PASSWORD_FILE" ]]; then
        cat > "$TEST_PASSWORD_FILE" << 'EOF'
# Test Account Password
# Store test account passwords here (one per line)
# Lines starting with # are comments and will be ignored
#
# WARNING: Be careful with password storage!
# Consider using environment variables instead
#
# Example:
# test-password-123

EOF
        log_success "Created: $TEST_PASSWORD_FILE"
    else
        log_info "Already exists: $TEST_PASSWORD_FILE"
    fi

    log_success "Distribution data files initialized!"
}

# Function to show file contents
show_files() {
    local file_type="$1"

    if [[ -n "$file_type" ]]; then
        case "$file_type" in
            tester-list)
                if [[ -f "$TESTER_LIST_FILE" ]]; then
                    log_step "Tester List ($TESTER_LIST_FILE):"
                    cat "$TESTER_LIST_FILE"
                else
                    log_warning "Tester list file not found: $TESTER_LIST_FILE"
                fi
                ;;
            tester-group)
                if [[ -f "$TESTER_GROUP_FILE" ]]; then
                    log_step "Tester Groups ($TESTER_GROUP_FILE):"
                    cat "$TESTER_GROUP_FILE"
                else
                    log_warning "Tester group file not found: $TESTER_GROUP_FILE"
                fi
                ;;
            release-note)
                if [[ -f "$RELEASE_NOTE_FILE" ]]; then
                    log_step "Release Notes ($RELEASE_NOTE_FILE):"
                    cat "$RELEASE_NOTE_FILE"
                else
                    log_warning "Release notes file not found: $RELEASE_NOTE_FILE"
                fi
                ;;
            test-device)
                if [[ -f "$TEST_DEVICE_FILE" ]]; then
                    log_step "Test Devices ($TEST_DEVICE_FILE):"
                    cat "$TEST_DEVICE_FILE"
                else
                    log_warning "Test device file not found: $TEST_DEVICE_FILE"
                fi
                ;;
            test-password)
                if [[ -f "$TEST_PASSWORD_FILE" ]]; then
                    log_step "Test Password ($TEST_PASSWORD_FILE):"
                    log_warning "Password file content hidden for security"
                    echo "[Content hidden - use 'edit test-password' to view/modify]"
                else
                    log_warning "Test password file not found: $TEST_PASSWORD_FILE"
                fi
                ;;
            *)
                log_error "Unknown file type: $file_type"
                echo "Available types: tester-list, tester-group, release-note, test-device, test-password"
                exit 1
                ;;
        esac
    else
        # Show all files
        show_files "tester-list"
        echo
        show_files "tester-group"
        echo
        show_files "release-note"
        echo
        show_files "test-device"
        echo
        show_files "test-password"
    fi
}

# Function to edit a file
edit_file() {
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
            echo "Available types: tester-list, tester-group, release-note, test-device, test-password"
            exit 1
            ;;
    esac

    ensure_distribution_dir

    if [[ ! -f "$file_path" ]]; then
        log_warning "File not found: $file_path"
        read -p "Create it now? (y/N) " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            init_distribution_files
        else
            exit 0
        fi
    fi

    # Use the default editor (nano, vim, or $EDITOR)
    if [[ -n "$EDITOR" ]]; then
        "$EDITOR" "$file_path"
    elif command -v nano >/dev/null 2>&1; then
        nano "$file_path"
    elif command -v vim >/dev/null 2>&1; then
        vim "$file_path"
    else
        log_error "No text editor found. Please set EDITOR environment variable or install nano/vim"
        exit 1
    fi

    log_success "File updated: $file_path"
}

# Function to add a tester
add_tester() {
    local email="$1"

    if [[ -z "$email" ]]; then
        log_error "Email address is required"
        exit 1
    fi

    # Simple email validation
    if [[ ! "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        log_error "Invalid email format: $email"
        exit 1
    fi

    ensure_distribution_dir

    if [[ ! -f "$TESTER_LIST_FILE" ]]; then
        init_distribution_files
    fi

    # Check if email already exists
    if grep -q "^$email$" "$TESTER_LIST_FILE" 2>/dev/null; then
        log_warning "Email already exists in tester list: $email"
        exit 0
    fi

    echo "$email" >> "$TESTER_LIST_FILE"
    log_success "Added tester: $email"
}

# Function to add a group
add_group() {
    local group="$1"

    if [[ -z "$group" ]]; then
        log_error "Group name is required"
        exit 1
    fi

    ensure_distribution_dir

    if [[ ! -f "$TESTER_GROUP_FILE" ]]; then
        init_distribution_files
    fi

    # Check if group already exists
    if grep -q "^$group$" "$TESTER_GROUP_FILE" 2>/dev/null; then
        log_warning "Group already exists in tester group list: $group"
        exit 0
    fi

    echo "$group" >> "$TESTER_GROUP_FILE"
    log_success "Added group: $group"
}

# Function to validate files
validate_files() {
    log_step "Validating distribution data files..."

    local errors=0

    # Validate tester list
    if [[ -f "$TESTER_LIST_FILE" ]]; then
        local invalid_emails=0
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ "$line" =~ ^[[:space:]]*$ ]] && continue

            if [[ ! "$line" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                log_warning "Invalid email in tester list: $line"
                ((invalid_emails++))
            fi
        done < "$TESTER_LIST_FILE"

        if [[ $invalid_emails -eq 0 ]]; then
            log_success "Tester list validation passed"
        else
            log_error "Found $invalid_emails invalid email(s) in tester list"
            ((errors++))
        fi
    else
        log_warning "Tester list file not found: $TESTER_LIST_FILE"
    fi

    if [[ $errors -eq 0 ]]; then
        log_success "All validation checks passed!"
    else
        log_error "Validation failed with $errors error(s)"
        exit 1
    fi
}

# Main function
main() {
    local command="$1"
    shift || true

    case "$command" in
        init)
            init_distribution_files
            ;;
        show)
            show_files "$1"
            ;;
        edit)
            edit_file "$1"
            ;;
        add-tester)
            add_tester "$1"
            ;;
        add-group)
            add_group "$1"
            ;;
        validate)
            validate_files
            ;;
        --help|-h|help)
            show_usage
            ;;
        *)
            if [[ -z "$command" ]]; then
                log_error "No command specified"
            else
                log_error "Unknown command: $command"
            fi
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
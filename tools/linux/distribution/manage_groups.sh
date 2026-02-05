#!/bin/bash

# Firebase App Distribution - Group Management with Centralized Configuration (Linux)
# This script provides comprehensive group management for Firebase App Distribution

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
    echo "  list                      List all distribution groups"
    echo "  create <name> [alias]     Create a new distribution group"
    echo "  delete <alias>            Delete a distribution group"
    echo "  show <alias>              Show group details and members"
    echo "  sync                      Sync groups from configuration"
    echo "  sync-from-file            Sync groups from tester_group.txt file"
    echo ""
    echo "Options:"
    echo "  --project <id>            Firebase project ID (uses config if not specified)"
    echo "  --flavor <dev|stg|prod>   Environment flavor for configuration"
    echo "  --description <text>      Group description (for create)"
    echo "  --add-testers <emails>    Add testers when creating group"
    echo "  --file <path>             Path to tester_group.txt file"
    echo "  --dry-run                 Show commands without executing"
    echo "  --verbose                 Show detailed output"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") list"
    echo "  $(basename "$0") create \"QA Team\" qa-team"
    echo "  $(basename "$0") delete qa-team"
    echo "  $(basename "$0") show qa-team"
    echo "  $(basename "$0") sync --flavor dev"
    echo "  $(basename "$0") sync-from-file --file .info/distribution/tester_group.txt"
}

# Parse command line arguments
parse_arguments() {
    COMMAND=""
    PROJECT_ID=""
    FLAVOR=""
    DESCRIPTION=""
    ADD_TESTERS=""
    FILE_PATH=""
    DRY_RUN=false
    VERBOSE=false
    GROUP_NAME=""
    GROUP_ALIAS=""

    # Check for help flag first
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        show_usage
        exit 0
    fi

    # First argument is the command
    if [[ $# -gt 0 ]]; then
        COMMAND="$1"
        shift
    fi

    # For create command, get name and alias
    if [[ "$COMMAND" == "create" && $# -gt 0 ]]; then
        GROUP_NAME="$1"
        shift
        if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
            GROUP_ALIAS="$1"
            shift
        fi
    fi

    # For delete/show commands, get alias
    if [[ ("$COMMAND" == "delete" || "$COMMAND" == "show") && $# -gt 0 ]]; then
        GROUP_ALIAS="$1"
        shift
    fi

    # Parse remaining arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --project)
                PROJECT_ID="$2"
                shift 2
                ;;
            --flavor)
                FLAVOR="$2"
                shift 2
                ;;
            --description)
                DESCRIPTION="$2"
                shift 2
                ;;
            --add-testers)
                ADD_TESTERS="$2"
                shift 2
                ;;
            --file)
                FILE_PATH="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use -h or --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Validate environment and parameters
validate_parameters() {
    validate_environment || exit 1

    if [[ -z "$COMMAND" ]]; then
        log_error "No command specified."
        echo "Use -h or --help for usage information"
        exit 1
    fi

    # Get Firebase project ID from config if not specified
    if [[ -z "$PROJECT_ID" ]]; then
        if [[ -n "$FLAVOR" ]]; then
            validate_flavor "$FLAVOR" || exit 1
            get_firebase_project_id "$FLAVOR" PROJECT_ID
        else
            # Default to dev flavor if not specified
            get_firebase_project_id "dev" PROJECT_ID
        fi
    fi

    if [[ -z "$PROJECT_ID" ]]; then
        log_error "Firebase project ID not found in configuration"
        log_error "Please specify --project or ensure Firebase configuration exists"
        exit 1
    fi

    # Set default file path for tester groups
    if [[ -z "$FILE_PATH" ]]; then
        FILE_PATH=".info/distribution/tester_group.txt"
    fi
}

# Check Firebase CLI prerequisites
check_firebase_cli() {
    log_step "Checking Firebase CLI..."

    if ! command -v firebase &> /dev/null; then
        log_error "Firebase CLI is not installed"
        log_error "Please install it with: npm install -g firebase-tools"
        exit 1
    fi

    # Check Firebase authentication
    if ! firebase projects:list &> /dev/null; then
        log_error "Not logged in to Firebase CLI"
        log_error "Please login with: firebase login"
        exit 1
    fi

    log_success "Firebase CLI is ready"
    log_info "Project ID: $PROJECT_ID"
}

# List all distribution groups
list_groups() {
    log_step "Listing Firebase App Distribution groups..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: firebase appdistribution:groups:list --project=$PROJECT_ID"
    else
        firebase appdistribution:groups:list --project="$PROJECT_ID" || {
            log_error "Failed to list groups"
            exit 1
        }
    fi
}

# Create a new distribution group
create_group() {
    if [[ -z "$GROUP_NAME" ]]; then
        log_error "Group name is required for create command"
        exit 1
    fi

    if [[ -z "$GROUP_ALIAS" ]]; then
        # Generate alias from name (simple conversion)
        GROUP_ALIAS=$(echo "$GROUP_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
        log_info "Generated alias: $GROUP_ALIAS"
    fi

    log_step "Creating Firebase App Distribution group..."
    log_info "Name: $GROUP_NAME"
    log_info "Alias: $GROUP_ALIAS"

    local create_cmd="firebase appdistribution:groups:create $GROUP_ALIAS --display-name \"$GROUP_NAME\" --project=$PROJECT_ID"

    if [[ -n "$DESCRIPTION" ]]; then
        create_cmd="$create_cmd --description \"$DESCRIPTION\""
    fi

    if [[ "$VERBOSE" == "true" ]]; then
        log_info "Command: $create_cmd"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: $create_cmd"
    else
        eval "$create_cmd" || {
            log_error "Failed to create group"
            exit 1
        }
        log_success "Group created successfully!"

        # Add testers if specified
        if [[ -n "$ADD_TESTERS" ]]; then
            log_info "Adding testers to group..."
            firebase appdistribution:groups:addtesters "$GROUP_ALIAS" --emails="$ADD_TESTERS" --project="$PROJECT_ID" && {
                log_success "Testers added to group"
            } || {
                log_warning "Failed to add some testers"
            }
        fi
    fi
}

# Delete a distribution group
delete_group() {
    if [[ -z "$GROUP_ALIAS" ]]; then
        log_error "Group alias is required for delete command"
        exit 1
    fi

    log_step "Deleting Firebase App Distribution group: $GROUP_ALIAS"

    local delete_cmd="firebase appdistribution:groups:delete $GROUP_ALIAS --project=$PROJECT_ID"

    if [[ "$VERBOSE" == "true" ]]; then
        log_info "Command: $delete_cmd"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: $delete_cmd"
    else
        log_warning "This will permanently delete the group. Continue? (y/N)"
        read -r CONFIRM
        if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
            eval "$delete_cmd" && {
                log_success "Group deleted successfully!"
            } || {
                log_error "Failed to delete group"
                exit 1
            }
        else
            log_info "Operation cancelled"
        fi
    fi
}

# Show group details
show_group() {
    if [[ -z "$GROUP_ALIAS" ]]; then
        log_error "Group alias is required for show command"
        exit 1
    fi

    log_step "Showing Firebase App Distribution group details: $GROUP_ALIAS"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: firebase appdistribution:groups:show $GROUP_ALIAS --project=$PROJECT_ID"
    else
        firebase appdistribution:groups:show "$GROUP_ALIAS" --project="$PROJECT_ID" || {
            log_error "Failed to show group details"
            exit 1
        }
    fi
}

# Sync groups from centralized configuration
sync_groups() {
    log_step "Syncing groups from centralized configuration..."

    if [[ -z "$FLAVOR" ]]; then
        log_error "Flavor is required for sync command"
        log_error "Use --flavor dev|stg|prod"
        exit 1
    fi

    validate_flavor "$FLAVOR" || exit 1

    log_info "Syncing groups for $FLAVOR environment"
    log_warning "Group sync from centralized config not fully implemented for Linux"
    log_info "Use 'sync-from-file' command with tester_group.txt file instead"
}

# Sync groups from file
sync_from_file() {
    log_step "Syncing groups from file: $FILE_PATH"

    if [[ ! -f "$FILE_PATH" ]]; then
        log_error "Tester group file not found: $FILE_PATH"
        log_info "Create the file using: tools/linux/distribution/manage_distribution_data.sh init"
        exit 1
    fi

    log_info "Reading groups from: $FILE_PATH"
    local group_count=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "${line// }" ]]; then
            ((group_count++))
            log_info "Processing group: $line"

            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "DRY RUN: Would create group '$line'"
            else
                # Attempt to create group
                if firebase appdistribution:groups:create "$line" --display-name "$line" --project="$PROJECT_ID" &> /dev/null; then
                    log_success "Created group: $line"
                else
                    log_warning "Group may already exist: $line"
                fi
            fi
        fi
    done < "$FILE_PATH"

    if [[ $group_count -eq 0 ]]; then
        log_warning "No groups found in file (excluding comments)"
    else
        log_success "Processed $group_count groups from file"
    fi
}

# Main execution
main() {
    parse_arguments "$@"
    validate_parameters
    check_firebase_cli

    case "$COMMAND" in
        list)
            list_groups
            ;;
        create)
            create_group
            ;;
        delete)
            delete_group
            ;;
        show)
            show_group
            ;;
        sync)
            sync_groups
            ;;
        sync-from-file)
            sync_from_file
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
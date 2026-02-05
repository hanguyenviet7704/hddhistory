#!/bin/bash

# Firebase App Distribution - Tester Management with Centralized Configuration (Linux)
# This script provides comprehensive tester management for Firebase App Distribution

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
    echo "  list [group]              List testers in project or group"
    echo "  add <emails...>           Add testers to project"
    echo "  remove <emails...>        Remove testers from project"
    echo "  add-to-group              Add testers to a specific group"
    echo "  remove-from-group         Remove testers from a specific group"
    echo "  import                    Import testers from CSV file"
    echo "  import-from-file          Import testers from tester_list.txt file"
    echo "  add-file-to-group         Add testers from file to a specific group"
    echo "  remove-file-from-group    Remove testers from file from a specific group"
    echo "  export                    Export testers to CSV file"
    echo ""
    echo "Options:"
    echo "  --project <id>            Firebase project ID (uses config if not specified)"
    echo "  --group <name>            Distribution group name"
    echo "  --file <path>             CSV file path for import/export"
    echo "  --flavor <dev|stg|prod>   Environment flavor for configuration"
    echo "  --dry-run                 Show commands without executing"
    echo "  --verbose                 Show detailed output"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") list"
    echo "  $(basename "$0") list --group qa-team"
    echo "  $(basename "$0") add user1@example.com user2@example.com"
    echo "  $(basename "$0") add-to-group --group qa-team user@example.com"
    echo "  $(basename "$0") import --file testers.csv"
    echo "  $(basename "$0") import-from-file --file .info/distribution/tester_list.txt"
    echo "  $(basename "$0") add-file-to-group --group qa-team --file .info/distribution/tester_list.txt"
    echo "  $(basename "$0") remove-file-from-group --group qa-team --file .info/distribution/tester_list.txt"
    echo "  $(basename "$0") export --file testers-backup.csv"
}

# Parse command line arguments
parse_arguments() {
    COMMAND=""
    PROJECT_ID=""
    GROUP_NAME=""
    FILE_PATH=""
    FLAVOR=""
    DRY_RUN=false
    VERBOSE=false
    EMAILS=()

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

    # For list command, check if next argument is a group name
    if [[ "$COMMAND" == "list" && $# -gt 0 && ! "$1" =~ ^-- ]]; then
        GROUP_NAME="$1"
        shift
    fi

    # For add/remove commands, collect email arguments
    if [[ "$COMMAND" == "add" || "$COMMAND" == "remove" ]]; then
        while [[ $# -gt 0 && ! "$1" =~ ^-- ]]; do
            EMAILS+=("$1")
            shift
        done
    fi

    # Parse remaining arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --project)
                PROJECT_ID="$2"
                shift 2
                ;;
            --group)
                GROUP_NAME="$2"
                shift 2
                ;;
            --file)
                FILE_PATH="$2"
                shift 2
                ;;
            --flavor)
                FLAVOR="$2"
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

    # Set default file path for imports
    if [[ -z "$FILE_PATH" && ("$COMMAND" == *"from-file"* || "$COMMAND" == "import") ]]; then
        if [[ "$COMMAND" == "import" ]]; then
            FILE_PATH="testers.csv"
        else
            FILE_PATH=".info/distribution/tester_list.txt"
        fi
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

# List testers
list_testers() {
    if [[ -z "$GROUP_NAME" ]]; then
        log_step "Listing all testers in project..."
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "DRY RUN: firebase appdistribution:testers:list --project=$PROJECT_ID"
        else
            firebase appdistribution:testers:list --project="$PROJECT_ID" || {
                log_error "Failed to list testers"
                exit 1
            }
        fi
    else
        log_step "Listing testers in group: $GROUP_NAME"
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "DRY RUN: firebase appdistribution:groups:show $GROUP_NAME --project=$PROJECT_ID"
        else
            firebase appdistribution:groups:show "$GROUP_NAME" --project="$PROJECT_ID" || {
                log_error "Failed to show group testers"
                exit 1
            }
        fi
    fi
}

# Add testers to project
add_testers() {
    if [[ ${#EMAILS[@]} -eq 0 ]]; then
        log_error "No email addresses specified for add command"
        exit 1
    fi

    local email_list=$(IFS=,; echo "${EMAILS[*]}")

    log_step "Adding testers to project..."
    log_info "Emails: $email_list"

    local add_cmd="firebase appdistribution:testers:add --emails=$email_list --project=$PROJECT_ID"

    if [[ "$VERBOSE" == "true" ]]; then
        log_info "Command: $add_cmd"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: $add_cmd"
    else
        eval "$add_cmd" && {
            log_success "Testers added successfully!"
        } || {
            log_error "Failed to add some testers"
            exit 1
        }
    fi
}

# Remove testers from project
remove_testers() {
    if [[ ${#EMAILS[@]} -eq 0 ]]; then
        log_error "No email addresses specified for remove command"
        exit 1
    fi

    local email_list=$(IFS=,; echo "${EMAILS[*]}")

    log_step "Removing testers from project..."
    log_info "Emails: $email_list"

    local remove_cmd="firebase appdistribution:testers:remove --emails=$email_list --project=$PROJECT_ID"

    if [[ "$VERBOSE" == "true" ]]; then
        log_info "Command: $remove_cmd"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: $remove_cmd"
    else
        log_warning "This will remove testers from the project. Continue? (y/N)"
        read -r CONFIRM
        if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
            eval "$remove_cmd" && {
                log_success "Testers removed successfully!"
            } || {
                log_error "Failed to remove some testers"
                exit 1
            }
        else
            log_info "Operation cancelled"
        fi
    fi
}

# Add testers to group
add_to_group() {
    if [[ -z "$GROUP_NAME" ]]; then
        log_error "Group name is required for add-to-group command"
        log_error "Use --group option"
        exit 1
    fi

    if [[ ${#EMAILS[@]} -eq 0 ]]; then
        log_error "No email addresses specified"
        log_error "Provide emails as arguments or use --file option"
        exit 1
    fi

    local email_list=$(IFS=,; echo "${EMAILS[*]}")

    log_step "Adding testers to group: $GROUP_NAME"
    log_info "Emails: $email_list"

    local add_group_cmd="firebase appdistribution:groups:addtesters $GROUP_NAME --emails=$email_list --project=$PROJECT_ID"

    if [[ "$VERBOSE" == "true" ]]; then
        log_info "Command: $add_group_cmd"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: $add_group_cmd"
    else
        eval "$add_group_cmd" && {
            log_success "Testers added to group successfully!"
        } || {
            log_error "Failed to add testers to group"
            exit 1
        }
    fi
}

# Remove testers from group
remove_from_group() {
    if [[ -z "$GROUP_NAME" ]]; then
        log_error "Group name is required for remove-from-group command"
        log_error "Use --group option"
        exit 1
    fi

    if [[ ${#EMAILS[@]} -eq 0 ]]; then
        log_error "No email addresses specified"
        log_error "Provide emails as arguments or use --file option"
        exit 1
    fi

    local email_list=$(IFS=,; echo "${EMAILS[*]}")

    log_step "Removing testers from group: $GROUP_NAME"
    log_info "Emails: $email_list"

    local remove_group_cmd="firebase appdistribution:groups:removetesters $GROUP_NAME --emails=$email_list --project=$PROJECT_ID"

    if [[ "$VERBOSE" == "true" ]]; then
        log_info "Command: $remove_group_cmd"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: $remove_group_cmd"
    else
        log_warning "This will remove testers from the group. Continue? (y/N)"
        read -r CONFIRM
        if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
            eval "$remove_group_cmd" && {
                log_success "Testers removed from group successfully!"
            } || {
                log_error "Failed to remove testers from group"
                exit 1
            }
        else
            log_info "Operation cancelled"
        fi
    fi
}

# Import testers from CSV file
import_testers() {
    if [[ -z "$FILE_PATH" ]]; then
        log_error "File path is required for import command"
        log_error "Use --file option"
        exit 1
    fi

    if [[ ! -f "$FILE_PATH" ]]; then
        log_error "Import file not found: $FILE_PATH"
        exit 1
    fi

    log_step "Importing testers from CSV file: $FILE_PATH"

    local import_cmd="firebase appdistribution:testers:import --file=$FILE_PATH --project=$PROJECT_ID"

    if [[ "$VERBOSE" == "true" ]]; then
        log_info "Command: $import_cmd"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: $import_cmd"
    else
        eval "$import_cmd" && {
            log_success "Testers imported successfully!"
        } || {
            log_error "Failed to import testers"
            exit 1
        }
    fi
}

# Import testers from text file
import_from_file() {
    if [[ -z "$FILE_PATH" ]]; then
        FILE_PATH=".info/distribution/tester_list.txt"
    fi

    if [[ ! -f "$FILE_PATH" ]]; then
        log_error "Tester list file not found: $FILE_PATH"
        log_info "Create the file using: tools/linux/distribution/manage_distribution_data.sh init"
        exit 1
    fi

    log_step "Importing testers from file: $FILE_PATH"

    # Read emails from file and build email list
    local email_list=""
    local email_count=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "${line// }" ]]; then
            # Basic email validation
            if [[ "$line" =~ @ ]]; then
                if [[ -z "$email_list" ]]; then
                    email_list="$line"
                else
                    email_list="$email_list,$line"
                fi
                ((email_count++))
            fi
        fi
    done < "$FILE_PATH"

    if [[ $email_count -eq 0 ]]; then
        log_warning "No valid email addresses found in file"
        return
    fi

    log_info "Found $email_count email addresses"

    local import_cmd="firebase appdistribution:testers:add --emails=$email_list --project=$PROJECT_ID"

    if [[ "$VERBOSE" == "true" ]]; then
        log_info "Command: $import_cmd"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: $import_cmd"
    else
        eval "$import_cmd" && {
            log_success "Testers imported successfully from file!"
        } || {
            log_error "Failed to import some testers"
            exit 1
        }
    fi
}

# Add testers from file to group
add_file_to_group() {
    if [[ -z "$GROUP_NAME" ]]; then
        log_error "Group name is required for add-file-to-group command"
        log_error "Use --group option"
        exit 1
    fi

    if [[ -z "$FILE_PATH" ]]; then
        FILE_PATH=".info/distribution/tester_list.txt"
    fi

    if [[ ! -f "$FILE_PATH" ]]; then
        log_error "Tester list file not found: $FILE_PATH"
        exit 1
    fi

    log_step "Adding testers from file to group: $GROUP_NAME"
    log_info "File: $FILE_PATH"

    # Read emails from file and build email list
    local email_list=""
    local email_count=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "${line// }" ]]; then
            # Basic email validation
            if [[ "$line" =~ @ ]]; then
                if [[ -z "$email_list" ]]; then
                    email_list="$line"
                else
                    email_list="$email_list,$line"
                fi
                ((email_count++))
            fi
        fi
    done < "$FILE_PATH"

    if [[ $email_count -eq 0 ]]; then
        log_warning "No valid email addresses found in file"
        return
    fi

    log_info "Found $email_count email addresses"

    local add_group_cmd="firebase appdistribution:groups:addtesters $GROUP_NAME --emails=$email_list --project=$PROJECT_ID"

    if [[ "$VERBOSE" == "true" ]]; then
        log_info "Command: $add_group_cmd"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: $add_group_cmd"
    else
        eval "$add_group_cmd" && {
            log_success "Testers from file added to group successfully!"
        } || {
            log_error "Failed to add some testers to group"
            exit 1
        }
    fi
}

# Remove testers from file from group
remove_file_from_group() {
    if [[ -z "$GROUP_NAME" ]]; then
        log_error "Group name is required for remove-file-from-group command"
        log_error "Use --group option"
        exit 1
    fi

    if [[ -z "$FILE_PATH" ]]; then
        FILE_PATH=".info/distribution/tester_list.txt"
    fi

    if [[ ! -f "$FILE_PATH" ]]; then
        log_error "Tester list file not found: $FILE_PATH"
        exit 1
    fi

    log_step "Removing testers from file from group: $GROUP_NAME"
    log_info "File: $FILE_PATH"

    # Read emails from file and build email list
    local email_list=""
    local email_count=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "${line// }" ]]; then
            # Basic email validation
            if [[ "$line" =~ @ ]]; then
                if [[ -z "$email_list" ]]; then
                    email_list="$line"
                else
                    email_list="$email_list,$line"
                fi
                ((email_count++))
            fi
        fi
    done < "$FILE_PATH"

    if [[ $email_count -eq 0 ]]; then
        log_warning "No valid email addresses found in file"
        return
    fi

    log_info "Found $email_count email addresses"

    local remove_group_cmd="firebase appdistribution:groups:removetesters $GROUP_NAME --emails=$email_list --project=$PROJECT_ID"

    if [[ "$VERBOSE" == "true" ]]; then
        log_info "Command: $remove_group_cmd"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: $remove_group_cmd"
    else
        log_warning "This will remove testers from the group. Continue? (y/N)"
        read -r CONFIRM
        if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
            eval "$remove_group_cmd" && {
                log_success "Testers from file removed from group successfully!"
            } || {
                log_error "Failed to remove some testers from group"
                exit 1
            }
        else
            log_info "Operation cancelled"
        fi
    fi
}

# Export testers
export_testers() {
    if [[ -z "$FILE_PATH" ]]; then
        log_error "File path is required for export command"
        log_error "Use --file option"
        exit 1
    fi

    log_step "Exporting testers to CSV file: $FILE_PATH"

    log_warning "Direct export not available via Firebase CLI"
    log_info "Use 'list' command and manually save the output to a file"
    log_info "Example: firebase appdistribution:testers:list --project=$PROJECT_ID > $FILE_PATH"
}

# Main execution
main() {
    parse_arguments "$@"
    validate_parameters
    check_firebase_cli

    case "$COMMAND" in
        list)
            list_testers
            ;;
        add)
            add_testers
            ;;
        remove)
            remove_testers
            ;;
        add-to-group)
            add_to_group
            ;;
        remove-from-group)
            remove_from_group
            ;;
        import)
            import_testers
            ;;
        import-from-file)
            import_from_file
            ;;
        add-file-to-group)
            add_file_to_group
            ;;
        remove-file-from-group)
            remove_file_from_group
            ;;
        export)
            export_testers
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
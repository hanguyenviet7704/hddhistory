#!/bin/bash

# Firebase App Distribution - Group Management
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
    echo "  --file <path>             Path to tester_group.txt file (default: .info/distribution/tester_group.txt)"
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
    
    # Get project ID from configuration if not specified
    if [[ -z "$PROJECT_ID" ]]; then
        PROJECT_ID=$(get_firebase_project_id "$FLAVOR")
        if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "null" ]]; then
            log_error "Firebase project ID not found. Please specify --project or configure in .info/"
            exit 1
        fi
    fi
}

# Function to execute Firebase command
execute_firebase_command() {
    local cmd="$1"
    
    if [[ "$VERBOSE" == true ]]; then
        log_step "Executing command:"
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warning "[DRY RUN] Would execute: $cmd"
    else
        echo "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo "${CYAN}$cmd${NC}"
        echo "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        eval "$cmd"
    fi
}

# Function to list groups
list_groups() {
    log_step "Listing distribution groups..."
    
    local cmd="firebase appdistribution:groups:list --project \"$PROJECT_ID\""
    
    execute_firebase_command "$cmd"
    
    # Also show configured groups from .info
    echo ""
    log_step "Groups configured in .info/firebase.json:"
    
    for flavor in dev stg prod; do
        local groups=$(get_firebase_groups "$flavor" 2>/dev/null | tr '\n' ', ' | sed 's/,$//')
        if [[ -n "$groups" && "$groups" != "null" ]]; then
            echo "${CYAN}  $flavor:${NC} $groups"
        fi
    done
}

# Function to create group
create_group() {
    if [[ -z "$GROUP_NAME" ]]; then
        log_error "Group name required"
        show_usage
        exit 1
    fi
    
    # Generate alias from name if not provided
    if [[ -z "$GROUP_ALIAS" ]]; then
        GROUP_ALIAS=$(echo "$GROUP_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g' | sed 's/[^a-z0-9-]//g')
        log_info "Generated alias: $GROUP_ALIAS"
    fi
    
    log_step "Creating distribution group..."
    log_info "Name: $GROUP_NAME"
    log_info "Alias: $GROUP_ALIAS"
    
    local cmd="firebase appdistribution:groups:create \"$GROUP_NAME\" \"$GROUP_ALIAS\" --project \"$PROJECT_ID\""
    
    execute_firebase_command "$cmd"
    
    # Add testers if specified
    if [[ -n "$ADD_TESTERS" && "$DRY_RUN" == false ]]; then
        log_step "Adding testers to group..."
        
        # Split comma-separated emails
        IFS=',' read -ra TESTERS <<< "$ADD_TESTERS"
        
        local add_cmd="firebase appdistribution:testers:add"
        for tester in "${TESTERS[@]}"; do
            add_cmd="$add_cmd \"$(echo "$tester" | tr -d ' ')\""
        done
        add_cmd="$add_cmd --group \"$GROUP_ALIAS\" --project \"$PROJECT_ID\""
        
        execute_firebase_command "$add_cmd"
    fi
    
    if [[ "$DRY_RUN" == false ]]; then
        log_success "Group created successfully"
        
        # Suggest adding to configuration
        log_info "To add this group to your configuration, update .info/firebase.json:"
        echo "  \"distribution\": {"
        echo "    \"groups\": {"
        echo "      \"dev\": [\"$GROUP_ALIAS\"],"
        echo "      \"stg\": [\"$GROUP_ALIAS\"],"
        echo "      \"prod\": [\"$GROUP_ALIAS\"]"
        echo "    }"
        echo "  }"
    fi
}

# Function to delete group
delete_group() {
    if [[ -z "$GROUP_ALIAS" ]]; then
        log_error "Group alias required"
        show_usage
        exit 1
    fi
    
    log_warning "Deleting distribution group: $GROUP_ALIAS"
    
    # Confirm deletion
    if [[ "$DRY_RUN" == false ]]; then
        echo -n "Are you sure you want to delete this group? (y/N): "
        read -r confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            log_info "Deletion cancelled"
            exit 0
        fi
    fi
    
    local cmd="firebase appdistribution:groups:delete \"$GROUP_ALIAS\" --project \"$PROJECT_ID\""
    
    execute_firebase_command "$cmd"
    
    if [[ "$DRY_RUN" == false ]]; then
        log_success "Group deleted successfully"
        log_warning "Remember to remove this group from .info/firebase.json if configured"
    fi
}

# Function to show group details
show_group() {
    if [[ -z "$GROUP_ALIAS" ]]; then
        log_error "Group alias required"
        show_usage
        exit 1
    fi
    
    log_step "Showing group details: $GROUP_ALIAS"
    
    # List groups with JSON output to get details
    local cmd="firebase appdistribution:groups:list --project \"$PROJECT_ID\" --json 2>/dev/null"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warning "[DRY RUN] Would fetch group details"
    else
        local groups_json=$(eval "$cmd")
        
        if [[ -n "$groups_json" ]]; then
            # Parse JSON to find the specific group - extract alias from full path
            local group_info=$(echo "$groups_json" | jq -r ".result.groups[] | select(.name | endswith(\"/$GROUP_ALIAS\"))")
            
            if [[ -n "$group_info" ]]; then
                echo "Group Information:"
                echo "$group_info" | jq '.'
                
                # List testers in this group
                log_step "Testers in group:"
                firebase appdistribution:testers:list "$GROUP_ALIAS" --project "$PROJECT_ID"
            else
                log_warning "Group not found: $GROUP_ALIAS"
            fi
        else
            log_warning "Could not fetch group details"
        fi
    fi
}

# Function to read groups from file
read_groups_from_file() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "File not found: $file_path"
        exit 1
    fi
    
    local groups=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        if [[ -z "$line" || "$line" =~ ^# ]]; then
            continue
        fi
        
        groups+=("$line")
    done < "$file_path"
    
    printf '%s\n' "${groups[@]}"
}

# Function to sync groups from file
sync_groups_from_file() {
    log_step "Syncing groups from file..."
    
    if [[ -z "$FILE_PATH" ]]; then
        FILE_PATH=".info/distribution/tester_group.txt"
        log_info "Using default file: $FILE_PATH"
    fi
    
    if [[ ! -f "$FILE_PATH" ]]; then
        log_error "File not found: $FILE_PATH"
        exit 1
    fi
    
    log_info "Reading groups from: $FILE_PATH"
    
    local groups_from_file=()
    local temp_groups=$(read_groups_from_file "$FILE_PATH")
    while IFS= read -r group; do
        if [[ -n "$group" ]]; then
            groups_from_file+=("$group")
        fi
    done <<< "$temp_groups"
    
    if [[ ${#groups_from_file[@]} -eq 0 ]]; then
        log_warning "No groups found in file: $FILE_PATH"
        exit 0
    fi
    
    log_info "Found ${#groups_from_file[@]} groups in file:"
    for group in "${groups_from_file[@]}"; do
        echo "  - $group"
    done
    
    local existing_groups_cmd="firebase appdistribution:groups:list --project \"$PROJECT_ID\" --json"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warning "[DRY RUN] Would sync the following groups:"
        for group in "${groups_from_file[@]}"; do
            echo "  - $group"
        done
    else
        log_info "Fetching existing groups..."
        local existing_groups=$(eval "$existing_groups_cmd" 2>/dev/null | jq -r '.result.groups[]?.name | split("/")[-1]' 2>/dev/null)
        
        for group in "${groups_from_file[@]}"; do
            if echo "$existing_groups" | grep -q "^$group$"; then
                log_success "Group already exists: $group"
            else
                log_warning "Group not found, creating: $group"
                
                local display_name=$(echo "$group" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
                
                local create_cmd="firebase appdistribution:groups:create \"$display_name\" \"$group\" --project \"$PROJECT_ID\""
                execute_firebase_command "$create_cmd"
            fi
        done
        
        log_success "Group sync from file completed"
    fi
}

# Function to sync groups from configuration
sync_groups() {
    log_step "Syncing groups from configuration..."
    
    if [[ -z "$FLAVOR" ]]; then
        log_error "Flavor required for sync. Use --flavor option"
        exit 1
    fi
    
    # Validate flavor
    if ! validate_flavor "$FLAVOR"; then
        exit 1
    fi
    
    # Get configured groups for this flavor
    local configured_groups=$(get_firebase_groups "$FLAVOR" 2>/dev/null)
    
    if [[ -z "$configured_groups" || "$configured_groups" == "null" ]]; then
        log_warning "No groups configured for flavor: $FLAVOR"
        exit 0
    fi
    
    log_info "Groups configured for $FLAVOR:"
    echo "$configured_groups"
    
    # Get existing groups
    local existing_groups_cmd="firebase appdistribution:groups:list --project \"$PROJECT_ID\" --json"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warning "[DRY RUN] Would sync the following groups:"
        echo "$configured_groups"
    else
        log_info "Fetching existing groups..."
        local existing_groups=$(eval "$existing_groups_cmd" 2>/dev/null | jq -r '.result.groups[]?.name | split("/")[-1]' 2>/dev/null)
        
        # Check each configured group
        while IFS= read -r group; do
            if [[ -n "$group" ]]; then
                if echo "$existing_groups" | grep -q "^$group$"; then
                    log_success "Group already exists: $group"
                else
                    log_warning "Group not found, creating: $group"
                    
                    # Create display name from alias
                    local display_name=$(echo "$group" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
                    
                    local create_cmd="firebase appdistribution:groups:create \"$display_name\" \"$group\" --project \"$PROJECT_ID\""
                    execute_firebase_command "$create_cmd"
                fi
            fi
        done <<< "$configured_groups"
        
        log_success "Group sync completed"
    fi
}

# Function to validate prerequisites
check_prerequisites() {
    # Check if Firebase CLI is installed
    if ! command -v firebase &> /dev/null; then
        log_error "Firebase CLI is not installed. Please install it first:"
        echo "npm install -g firebase-tools"
        exit 1
    fi
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        log_error "jq is not installed. Please install it first:"
        echo "brew install jq"
        exit 1
    fi
}

# Main function
main() {
    log_info "👥 Firebase App Distribution - Group Management"
    
    # Parse arguments
    parse_arguments "$@"
    
    # Validate command - show help if no command provided
    if [[ -z "$COMMAND" ]]; then
        show_usage
        exit 0
    fi
    
    # Check prerequisites
    check_prerequisites
    
    log_info "Using project: $PROJECT_ID"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN MODE - No changes will be made"
    fi
    
    # Execute command
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
            sync_groups_from_file
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            show_usage
            exit 1
            ;;
    esac
    
    log_success "Operation completed"
}

# Run main function
main "$@"
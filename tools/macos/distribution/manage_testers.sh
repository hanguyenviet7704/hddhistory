#!/bin/bash

# Firebase App Distribution - Tester Management
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
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                # Collect emails or group names
                EMAILS+=("$1")
                shift
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
        echo "${CYAN}$cmd${NC}"
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

# Function to list testers
list_testers() {
    log_step "Listing testers..."
    
    local cmd="firebase appdistribution:testers:list"
    
    if [[ -n "$GROUP_NAME" ]]; then
        cmd="$cmd $GROUP_NAME"
        log_info "Listing testers in group: $GROUP_NAME"
    else
        log_info "Listing all testers in project"
    fi
    
    cmd="$cmd --project \"$PROJECT_ID\""
    
    execute_firebase_command "$cmd"
}

# Function to add testers
add_testers() {
    if [[ ${#EMAILS[@]} -eq 0 ]]; then
        log_error "No emails provided"
        show_usage
        exit 1
    fi
    
    log_step "Adding testers to project..."
    log_info "Testers to add: ${EMAILS[*]}"
    
    local cmd="firebase appdistribution:testers:add"
    
    # Add emails
    for email in "${EMAILS[@]}"; do
        cmd="$cmd \"$email\""
    done
    
    # Add group if specified
    if [[ -n "$GROUP_NAME" ]]; then
        cmd="$cmd --group \"$GROUP_NAME\""
        log_info "Adding to group: $GROUP_NAME"
    fi
    
    cmd="$cmd --project \"$PROJECT_ID\""
    
    execute_firebase_command "$cmd"
    
    if [[ "$DRY_RUN" == false ]]; then
        log_success "Testers added successfully"
    fi
}

# Function to remove testers
remove_testers() {
    if [[ ${#EMAILS[@]} -eq 0 ]]; then
        log_error "No emails provided"
        show_usage
        exit 1
    fi
    
    log_step "Removing testers from project..."
    log_warning "Testers to remove: ${EMAILS[*]}"
    
    # Confirm removal
    if [[ "$DRY_RUN" == false ]]; then
        echo -n "Are you sure you want to remove these testers? (y/N): "
        read -r confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            log_info "Removal cancelled"
            exit 0
        fi
    fi
    
    local cmd="firebase appdistribution:testers:remove"
    
    # Add emails
    for email in "${EMAILS[@]}"; do
        cmd="$cmd \"$email\""
    done
    
    # Add group if specified
    if [[ -n "$GROUP_NAME" ]]; then
        cmd="$cmd --group \"$GROUP_NAME\""
        log_info "Removing from group: $GROUP_NAME"
    fi
    
    cmd="$cmd --project \"$PROJECT_ID\""
    
    execute_firebase_command "$cmd"
    
    if [[ "$DRY_RUN" == false ]]; then
        log_success "Testers removed successfully"
    fi
}

# Function to read emails from text file
read_emails_from_file() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "File not found: $file_path"
        exit 1
    fi
    
    local emails=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        if [[ -z "$line" || "$line" =~ ^# ]]; then
            continue
        fi
        
        if [[ "$line" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            emails+=("$line")
        else
            log_warning "Skipping invalid email: $line"
        fi
    done < "$file_path"
    
    printf '%s\n' "${emails[@]}"
}

# Function to import testers from text file
import_from_file() {
    if [[ -z "$FILE_PATH" ]]; then
        FILE_PATH=".info/distribution/tester_list.txt"
        log_info "Using default file: $FILE_PATH"
    fi
    
    if [[ ! -f "$FILE_PATH" ]]; then
        log_error "File not found: $FILE_PATH"
        exit 1
    fi
    
    log_step "Importing testers from text file..."
    log_info "File: $FILE_PATH"
    
    local emails=()
    local temp_emails=$(read_emails_from_file "$FILE_PATH")
    while IFS= read -r email; do
        if [[ -n "$email" ]]; then
            emails+=("$email")
        fi
    done <<< "$temp_emails"
    
    if [[ ${#emails[@]} -eq 0 ]]; then
        log_error "No valid emails found in file"
        exit 1
    fi
    
    log_info "Found ${#emails[@]} testers to import:"
    for email in "${emails[@]}"; do
        echo "  - $email"
    done
    
    local batch_size=100
    local batch_count=0
    
    for ((i=0; i<${#emails[@]}; i+=batch_size)); do
        batch_count=$((batch_count + 1))
        local batch_emails=("${emails[@]:$i:$batch_size}")
        
        log_info "Processing batch $batch_count (${#batch_emails[@]} testers)"
        
        local cmd="firebase appdistribution:testers:add"
        
        for email in "${batch_emails[@]}"; do
            cmd="$cmd \"$email\""
        done
        
        if [[ -n "$GROUP_NAME" ]]; then
            cmd="$cmd --group \"$GROUP_NAME\""
        fi
        
        cmd="$cmd --project \"$PROJECT_ID\""
        
        execute_firebase_command "$cmd"
        
        if [[ $((i + batch_size)) -lt ${#emails[@]} ]]; then
            log_info "Waiting 2 seconds before next batch..."
            sleep 2
        fi
    done
    
    if [[ "$DRY_RUN" == false ]]; then
        log_success "Import completed: ${#emails[@]} testers processed"
    fi
}

# Function to add testers from file to a specific group
add_file_to_group() {
    if [[ -z "$GROUP_NAME" ]]; then
        log_error "Group name required. Use --group option"
        exit 1
    fi
    
    if [[ -z "$FILE_PATH" ]]; then
        FILE_PATH=".info/distribution/tester_list.txt"
        log_info "Using default file: $FILE_PATH"
    fi
    
    if [[ ! -f "$FILE_PATH" ]]; then
        log_error "File not found: $FILE_PATH"
        exit 1
    fi
    
    log_step "Adding testers from file to group: $GROUP_NAME"
    log_info "File: $FILE_PATH"
    
    local emails=()
    local temp_emails=$(read_emails_from_file "$FILE_PATH")
    while IFS= read -r email; do
        if [[ -n "$email" ]]; then
            emails+=("$email")
        fi
    done <<< "$temp_emails"
    
    if [[ ${#emails[@]} -eq 0 ]]; then
        log_error "No valid emails found in file"
        exit 1
    fi
    
    log_info "Found ${#emails[@]} testers to add to group:"
    for email in "${emails[@]}"; do
        echo "  - $email"
    done
    
    local batch_size=100
    local batch_count=0
    
    for ((i=0; i<${#emails[@]}; i+=batch_size)); do
        batch_count=$((batch_count + 1))
        local batch_emails=("${emails[@]:$i:$batch_size}")
        
        log_info "Processing batch $batch_count (${#batch_emails[@]} testers)"
        
        local cmd="firebase appdistribution:testers:add"
        
        for email in "${batch_emails[@]}"; do
            cmd="$cmd \"$email\""
        done
        
        cmd="$cmd --group-alias \"$GROUP_NAME\""
        cmd="$cmd --project \"$PROJECT_ID\""
        
        execute_firebase_command "$cmd"
        
        if [[ $((i + batch_size)) -lt ${#emails[@]} ]]; then
            log_info "Waiting 2 seconds before next batch..."
            sleep 2
        fi
    done
    
    if [[ "$DRY_RUN" == false ]]; then
        log_success "Added ${#emails[@]} testers to group: $GROUP_NAME"
    fi
}

# Function to remove testers from file from a specific group
remove_file_from_group() {
    if [[ -z "$GROUP_NAME" ]]; then
        log_error "Group name required. Use --group option"
        exit 1
    fi
    
    if [[ -z "$FILE_PATH" ]]; then
        FILE_PATH=".info/distribution/tester_list.txt"
        log_info "Using default file: $FILE_PATH"
    fi
    
    if [[ ! -f "$FILE_PATH" ]]; then
        log_error "File not found: $FILE_PATH"
        exit 1
    fi
    
    log_step "Removing testers from file from group: $GROUP_NAME"
    log_info "File: $FILE_PATH"
    
    local emails=()
    local temp_emails=$(read_emails_from_file "$FILE_PATH")
    while IFS= read -r email; do
        if [[ -n "$email" ]]; then
            emails+=("$email")
        fi
    done <<< "$temp_emails"
    
    if [[ ${#emails[@]} -eq 0 ]]; then
        log_error "No valid emails found in file"
        exit 1
    fi
    
    log_warning "Found ${#emails[@]} testers to remove from group:"
    for email in "${emails[@]}"; do
        echo "  - $email"
    done
    
    # Confirm removal
    if [[ "$DRY_RUN" == false ]]; then
        echo -n "Are you sure you want to remove these testers from group $GROUP_NAME? (y/N): "
        read -r confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            log_info "Removal cancelled"
            exit 0
        fi
    fi
    
    local batch_size=100
    local batch_count=0
    
    for ((i=0; i<${#emails[@]}; i+=batch_size)); do
        batch_count=$((batch_count + 1))
        local batch_emails=("${emails[@]:$i:$batch_size}")
        
        log_info "Processing batch $batch_count (${#batch_emails[@]} testers)"
        
        local cmd="firebase appdistribution:testers:remove"
        
        for email in "${batch_emails[@]}"; do
            cmd="$cmd \"$email\""
        done
        
        cmd="$cmd --group-alias \"$GROUP_NAME\""
        cmd="$cmd --project \"$PROJECT_ID\""
        
        execute_firebase_command "$cmd"
        
        if [[ $((i + batch_size)) -lt ${#emails[@]} ]]; then
            log_info "Waiting 2 seconds before next batch..."
            sleep 2
        fi
    done
    
    if [[ "$DRY_RUN" == false ]]; then
        log_success "Removed ${#emails[@]} testers from group: $GROUP_NAME"
    fi
}

# Function to import testers from CSV
import_testers() {
    if [[ -z "$FILE_PATH" ]]; then
        log_error "CSV file path required. Use --file option"
        exit 1
    fi
    
    if [[ ! -f "$FILE_PATH" ]]; then
        log_error "File not found: $FILE_PATH"
        exit 1
    fi
    
    log_step "Importing testers from CSV file..."
    log_info "File: $FILE_PATH"
    
    # Read CSV file and extract emails
    local emails=()
    while IFS=',' read -r email name group _; do
        # Skip header row
        if [[ "$email" == "email" || "$email" == "Email" ]]; then
            continue
        fi
        
        # Clean email
        email=$(echo "$email" | tr -d ' ' | tr -d '"')
        
        if [[ -n "$email" ]]; then
            emails+=("$email")
        fi
    done < "$FILE_PATH"
    
    if [[ ${#emails[@]} -eq 0 ]]; then
        log_error "No valid emails found in CSV file"
        exit 1
    fi
    
    log_info "Found ${#emails[@]} testers to import"
    
    # Add testers in batches (Firebase has limits)
    local batch_size=100
    local batch_count=0
    
    for ((i=0; i<${#emails[@]}; i+=batch_size)); do
        batch_count=$((batch_count + 1))
        local batch_emails=("${emails[@]:$i:$batch_size}")
        
        log_info "Processing batch $batch_count (${#batch_emails[@]} testers)"
        
        local cmd="firebase appdistribution:testers:add"
        
        for email in "${batch_emails[@]}"; do
            cmd="$cmd \"$email\""
        done
        
        if [[ -n "$GROUP_NAME" ]]; then
            cmd="$cmd --group \"$GROUP_NAME\""
        fi
        
        cmd="$cmd --project \"$PROJECT_ID\""
        
        execute_firebase_command "$cmd"
        
        # Add delay between batches to avoid rate limiting
        if [[ $((i + batch_size)) -lt ${#emails[@]} ]]; then
            log_info "Waiting 2 seconds before next batch..."
            sleep 2
        fi
    done
    
    if [[ "$DRY_RUN" == false ]]; then
        log_success "Import completed: ${#emails[@]} testers processed"
    fi
}

# Function to export testers to CSV
export_testers() {
    if [[ -z "$FILE_PATH" ]]; then
        FILE_PATH="testers-export-$(date +%Y%m%d-%H%M%S).csv"
        log_info "No file specified, using: $FILE_PATH"
    fi
    
    log_step "Exporting testers to CSV file..."
    
    # Get testers list
    local cmd="firebase appdistribution:testers:list"
    
    if [[ -n "$GROUP_NAME" ]]; then
        cmd="$cmd $GROUP_NAME"
    fi
    
    cmd="$cmd --project \"$PROJECT_ID\" --json"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warning "[DRY RUN] Would export testers to: $FILE_PATH"
        log_info "Command: $cmd"
    else
        log_info "Fetching testers from Firebase..."
        
        # Execute command and capture output
        local testers_json=$(eval "$cmd" 2>/dev/null)
        
        # Create CSV header
        echo "email,display_name,groups,date_added" > "$FILE_PATH"
        
        # Parse JSON and write to CSV
        if [[ -n "$testers_json" ]]; then
            echo "$testers_json" | jq -r '.[] | [.email, .displayName // "", .groups // "" | join(";"), .dateAdded // ""] | @csv' >> "$FILE_PATH" 2>/dev/null || {
                log_warning "Could not parse tester data, saving raw JSON instead"
                echo "$testers_json" > "${FILE_PATH%.csv}.json"
                FILE_PATH="${FILE_PATH%.csv}.json"
            }
        fi
        
        log_success "Testers exported to: $FILE_PATH"
        log_info "File contains $(wc -l < "$FILE_PATH") lines"
    fi
}

# Function to manage testers in groups
manage_group_testers() {
    local action="$1"
    
    if [[ -z "$GROUP_NAME" ]]; then
        log_error "Group name required. Use --group option"
        exit 1
    fi
    
    if [[ ${#EMAILS[@]} -eq 0 ]]; then
        log_error "No emails provided"
        show_usage
        exit 1
    fi
    
    if [[ "$action" == "add" ]]; then
        log_step "Adding testers to group: $GROUP_NAME"
        COMMAND="add"
    else
        log_step "Removing testers from group: $GROUP_NAME"
        COMMAND="remove"
    fi
    
    # Use the add/remove functions with group specified
    if [[ "$action" == "add" ]]; then
        add_testers
    else
        remove_testers
    fi
}

# Main function
main() {
    log_info "🧑‍🤝‍🧑 Firebase App Distribution - Tester Management"
    
    # Parse arguments
    parse_arguments "$@"
    
    # Validate command - show help if no command provided
    if [[ -z "$COMMAND" ]]; then
        show_usage
        exit 0
    fi
    
    # Check prerequisites
    if ! command -v firebase &> /dev/null; then
        log_error "Firebase CLI is not installed. Please install it first:"
        echo "npm install -g firebase-tools"
        exit 1
    fi
    
    log_info "Using project: $PROJECT_ID"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN MODE - No changes will be made"
    fi
    
    # Execute command
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
            manage_group_testers "add"
            ;;
        remove-from-group)
            manage_group_testers "remove"
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
            show_usage
            exit 1
            ;;
    esac
    
    log_success "Operation completed"
}

# Run main function
main "$@"
#!/bin/bash

# Script to clean up old ARB files after migration to module-based structure

set -e

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source the localization-specific configuration (which includes common.sh)
source "${SCRIPT_DIR}/localization_common.sh" || {
    echo "❌ Failed to load localization configuration"
    exit 1
}

# Change to project root directory
cd "$PROJECT_ROOT"

# Validate environment and configuration
if ! validate_environment; then
    exit 1
fi

if ! validate_localization_config; then
    exit 1
fi

log_warning "ARB File Cleanup"
echo "================="
echo ""

# Files to remove (using localization configuration)
ARB_DIR=$(get_arb_dir)
OLD_FILES=(
    "${ARB_DIR}/app_en.arb"
    "${ARB_DIR}/app_vn.arb"
)

echo "This will remove the following old ARB files:"
files_exist=false
for file in "${OLD_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  - $file"
        files_exist=true
    fi
done

if [ "$files_exist" = false ]; then
    log_info "No old ARB files found to cleanup"
    exit 0
fi

echo ""
read -p "Are you sure you want to delete these files? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    for file in "${OLD_FILES[@]}"; do
        if [ -f "$file" ]; then
            rm "$file"
            log_success "Removed: $file"
        else
            log_warning "File not found: $file"
        fi
    done
    echo ""
    log_success "Cleanup completed!"
else
    log_warning "Cleanup cancelled."
fi 
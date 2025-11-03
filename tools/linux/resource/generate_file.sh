#!/bin/bash

# Define the root directory
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

# Load common configuration functions
source "${ROOT_DIR}/tools/linux/common/common.sh" || {
    echo "❌ Failed to load common configuration library."
    exit 1
}

# Navigate to the root directory
cd "$ROOT_DIR" || {
    log_error "Failed to navigate to the root directory."
    exit 1
}

# Get the dart command based on version manager configuration
DART_CMD=$(get_dart_command)

# Define the build_runner command
BUILD_RUNNER_CMD="$DART_CMD run build_runner build --delete-conflicting-outputs"

log_info "Using command: $BUILD_RUNNER_CMD"

# Run the build_runner command
log_step "Running build_runner to generate api files..."
log_step "Running build_runner to generate models files..."
log_step "Running build_runner to generate resources files..."
$BUILD_RUNNER_CMD || {
    log_error "build_runner command failed."
    exit 1
}

log_success "Build_runner generation complete."

# Exit the script
exit 0

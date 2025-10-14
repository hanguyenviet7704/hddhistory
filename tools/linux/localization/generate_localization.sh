#!/bin/bash

# Script to generate Flutter localization files from Google Sheets
# This script:
# 1. Generates module-specific ARB files from Google Sheets
# 2. Merges module ARB files into app ARB files
# 3. Runs Flutter's localization generation

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

log_info "Flutter Localization Generator"
echo "================================"
show_localization_config

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    log_error "Python 3 is not installed"
    exit 1
fi

# Store original PATH
ORIGINAL_PATH="$PATH"

# Setup virtual environment
VENV_DIR="$PROJECT_ROOT/.venv_localization"
if [ ! -d "$VENV_DIR" ]; then
    log_warning "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

# Activate virtual environment
log_step "Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# Check if required Python packages are installed
log_step "Checking Python dependencies..."
python3 -c "import requests" 2>/dev/null || {
    log_warning "Installing requests package..."
    pip install requests
}

# Create Python configuration file
PYTHON_CONFIG=$(create_python_config)
log_info "Created Python configuration: $PYTHON_CONFIG"

# Setup cleanup trap to ensure config file is deleted on exit
cleanup() {
    rm -f "$PYTHON_CONFIG" 2>/dev/null
}
trap cleanup EXIT

# Step 1: Generate module ARB files from Google Sheets
echo ""
log_step "Step 1: Generating module ARB files from Google Sheets..."
python3 "$SCRIPT_DIR/generate_arb_from_sheets.py" "$PYTHON_CONFIG"

# Step 2: Merge module ARB files into app ARB files
echo ""
log_step "Step 2: Merging module ARB files..."
python3 "$SCRIPT_DIR/merge_arb_files.py" "$PYTHON_CONFIG"

# Step 3: Run Flutter localization generation
echo ""
log_step "Step 3: Running Flutter localization generation..."

# Restore original PATH to ensure system commands are available
export PATH="$ORIGINAL_PATH"

# Get Flutter command from configuration
FLUTTER_CMD=$(get_flutter_command)
log_info "Using Flutter command: $FLUTTER_CMD"

# Validate Flutter availability
if ! command -v $(echo $FLUTTER_CMD | cut -d' ' -f1) &> /dev/null; then
    # Common Flutter installation locations as fallback
    POSSIBLE_PATHS=(
        "$HOME/flutter/bin/flutter"
        "$HOME/development/flutter/bin/flutter"
        "$HOME/.flutter/bin/flutter"
        "$HOME/fvm/default/bin/flutter"  # FVM default
    )

    FLUTTER_FOUND=false
    for path in "${POSSIBLE_PATHS[@]}"; do
        if [ -x "$path" ]; then
            FLUTTER_CMD="$path"
            FLUTTER_FOUND=true
            log_warning "Found Flutter at: $path"
            break
        fi
    done
    
    if [ "$FLUTTER_FOUND" = false ]; then
        log_warning "Flutter command not found in PATH"
        echo "Please specify the path to Flutter manually:"
        echo "1) Enter the full path to the flutter command"
        echo "2) Type 'skip' to skip Flutter generation"
        echo "3) Press Enter to try with 'flutter' anyway"
        read -p "> " FLUTTER_INPUT

        if [ "$FLUTTER_INPUT" = "skip" ]; then
            log_warning "Skipping Flutter generation step..."
            FLUTTER_CMD=""
        elif [ -n "$FLUTTER_INPUT" ]; then
            if [ -x "$FLUTTER_INPUT" ]; then
                FLUTTER_CMD="$FLUTTER_INPUT"
            else
                log_error "Specified path is not executable"
                echo "Skipping Flutter generation step..."
                FLUTTER_CMD=""
            fi
        fi
    fi
fi

if [ -n "$FLUTTER_CMD" ]; then
    log_step "Generating Flutter localization files with: $FLUTTER_CMD"
    $FLUTTER_CMD gen-l10n
    if [ $? -eq 0 ]; then
        log_success "Flutter localization files generated successfully"
    else
        log_error "Flutter localization generation failed"
        deactivate
        exit 1
    fi
else
    log_warning "Flutter localization files were not generated."
    echo "You will need to run 'flutter gen-l10n' manually to complete the process."
fi

# Deactivate virtual environment
deactivate

# Cleanup is handled by trap

echo ""
log_success "Localization generation completed successfully!"
echo ""
log_info "Generated files:"
echo "  - Module ARB files: $(get_module_dir)"
echo "  - App ARB files: $(get_app_dir)"
if [ -n "$FLUTTER_CMD" ]; then
    echo "  - Dart localization files: $(get_l10n_output_dir)"
else
    echo "  - Dart localization files: Not generated (run 'flutter gen-l10n' manually)"
fi 
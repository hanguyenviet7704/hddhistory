#!/bin/bash

# Enhanced SSH Key Generation Script with Centralized Configuration
# This script generates SSH keys for Git authentication using configuration from .info/ directory

# Navigate to the root directory relative to the current script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../../.."
cd "${ROOT_DIR}" || {
    echo "❌ Failed to navigate to the project root directory."
    exit 1
}

# Load common configuration functions
source "${ROOT_DIR}/tools/linux/common/common.sh" || {
    echo "❌ Failed to load common configuration library."
    echo "Make sure tools/linux/common/common.sh exists and is readable."
    exit 1
}

# Validate environment
if ! validate_environment; then
    exit 1
fi

# Get app information for SSH key generation
APP_NAME=$(get_app_name)
VERSION=$(get_pubspec_version)

clear
log_info "🔑 SSH Key Generation with Centralized Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "App: $APP_NAME"
echo "Version: $VERSION"
echo "Purpose: Git authentication (GitHub/GitLab)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Default values
DEFAULT_KEY_NAME="git_ssh_key"
DEFAULT_KEY_PATH="$HOME/.ssh/$DEFAULT_KEY_NAME"
DEFAULT_PASSPHRASE="git_ssh_pass"
DEFAULT_EMAIL=""

# Get Git user email if available
log_step "Detecting Git configuration..."
echo "Command: git config --global user.email"
GIT_EMAIL=$(git config --global user.email 2>/dev/null)
if [[ -n "$GIT_EMAIL" ]]; then
    DEFAULT_EMAIL="$GIT_EMAIL"
    log_success "Found Git email: $GIT_EMAIL"
else
    log_warning "No Git email configured globally"
fi
echo

# Get user preferences
log_step "🔑 SSH Key Generation for Git Authentication"
echo

read -p "Enter key name [${DEFAULT_KEY_NAME}]: " KEY_NAME
KEY_NAME=${KEY_NAME:-$DEFAULT_KEY_NAME}

read -p "Enter email for key comment [${DEFAULT_EMAIL}]: " EMAIL
EMAIL=${EMAIL:-$DEFAULT_EMAIL}

echo
log_warning "Do you want to use the default passphrase '$DEFAULT_PASSPHRASE'? (y/n)"
read -n 1 -r USE_DEFAULT_PASS
echo

if [[ $USE_DEFAULT_PASS =~ ^[Yy]$ ]]; then
    PASSPHRASE="$DEFAULT_PASSPHRASE"
    log_success "Using default passphrase."
else
    log_info "Enter your passphrase:"
    read -s PASSPHRASE
    log_info "Confirm your passphrase:"
    read -s PASSPHRASE_CONFIRM
    
    if [[ "$PASSPHRASE" != "$PASSPHRASE_CONFIRM" ]]; then
        log_error "Passphrases do not match. Exiting."
        exit 1
    fi
fi

KEY_PATH="$HOME/.ssh/$KEY_NAME"

# Check if key already exists
log_step "Checking for existing SSH key..."
if [[ -f "$KEY_PATH" ]]; then
    log_warning "SSH key already exists at $KEY_PATH"
    read -p "Do you want to overwrite it? (y/N) " -n 1 -r OVERWRITE
    echo
    if [[ ! $OVERWRITE =~ ^[Yy]$ ]]; then
        log_warning "Operation cancelled by user."
        exit 0
    fi
else
    log_info "No existing SSH key found. Proceeding with generation."
fi

# Generate SSH key
echo
log_step "Generating SSH key..."

# Print the command before execution
SSH_KEYGEN_ARGS=(
    "-t" "ed25519"
    "-f" "$KEY_PATH"
    "-N" "$PASSPHRASE"
    "-C" "$EMAIL"
)

log_info "Executing ssh-keygen command:"
echo "Command: ssh-keygen ${SSH_KEYGEN_ARGS[*]}"
echo

# Execute the command
ssh-keygen "${SSH_KEYGEN_ARGS[@]}"

# Check if key was generated successfully
if [[ ! -f "$KEY_PATH" ]]; then
    log_error "Failed to generate SSH key."
    exit 1
fi

# Add key to SSH agent
log_step "Adding key to SSH agent..."
echo "Command: eval \"\$(ssh-agent -s)\""
eval "$(ssh-agent -s)"
echo "Command: ssh-add -K \"$KEY_PATH\""
ssh-add -K "$KEY_PATH"

# Copy public key to clipboard
PUBLIC_KEY_PATH="$KEY_PATH.pub"
log_step "Copying public key to clipboard..."
if [[ -f "$PUBLIC_KEY_PATH" ]]; then
    echo "Command: cat \"$PUBLIC_KEY_PATH\" | pbcopy"
    cat "$PUBLIC_KEY_PATH" | pbcopy
    log_success "Public key copied to clipboard!"
else
    log_error "Public key file not found: $PUBLIC_KEY_PATH"
fi

echo
log_success "SSH key generated successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SSH Key Details:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "App: $APP_NAME"
echo "Version: $VERSION"
echo "Key Name: $KEY_NAME"
echo "Key Type: ed25519"
echo "Email: $EMAIL"
echo "Private Key: $KEY_PATH"
echo "Public Key: $PUBLIC_KEY_PATH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

log_step "📝 Next Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Add your SSH key to GitHub:"
echo "   a. Go to GitHub → Settings → SSH and GPG keys → New SSH key"
echo "   b. Paste the copied key and give it a title"
echo "   c. Click 'Add SSH key'"
echo
echo "2. Add your SSH key to GitLab:"
echo "   a. Go to GitLab → Preferences → SSH Keys"
echo "   b. Paste the copied key and give it a title"
echo "   c. Click 'Add key'"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

log_step "🧪 Test Commands:"
echo "• Test GitHub connection:"
echo "  ssh -T git@github.com"
echo
echo "• Test GitLab connection:"
echo "  ssh -T git@gitlab.com"
echo

log_step "🔗 Update Repository Remote URL:"
echo "• For GitHub repositories:"
echo "  git remote set-url origin git@github.com:username/repository.git"
echo
echo "• For GitLab repositories:"
echo "  git remote set-url origin git@gitlab.com:username/repository.git"
echo

log_step "📚 Documentation:"
echo "• GitHub SSH Setup: https://docs.github.com/en/authentication/connecting-to-github-with-ssh"
echo "• GitLab SSH Setup: https://docs.gitlab.com/ee/user/ssh.html" 
#!/bin/bash

# Navigate to the root directory relative to the current script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../../../.."
cd "${ROOT_DIR}" || {
    echo "❌ Failed to navigate to the project root directory."
    exit 1
}

echo "🚀 Setting up GitFlow workflow for the project..."
echo "📍 Project root: $(pwd)"

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Copy commit-msg hook
echo "📝 Installing commit message validation hook..."
cp "${SCRIPT_DIR}/hooks/commit-msg" .git/hooks/
chmod +x .git/hooks/commit-msg

# Copy pre-push hook  
echo "🔍 Installing pre-push validation hook..."
cp "${SCRIPT_DIR}/hooks/pre-push" .git/hooks/
chmod +x .git/hooks/pre-push

# Copy configuration file
echo "⚙️  Installing GitFlow configuration..."
cp "${SCRIPT_DIR}/.gitflow.config" .gitflow.config

# Initialize git flow branches if they don't exist
echo "🌿 Checking branch structure..."
git show-ref --verify --quiet refs/heads/main || {
    echo "Creating main branch..."
    git checkout -b main
}

git show-ref --verify --quiet refs/heads/develop || {
    echo "Creating develop branch..."
    git checkout -b develop
}

# Create local config for git flow
git config gitflow.branch.master main
git config gitflow.branch.develop develop
git config gitflow.prefix.feature feature/
git config gitflow.prefix.release release/
git config gitflow.prefix.hotfix hotfix/
git config gitflow.prefix.support support/
git config gitflow.prefix.versiontag v

echo "✅ GitFlow setup completed successfully!"
echo ""
echo "📚 Available commands:"
echo "  - ./tools/macos/git/workflow/feature.sh  : Manage feature branches"
echo "  - ./tools/macos/git/workflow/fix.sh      : Manage fix branches"
echo "  - ./tools/macos/git/workflow/release.sh  : Manage release branches"
echo "  - ./tools/macos/git/workflow/hotfix.sh   : Manage hotfix branches"
echo ""
echo "💡 Run './tools/macos/git/workflow/feature.sh help' for usage instructions" 
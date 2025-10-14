#!/bin/bash

# Navigate to the root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../../.."
cd "${ROOT_DIR}" || {
    echo "❌ Failed to navigate to the project root directory."
    exit 1
}

# Source utilities
source "${SCRIPT_DIR}/utils.sh"

# Function to display usage
show_usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  start <version>       Start a new release branch (e.g., 1.2.0)"
    echo "  finish [version]      Finish current release branch"
    echo "  publish               Push release branch to remote"
    echo "  list                  List all release branches"
    echo "  help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start 1.2.0"
    echo "  $0 finish"
    echo "  $0 publish"
}

# Handle commands
case "$1" in
    start)
        if [ -z "$2" ]; then
            echo "❌ Error: Missing version number"
            echo "Usage: $0 start <version>"
            exit 1
        fi
        
        VERSION="$2"
        BRANCH_NAME="release/${VERSION}"
        
        echo "🚀 Starting new release: $BRANCH_NAME"
        
        # Ensure we're on develop and up to date
        git checkout develop
        git pull origin develop
        
        # Create and checkout new release branch
        git checkout -b "$BRANCH_NAME"
        
        echo "✅ Release branch created: $BRANCH_NAME"
        echo "💡 You can now prepare the release (update version, changelog, etc.)"
        ;;
        
    finish)
        # Get current branch
        CURRENT_BRANCH=$(git branch --show-current)
        
        if [[ ! "$CURRENT_BRANCH" =~ ^release/ ]]; then
            echo "❌ Error: Not on a release branch"
            echo "Current branch: $CURRENT_BRANCH"
            exit 1
        fi
        
        # Extract version from branch name
        VERSION=$(echo "$CURRENT_BRANCH" | sed 's/release\///')
        
        if [ -n "$2" ]; then
            VERSION="$2"
        fi
        
        echo "🏁 Finishing release: $CURRENT_BRANCH"
        echo "📦 Version: $VERSION"
        
        # Check if there are uncommitted changes
        check_clean_working_tree
        
        # Make sure main and develop are up to date
        git fetch origin main develop
        
        # Push current branch to remote if it's not already there
        if ! branch_exists_remote "$CURRENT_BRANCH"; then
            echo "📤 Pushing release branch to remote..."
            git push -u origin "$CURRENT_BRANCH"
        else
            echo "📝 Release branch already exists on remote"
            
            # Make sure local branch is up to date with remote
            echo "🔄 Updating local branch from remote..."
            git pull origin "$CURRENT_BRANCH"
        fi
        
        # Create PR/MR titles
        MAIN_PR_TITLE="release: Release version $VERSION"
        
        # Create pull request to main
        echo "🔗 Creating pull request to main..."
        create_pull_request "$CURRENT_BRANCH" "main" "$MAIN_PR_TITLE"
        
        # Also create pull request to develop for backporting
        echo "🔗 Creating pull request to develop..."
        DEV_PR_TITLE="release: Merge release $VERSION back to develop"
        create_pull_request "$CURRENT_BRANCH" "develop" "$DEV_PR_TITLE"
        
        echo "✅ Release completed and pull requests created!"
        echo "⚠️  IMPORTANT: After the PRs are approved and merged, tag the main branch:"
        echo "   git checkout main"
        echo "   git pull origin main"
        echo "   git tag -a \"$VERSION\" -m \"Version $VERSION\""
        echo "   git push origin \"$VERSION\""
        echo "💡 After the pull requests are merged, you can delete your local branch with:"
        echo "   git branch -d $CURRENT_BRANCH"
        ;;
        
    publish)
        # Get current branch
        CURRENT_BRANCH=$(git branch --show-current)
        
        if [[ ! "$CURRENT_BRANCH" =~ ^release/ ]]; then
            echo "❌ Error: Not on a release branch"
            echo "Current branch: $CURRENT_BRANCH"
            exit 1
        fi
        
        echo "📤 Publishing release: $CURRENT_BRANCH"
        git push -u origin "$CURRENT_BRANCH"
        
        echo "✅ Release published to remote"
        echo "💡 Team can now test the release candidate"
        ;;
        
    list)
        echo "📋 Release branches:"
        git branch -a | grep "release/" | sed 's/remotes\/origin\///'  | sort | uniq
        echo ""
        echo "🏷️  Release tags:"
        git tag -l | sort -V
        ;;
        
    help|--help|-h)
        show_usage
        ;;
        
    *)
        echo "❌ Unknown command: $1"
        show_usage
        exit 1
        ;;
esac 
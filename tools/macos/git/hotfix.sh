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
    echo "  start <ticket-id> <description>  Start a new hotfix branch"
    echo "  finish                           Finish current hotfix branch"
    echo "  publish                          Push hotfix branch to remote"
    echo "  list                             List all hotfix branches"
    echo "  help                             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start TG-789 critical-payment-fix"
    echo "  $0 finish"
    echo "  $0 publish"
    echo ""
    echo "⚠️  Note: Hotfixes should only be used for critical production issues"
}

# Handle commands
case "$1" in
    start)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "❌ Error: Missing ticket ID or description"
            echo "Usage: $0 start <ticket-id> <description>"
            exit 1
        fi
        
        TICKET_ID="$2"
        DESCRIPTION="$3"
        BRANCH_NAME="hotfix/${TICKET_ID}-${DESCRIPTION}"
        
        echo "🚨 Starting emergency hotfix: $BRANCH_NAME"
        
        # Ensure we're on main and up to date
        git checkout main
        git pull origin main
        
        # Create and checkout new hotfix branch
        git checkout -b "$BRANCH_NAME"
        
        echo "✅ Hotfix branch created: $BRANCH_NAME"
        echo "⚡ You can now implement the critical fix"
        ;;
        
    finish)
        # Get current branch
        CURRENT_BRANCH=$(git branch --show-current)
        
        if [[ ! "$CURRENT_BRANCH" =~ ^hotfix/ ]]; then
            echo "❌ Error: Not on a hotfix branch"
            echo "Current branch: $CURRENT_BRANCH"
            exit 1
        fi
        
        echo "🏁 Finishing hotfix: $CURRENT_BRANCH"
        
        # Check if there are uncommitted changes
        check_clean_working_tree
        
        # Extract ticket ID from branch name
        TICKET_ID=$(extract_ticket_id "$CURRENT_BRANCH")
        
        # Get the latest tag for version bump
        LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0")
        echo "📦 Latest version: $LATEST_TAG"
        
        # Create a new patch version based on latest tag
        if [[ $LATEST_TAG =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
            MAJOR="${BASH_REMATCH[1]}"
            MINOR="${BASH_REMATCH[2]}"
            PATCH="${BASH_REMATCH[3]}"
            NEW_PATCH=$((PATCH + 1))
            NEW_TAG="${MAJOR}.${MINOR}.${NEW_PATCH}"
            echo "🏷️  New version tag will be: $NEW_TAG"
        fi
        
        # Make sure main and develop are up to date
        git fetch origin main develop
        
        # Push current branch to remote if it's not already there
        if ! branch_exists_remote "$CURRENT_BRANCH"; then
            echo "📤 Pushing hotfix branch to remote..."
            git push -u origin "$CURRENT_BRANCH"
        else
            echo "📝 Hotfix branch already exists on remote"
            
            # Make sure local branch is up to date with remote
            echo "🔄 Updating local branch from remote..."
            git pull origin "$CURRENT_BRANCH"
        fi
        
        # Create PR/MR title based on branch name
        BRANCH_DESCRIPTION=$(echo "$CURRENT_BRANCH" | sed -E 's/^hotfix\/[A-Z]+-[0-9]+-(.+)/\1/')
        MAIN_PR_TITLE="hotfix-${TICKET_ID}: $(echo $BRANCH_DESCRIPTION | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g')"
        
        # Create pull request to main
        echo "🔗 Creating pull request to main..."
        create_pull_request "$CURRENT_BRANCH" "main" "$MAIN_PR_TITLE"
        
        # Also create pull request to develop
        echo "🔗 Creating pull request to develop..."
        DEV_PR_TITLE="$MAIN_PR_TITLE (Backport to develop)"
        create_pull_request "$CURRENT_BRANCH" "develop" "$DEV_PR_TITLE"
        
        echo "✅ Hotfix completed and pull requests created!"
        echo "⚠️  IMPORTANT: After the PRs are approved and merged, tag the main branch:"
        if [[ -n "$NEW_TAG" ]]; then
            echo "   git checkout main"
            echo "   git pull origin main"
            echo "   git tag -a \"$NEW_TAG\" -m \"Hotfix version $NEW_TAG\""
            echo "   git push origin \"$NEW_TAG\""
        fi
        echo "💡 After the pull requests are merged, you can delete your local branch with:"
        echo "   git branch -d $CURRENT_BRANCH"
        ;;
        
    publish)
        # Get current branch
        CURRENT_BRANCH=$(git branch --show-current)
        
        if [[ ! "$CURRENT_BRANCH" =~ ^hotfix/ ]]; then
            echo "❌ Error: Not on a hotfix branch"
            echo "Current branch: $CURRENT_BRANCH"
            exit 1
        fi
        
        echo "📤 Publishing hotfix: $CURRENT_BRANCH"
        git push -u origin "$CURRENT_BRANCH"
        
        echo "✅ Hotfix published to remote"
        echo "⚡ You can now create an urgent merge request"
        ;;
        
    list)
        echo "📋 Hotfix branches:"
        git branch -a | grep "hotfix/" | sed 's/remotes\/origin\///'  | sort | uniq
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
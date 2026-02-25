#!/bin/bash

# Navigate to the root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../../../.."
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
    echo "  start <ticket-id> <description>  Start a new feature branch"
    echo "  finish                           Finish current feature branch"
    echo "  publish                          Push feature branch to remote"
    echo "  list                             List all feature branches"
    echo "  help                             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start TG-123 login-social"
    echo "  $0 finish"
    echo "  $0 publish"
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
        BRANCH_NAME="feature/${TICKET_ID}-${DESCRIPTION}"
        
        echo "🚀 Starting new feature: $BRANCH_NAME"
        
        # Ensure we're on develop and up to date
        git checkout develop
        git pull origin develop
        
        # Create and checkout new feature branch
        git checkout -b "$BRANCH_NAME"
        
        echo "✅ Feature branch created: $BRANCH_NAME"
        echo "💡 You can now start working on your feature"
        ;;
        
    finish)
        # Get current branch
        CURRENT_BRANCH=$(git branch --show-current)
        
        if [[ ! "$CURRENT_BRANCH" =~ ^feature/ ]]; then
            echo "❌ Error: Not on a feature branch"
            echo "Current branch: $CURRENT_BRANCH"
            exit 1
        fi
        
        echo "🏁 Finishing feature: $CURRENT_BRANCH"
        
        # Check if there are uncommitted changes
        check_clean_working_tree
        
        # Extract ticket ID from branch name
        TICKET_ID=$(extract_ticket_id "$CURRENT_BRANCH")
        
        # Make sure develop is up to date
        git fetch origin develop
        
        # Push current branch to remote if it's not already there
        if ! branch_exists_remote "$CURRENT_BRANCH"; then
            echo "📤 Pushing feature branch to remote..."
            git push -u origin "$CURRENT_BRANCH"
        else
            echo "📝 Feature branch already exists on remote"
            
            # Make sure local branch is up to date with remote
            echo "🔄 Updating local branch from remote..."
            git pull origin "$CURRENT_BRANCH"
        fi
        
        # Create PR/MR title based on branch name
        BRANCH_DESCRIPTION=$(echo "$CURRENT_BRANCH" | sed -E 's/^feature\/[A-Z]+-[0-9]+-(.+)/\1/')
        PR_TITLE="feature-${TICKET_ID}: $(echo $BRANCH_DESCRIPTION | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g')"
        
        # Create pull request
        echo "🔗 Creating pull request..."
        create_pull_request "$CURRENT_BRANCH" "develop" "$PR_TITLE"
        
        echo "✅ Feature completed and pull request created!"
        echo "💡 After the pull request is approved and merged, you can delete your local branch with:"
        echo "   git branch -d $CURRENT_BRANCH"
        ;;
        
    publish)
        # Get current branch
        CURRENT_BRANCH=$(git branch --show-current)
        
        if [[ ! "$CURRENT_BRANCH" =~ ^feature/ ]]; then
            echo "❌ Error: Not on a feature branch"
            echo "Current branch: $CURRENT_BRANCH"
            exit 1
        fi
        
        echo "📤 Publishing feature: $CURRENT_BRANCH"
        git push -u origin "$CURRENT_BRANCH"
        
        echo "✅ Feature published to remote"
        echo "💡 You can now create a merge request on GitLab/GitHub"
        ;;
        
    list)
        echo "📋 Feature branches:"
        git branch -a | grep "feature/" | sed 's/remotes\/origin\///'  | sort | uniq
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
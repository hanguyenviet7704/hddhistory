#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if git is installed
check_git() {
    if ! command -v git &> /dev/null; then
        echo -e "${RED}❌ Git is not installed. Please install git first.${NC}"
        exit 1
    fi
}

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}❌ Not in a git repository${NC}"
        exit 1
    fi
}

# Function to check if there are uncommitted changes
check_clean_working_tree() {
    if ! git diff-index --quiet HEAD --; then
        echo -e "${YELLOW}⚠️  You have uncommitted changes${NC}"
        echo "Please commit or stash your changes before proceeding."
        exit 1
    fi
}

# Function to validate branch name format
validate_branch_name() {
    local branch_type="$1"
    local branch_name="$2"
    
    # Check if branch name matches the pattern
    if [[ ! "$branch_name" =~ ^${branch_type}/[A-Z]+-[0-9]+-[a-z0-9-]+$ ]]; then
        echo -e "${RED}❌ Invalid branch name format${NC}"
        echo "Expected format: ${branch_type}/TICKET-ID-description"
        echo "Example: ${branch_type}/TG-123-login-feature"
        return 1
    fi
    
    return 0
}

# Function to extract ticket ID from branch name
extract_ticket_id() {
    local branch_name="$1"
    echo "$branch_name" | sed -E 's/^[^\/]+\/([A-Z]+-[0-9]+)-.*/\1/'
}

# Function to confirm action
confirm_action() {
    local message="$1"
    echo -e "${YELLOW}$message${NC}"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 0
    fi
}

# Function to check if branch exists locally
branch_exists_local() {
    local branch_name="$1"
    git show-ref --verify --quiet "refs/heads/$branch_name"
}

# Function to check if branch exists on remote
branch_exists_remote() {
    local branch_name="$1"
    git ls-remote --heads origin "$branch_name" | grep -q "$branch_name"
}

# Function to get current branch
get_current_branch() {
    git branch --show-current
}

# Function to validate commit message format
validate_commit_message() {
    local commit_msg="$1"
    local pattern="^(feature|fix|hotfix|release)(-[A-Z]+-[0-9]+)?(-[a-z0-9-]+)?: .+"
    
    if [[ ! "$commit_msg" =~ $pattern ]]; then
        echo -e "${RED}❌ Invalid commit message format${NC}"
        echo "Expected format: type-TICKET-ID-description: message"
        echo "Examples:"
        echo "  feature-TG-123-login: Add social login functionality"
        echo "  fix-TG-456-validation: Fix email validation regex"
        return 1
    fi
    
    return 0
}

# Function to detect the git repository provider (GitHub or GitLab)
detect_git_provider() {
    local remote_url=$(git remote get-url origin 2>/dev/null)
    
    if [[ "$remote_url" == *"github.com"* ]]; then
        echo "github"
    elif [[ "$remote_url" == *"gitlab.com"* ]]; then
        echo "gitlab"
    else
        # Try to detect self-hosted instances
        if [[ "$remote_url" == *"gitlab"* ]]; then
            echo "gitlab"
        else
            # Default to GitHub if unsure
            echo "github"
        fi
    fi
}

# Function to get the repository owner and name from remote URL
get_repo_info() {
    local remote_url=$(git remote get-url origin 2>/dev/null)
    
    # Remove protocol and domain part
    local repo_path=$(echo "$remote_url" | sed -E 's/^(https:\/\/|git@)([^\/]+)(\/|:)//')
    
    # Ensure .git suffix is removed
    repo_path=${repo_path%.git}
    
    echo "$repo_path"
}

# Function to create a pull request
create_pull_request() {
    local source_branch="$1"
    local target_branch="$2"
    local pr_title="$3"
    
    # Check if source branch exists on remote
    if ! branch_exists_remote "$source_branch"; then
        echo -e "${YELLOW}⚠️  Source branch doesn't exist on remote. Pushing...${NC}"
        git push -u origin "$source_branch"
    fi
    
    # Detect provider and create PR
    local provider=$(detect_git_provider)
    local repo_info=$(get_repo_info)
    
    if [[ "$provider" == "github" ]]; then
        local github_url="https://github.com/$repo_info/compare/$target_branch...$source_branch?quick_pull=1"
        echo -e "${GREEN}🔗 Opening GitHub pull request page...${NC}"
        echo "PR URL: $github_url"
        open "$github_url" 2>/dev/null || xdg-open "$github_url" 2>/dev/null || echo -e "${YELLOW}⚠️  Could not open browser. Please manually create PR at: $github_url${NC}"
    elif [[ "$provider" == "gitlab" ]]; then
        # For GitLab, ensure the URL is properly formatted (no .git suffix)
        if [[ "$repo_info" == *".git" ]]; then
            repo_info=${repo_info%.git}
        fi
        
        # For GitLab, we need to use the web URL format
        local gitlab_url="https://gitlab.com/$repo_info/-/merge_requests/new?merge_request%5Bsource_branch%5D=$source_branch&merge_request%5Btarget_branch%5D=$target_branch"
        
        # Extract domain from remote URL
        local remote_url=$(git remote get-url origin 2>/dev/null)
        if [[ ! "$remote_url" == *"gitlab.com"* ]]; then
            # Handle self-hosted GitLab instances
            local domain=$(echo "$remote_url" | sed -E 's/^(https:\/\/|git@)([^\/]+)(\/|:).*/\2/')
            if [[ "$domain" != "gitlab.com" ]]; then
                gitlab_url="https://$domain/$repo_info/-/merge_requests/new?merge_request%5Bsource_branch%5D=$source_branch&merge_request%5Btarget_branch%5D=$target_branch"
            fi
        fi
        
        echo -e "${GREEN}🔗 Opening GitLab merge request page...${NC}"
        echo "MR URL: $gitlab_url"
        open "$gitlab_url" 2>/dev/null || xdg-open "$gitlab_url" 2>/dev/null || echo -e "${YELLOW}⚠️  Could not open browser. Please manually create MR at: $gitlab_url${NC}"
    else
        echo -e "${YELLOW}⚠️  Unknown Git provider. Please manually create a pull request from $source_branch to $target_branch.${NC}"
    fi
}

# Function to show branch status
show_branch_status() {
    echo -e "${BLUE}📊 Branch Status${NC}"
    echo "Current branch: $(get_current_branch)"
    echo "Tracking: $(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo 'Not tracking any remote branch')"
    echo ""
    echo "Recent commits:"
    git log --oneline -5
}

# Perform basic checks
check_git
check_git_repo 
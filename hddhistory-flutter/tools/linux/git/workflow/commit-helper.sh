#!/bin/bash

# Commit Message Helper for GitFlow

# Navigate to the root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../../../.."
cd "${ROOT_DIR}" || {
    echo "❌ Failed to navigate to the project root directory."
    exit 1
}

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

# Extract ticket ID from branch
TICKET_ID=""
if [[ "$CURRENT_BRANCH" =~ ([A-Z]+-[0-9]+) ]]; then
    # Get the last ticket ID if multiple exist
    TICKET_ID=$(echo "$CURRENT_BRANCH" | grep -oE '[A-Z]+-[0-9]+' | tail -1)
fi

# Get branch type
BRANCH_TYPE=""
if [[ "$CURRENT_BRANCH" =~ ^(feature|fix|release|hotfix)/ ]]; then
    BRANCH_TYPE="${BASH_REMATCH[1]}"
fi

# Function to analyze staged files
analyze_staged_files() {
    local files=$(git diff --cached --name-only)
    local scope=""
    
    if [[ -z "$files" ]]; then
        echo "No staged files found."
        return 1
    fi
    
    # Determine scope based on file paths
    if echo "$files" | grep -q "lib/src/presentation/blocs/"; then
        scope="bloc"
    elif echo "$files" | grep -q "lib/src/presentation/pages/"; then
        scope="ui"
    elif echo "$files" | grep -q "lib/src/presentation/widgets/"; then
        scope="widget"
    elif echo "$files" | grep -q "lib/config/routes/"; then
        scope="routing"
    elif echo "$files" | grep -q "lib/src/data/"; then
        scope="data"
    elif echo "$files" | grep -q "lib/src/domain/"; then
        scope="domain"
    fi
    
    echo "$scope"
}

# Display header
clear
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              ${CYAN}Commit Message Helper${BLUE}                          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Show current context
echo -e "${GREEN}📍 Current Context:${NC}"
echo -e "  Branch: ${CYAN}$CURRENT_BRANCH${NC}"
if [[ -n "$TICKET_ID" ]]; then
    echo -e "  Ticket: ${CYAN}$TICKET_ID${NC}"
fi
if [[ -n "$BRANCH_TYPE" ]]; then
    echo -e "  Type: ${CYAN}$BRANCH_TYPE${NC}"
fi
echo ""

# Show staged files
echo -e "${GREEN}📄 Staged Files:${NC}"
git diff --cached --name-only | head -10 | sed 's/^/  /'
if [[ $(git diff --cached --name-only | wc -l) -gt 10 ]]; then
    echo "  ... and $(($(git diff --cached --name-only | wc -l) - 10)) more files"
fi
echo ""

# Get scope from staged files
SCOPE=$(analyze_staged_files)

# Generate commit message suggestions
echo -e "${GREEN}💡 Suggested Commit Messages:${NC}"
echo ""

if [[ -n "$TICKET_ID" ]]; then
    echo -e "${YELLOW}With ticket ID:${NC}"
    echo "  $BRANCH_TYPE-$TICKET_ID: <description>"
    
    if [[ -n "$SCOPE" ]]; then
        echo "  $BRANCH_TYPE($SCOPE)-$TICKET_ID: <description>"
    fi
    echo ""
fi

echo -e "${YELLOW}With scope:${NC}"
if [[ -n "$SCOPE" ]]; then
    echo "  $BRANCH_TYPE($SCOPE): <description>"
else
    echo "  $BRANCH_TYPE(<scope>): <description>"
fi
echo ""

echo -e "${GREEN}📝 Examples based on your changes:${NC}"

# Provide context-specific examples
if echo "$(git diff --cached --name-only)" | grep -q "color_picker"; then
    echo "  ${BRANCH_TYPE}-${TICKET_ID}: Implement color picker functionality"
    echo "  ${BRANCH_TYPE}(gallery): Add color picker to gallery view"
fi

if echo "$(git diff --cached --name-only)" | grep -q "gallery"; then
    echo "  ${BRANCH_TYPE}-${TICKET_ID}: Update gallery view components"
    echo "  ${BRANCH_TYPE}(ui): Enhance gallery picture view"
fi

if echo "$(git diff --cached --name-only)" | grep -q "route"; then
    echo "  ${BRANCH_TYPE}-${TICKET_ID}: Add routing for color picker"
    echo "  ${BRANCH_TYPE}(routing): Configure color picker routes"
fi

if echo "$(git diff --cached --name-only)" | grep -q "bloc\|cubit\|state"; then
    echo "  ${BRANCH_TYPE}-${TICKET_ID}: Add state management for color picker"
    echo "  ${BRANCH_TYPE}(bloc): Implement color picker cubit"
fi

echo ""
echo -e "${BLUE}📋 Remember:${NC}"
echo "  • Use imperative mood: 'Add' not 'Added'"
echo "  • Keep under 50 characters"
echo "  • Be specific and descriptive"
echo "  • No period at the end"
echo ""

# Interactive mode
echo -e "${GREEN}🎯 Generate commit message? (y/n)${NC}"
read -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Enter your commit description:${NC}"
    read -p "> " description
    
    if [[ -n "$TICKET_ID" ]]; then
        COMMIT_MSG="$BRANCH_TYPE-$TICKET_ID: $description"
    else
        COMMIT_MSG="$BRANCH_TYPE: $description"
    fi
    
    echo ""
    echo -e "${GREEN}Generated commit message:${NC}"
    echo -e "${CYAN}$COMMIT_MSG${NC}"
    echo ""
    echo -e "${YELLOW}Copy to clipboard? (y/n)${NC}"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$COMMIT_MSG" | pbcopy
        echo -e "${GREEN}✅ Copied to clipboard!${NC}"
    fi
fi 
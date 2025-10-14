# New Pull Request to Develop - Agent Command

## Overview
This command generates a comprehensive pull request content based on git diff between the current feature branch and develop branch, then updates the PR content file for easy copying.

## Usage Steps

### 1. Get Git Diff Statistics and Changes
```bash
# Get change statistics
git diff develop --stat

# Get list of changed files
git diff develop --name-only

# Get commit history between develop and current branch
git log develop..HEAD --oneline

# Get current branch name
git branch --show-current
```

### 2. Analyze Key Changes
```bash
# Look at specific important files to understand changes
git diff develop [important-file-path] | head -30
```

### 3. Generate PR Content Structure

#### Essential PR Content Elements:
- **Title**: Use format `feature-TICKET-ID: Brief description`
- **Summary**: High-level overview of changes
- **Change Statistics**: File counts and line changes
- **Key Changes**: Commit history and main enhancements
- **File Categories**: Organized by type (source code, config, etc.)
- **Testing Checklist**: Standard testing requirements
- **Review Focus Areas**: What reviewers should pay attention to
- **Related Information**: Ticket IDs, branch names, deployment notes

#### PR Title Format
Extract ticket ID from branch name pattern:
- `feature/TICKET-ID/TICKET-ID-description` → Use second TICKET-ID
- `feature/TICKET-ID-description` → Use TICKET-ID

### 4. Update pr_content.md
Replace content with generated PR description including:
- Proper commit message format compliance
- Categorized file changes
- Clear enhancement descriptions
- Testing and review guidelines

### 5. Final Output
The command produces:
- Updated `pr_content.md` with complete PR description
- Ready-to-copy content for GitLab/GitHub PR creation
- Organized change summary for easy review

## Command Automation
```bash
# Complete workflow in one sequence:
git diff develop --stat
git diff develop --name-only  
git log develop..HEAD --oneline
git branch --show-current
# Then update pr_content.md with generated content
```

## Key Features
- **Automatic branch/ticket detection**
- **Change categorization** (source code, config, documentation)
- **Commit message compliance checking**
- **Standardized PR template format**
- **File change analysis and organization**

## Notes for Future Agents
- Always extract ticket ID from current branch name
- Follow GitFlow commit message conventions: `type-TICKET-ID: description`
- Categorize changes by file type and importance
- Include proper testing and review checklists
- Generate deployment notes when applicable
- Maintain consistency with project PR standards

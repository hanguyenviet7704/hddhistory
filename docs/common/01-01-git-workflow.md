# Git Workflow and Branching Strategy

This document outlines the Git workflow and branching strategy used across Flutter projects.

## Branching Strategy

### Main Branches
- **`develop`**: Main development branch where all features are integrated
- **`main`**: Production-ready code (if applicable)

### Feature Branches
- **Format**: `feature/TICKET-ID/TICKET-ID-description` or `feature/TICKET-ID-description`
- **Purpose**: Development of new features
- **Examples**:
  - `feature/ARTLEXIS-123/ARTLEXIS-123-add-user-authentication`
  - `feature/ARTLEXIS-456-implement-dark-mode`

### Other Branch Types
- **`fix/TICKET-ID-description`**: Bug fixes
- **`refactor/TICKET-ID-description`**: Code refactoring
- **`chore/TICKET-ID-description`**: Maintenance tasks

## Workflow Process

### 1. Starting New Work
```bash
# Switch to develop and pull latest changes
git checkout develop
git pull origin develop

# Create new feature branch
git checkout -b feature/ARTLEXIS-123-add-login-screen
```

### 2. During Development
```bash
# Regular commits during development
git add .
git commit -m "feature-ARTLEXIS-123: Add login form validation"

# Push branch to remote
git push -u origin feature/ARTLEXIS-123-add-login-screen
```

### 3. Code Review and Integration
```bash
# Create pull/merge request to develop branch
# After review approval, merge to develop
git checkout develop
git pull origin develop
```

### 4. Branch Cleanup
```bash
# Delete local branch after merge
git branch -d feature/ARTLEXIS-123-add-login-screen

# Delete remote branch
git push origin --delete feature/ARTLEXIS-123-add-login-screen
```

## GitFlow Configuration

This project uses GitFlow with the following configuration:

```ini
[gitflow "branch"]
    master = main
    develop = develop

[gitflow "prefix"]
    feature = feature/
    bugfix = fix/
    release = release/
    hotfix = hotfix/
    support = support/
    versiontag = v
```

## Best Practices

### Branch Naming
- Use descriptive names that indicate the purpose
- Include ticket/issue ID when available
- Use kebab-case for descriptions
- Keep names concise but meaningful

### Commit Frequency
- Make small, focused commits
- Commit working code frequently
- Each commit should represent a logical unit of work

### Before Merging
- Ensure all tests pass
- Run linting and formatting checks
- Rebase on latest develop if needed
- Squash commits if appropriate

### Merge Strategy
- Use merge requests/pull requests for all changes
- Require code review before merging
- Use squash and merge for feature branches
- Maintain linear history on develop branch

## Common Commands

```bash
# Check current branch status
git status
git branch -v

# View commit history
git log --oneline --graph

# Sync with remote changes
git fetch --all
git pull origin develop

# Interactive rebase for commit cleanup
git rebase -i HEAD~3

# Push force after rebase (use with caution)
git push --force-with-lease
```

## Troubleshooting

### Resolving Conflicts
```bash
# During merge conflicts
git status                    # See conflicted files
# Edit files to resolve conflicts
git add .                     # Stage resolved files
git commit                    # Complete the merge
```

### Undoing Changes
```bash
# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Undo changes to specific file
git checkout -- filename.dart
```

### Branch Recovery
```bash
# Find deleted branch commits
git reflog

# Recover deleted branch
git checkout -b recovered-branch commit-hash
```
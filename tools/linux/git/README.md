# GitFlow Workflow Setup

This directory contains scripts and tools for implementing GitFlow workflow in your project. The setup is designed to be reusable across multiple projects.

## 🚀 Quick Start

### Initial Setup

```bash
# Run the setup script from project root
./tools/macos/git/setup.sh
```

This will:
- Install git hooks for commit message validation
- Install pre-push validation hooks
- Copy GitFlow configuration to project root
- Initialize main and develop branches if they don't exist

### Basic Workflow Commands

```bash
# Start a new feature
./tools/macos/git/feature.sh start ARTLEXIS-123 login-social

# Publish feature to remote (for code review)
./tools/macos/git/feature.sh publish

# Finish feature (push to remote and create PR)
./tools/macos/git/feature.sh finish

# Start a bug fix
./tools/macos/git/fix.sh start ARTLEXIS-456 validation-error

# Create a release
./tools/macos/git/release.sh start 1.2.0

# Emergency hotfix
./tools/macos/git/hotfix.sh start ARTLEXIS-789 critical-payment-fix
```

## 📋 GitFlow Overview

### Branch Structure

```
main            (production-ready code)
├── hotfix/*    (emergency fixes)
└── release/*   (release preparation)

develop         (integration branch)
├── feature/*   (new features)
└── fix/*       (bug fixes)
```

### Branch Naming Convention

- **Feature**: `feature/TICKET-ID-description`
  - Example: `feature/ARTLEXIS-123-login-social`
- **Fix**: `fix/TICKET-ID-description`
  - Example: `fix/ARTLEXIS-456-validation-error`
- **Release**: `release/VERSION`
  - Example: `release/1.2.0`
- **Hotfix**: `hotfix/TICKET-ID-description`
  - Example: `hotfix/ARTLEXIS-789-payment-crash`

### Commit Message Format

```
type(scope): subject

# With ticket reference:
type-TICKET-ID-description: subject
```

**Valid types:**
- `feature`: New feature
- `fix`: Bug fix
- `hotfix`: Critical bug fix
- `release`: Release preparation
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Maintenance tasks

**Examples:**
```bash
feature(auth): Add social login functionality
fix(validation): Fix email regex pattern
feature-ARTLEXIS-123-login: Implement OAuth2 authentication
fix-TG-456: Resolve payment gateway timeout
```

## 🔧 Available Scripts

### setup.sh
Initializes GitFlow in your project:
- Installs git hooks
- Sets up branch structure
- Configures git flow settings

### feature.sh
Manages feature branches:
```bash
./tools/macos/git/feature.sh start <ticket-id> <description>  # Start new feature
./tools/macos/git/feature.sh publish                          # Push to remote
./tools/macos/git/feature.sh finish                           # Create PR to develop
./tools/macos/git/feature.sh list                             # List features
```

### fix.sh
Manages bug fix branches:
```bash
./tools/macos/git/fix.sh start <ticket-id> <description>  # Start bug fix
./tools/macos/git/fix.sh publish                          # Push to remote
./tools/macos/git/fix.sh finish                           # Create PR to develop
./tools/macos/git/fix.sh list                             # List fixes
```

### release.sh
Manages releases:
```bash
./tools/macos/git/release.sh start <version>  # Start release
./tools/macos/git/release.sh publish          # Push to remote
./tools/macos/git/release.sh finish           # Create PRs to main & develop
./tools/macos/git/release.sh list             # List releases
```

### hotfix.sh
Manages emergency fixes:
```bash
./tools/macos/git/hotfix.sh start <ticket-id> <description>  # Start hotfix
./tools/macos/git/hotfix.sh publish                          # Push to remote
./tools/macos/git/hotfix.sh finish                           # Create PRs to main & develop
./tools/macos/git/hotfix.sh list                             # List hotfixes
```

## 🪝 Git Hooks

### commit-msg
Validates commit messages against the project convention:
- Checks format: `type(scope): subject`
- Validates commit types
- Suggests including ticket ID from branch name
- Warns about message length

### pre-push
Validates before pushing:
- Checks branch name format
- Warns about direct pushes to protected branches
- Detects WIP commits
- Runs Flutter analyze (if applicable)

## ⚙️ Configuration

The `.gitflow.config` file contains all workflow settings:

```bash
# Main branches
MAIN_BRANCH=main
DEVELOP_BRANCH=develop

# Branch prefixes
FEATURE_PREFIX=feature/
FIX_PREFIX=fix/
RELEASE_PREFIX=release/
HOTFIX_PREFIX=hotfix/

# Validation rules
REQUIRE_TICKET_ID=true
VALIDATE_COMMIT_MSG=true
RUN_TESTS_BEFORE_PUSH=true
```

## 📚 Workflow Examples

### Feature Development

```bash
# 1. Start feature
./tools/macos/git/feature.sh start ARTLEXIS-123 user-profile

# 2. Work on feature
git add .
git commit -m "feature(profile): Add user avatar upload"

# 3. Push for review
./tools/macos/git/feature.sh publish

# 4. When ready, create a pull request
./tools/macos/git/feature.sh finish
```

### Bug Fixing

```bash
# 1. Start fix
./tools/macos/git/fix.sh start ARTLEXIS-456 login-validation

# 2. Fix the bug
git add .
git commit -m "fix(auth): Validate email format correctly"

# 3. Create pull request
./tools/macos/git/fix.sh finish
```

### Release Process

```bash
# 1. Start release
./tools/macos/git/release.sh start 1.2.0

# 2. Update version, changelog
git add .
git commit -m "release: Prepare version 1.2.0"

# 3. Create pull requests
./tools/macos/git/release.sh finish
```

### Emergency Hotfix

```bash
# 1. Start hotfix from main
./tools/macos/git/hotfix.sh start ARTLEXIS-789 payment-crash

# 2. Fix critical issue
git add .
git commit -m "hotfix(payment): Fix null pointer in checkout"

# 3. Create pull requests
./tools/macos/git/hotfix.sh finish
```

## 🤝 Team Collaboration

1. **Feature Development**: Always create feature branches from `develop`
2. **Code Review**: Push feature branches and create merge requests
3. **No Direct Commits**: Never commit directly to `main` or `develop`
4. **Clean History**: Use meaningful commit messages with ticket references
5. **Regular Updates**: Pull latest `develop` before starting new work

## 🔍 Troubleshooting

### "Not in a git repository"
Run the script from your project root directory.

### "Invalid branch name format"
Ensure your branch follows the pattern: `type/TICKET-ID-description`

### "Invalid commit message format"
Follow the format: `type(scope): subject` or `type-TICKET-ID: subject`

### Hook not executing
Make sure hooks have execute permission:
```bash
chmod +x .git/hooks/commit-msg
chmod +x .git/hooks/pre-push
```

## 📝 Best Practices

1. **One Feature Per Branch**: Keep features isolated
2. **Small Commits**: Make atomic, focused commits
3. **Descriptive Names**: Use clear branch and commit descriptions
4. **Regular Merges**: Keep branches up to date with develop
5. **Clean Up**: Delete local branches after merging
6. **Tag Releases**: Always tag production releases
7. **Document Changes**: Update README/CHANGELOG for releases

## 🔄 Making This Reusable

To use this GitFlow setup in another project:

1. Copy the entire `tools/macos/git/` directory to your new project
2. Run `./tools/macos/git/setup.sh` from the new project root
3. Adjust `.gitflow.config` if needed (e.g., different ticket prefixes)
4. Commit the GitFlow setup to your new project

The scripts automatically detect the project root and adapt to your project structure. 
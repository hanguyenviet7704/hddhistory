# GitFlow Workflow for Flutter Projects

## Overview
This GitFlow implementation provides a structured branching strategy and automated workflow for Flutter projects. It includes automated commit message validation, branch naming conventions, and helper scripts.

## Branch Structure

### Main Branches
- **main/master**: Production-ready code
- **develop**: Development integration branch

### Supporting Branches
- **feature/**: New features (from develop)
- **release/**: Prepare for production release (from develop)
- **hotfix/**: Emergency fixes (from main)

## Branch Naming Convention

### Format
`<type>/<ticket-id>/<short-description>`

### Examples
- `feature/ARTLEXIS-123/add-user-authentication`
- `release/1.2.0/prepare-release`
- `hotfix/ARTLEXIS-456/fix-login-crash`

## Commit Message Convention

### Format
```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

### Types
- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, missing semicolons, etc.)
- **refactor**: Code refactoring
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **build**: Build system or external dependencies
- **ci**: CI/CD configuration
- **chore**: Other changes that don't modify src or test files

### Examples
```
feat(auth): add biometric authentication support

- Implement fingerprint authentication for iOS and Android
- Add fallback to PIN authentication
- Update security settings UI

ARTLEXIS-123
```

```
fix(gallery): resolve image loading crash on low memory devices

ARTLEXIS-456
```

## Quick Start

### 1. Setup GitFlow
```bash
.\tools\windows\git\setup.bat
```

### 2. Start a Feature
```bash
.\tools\windows\git\feature.bat start ARTLEXIS-123 "add-user-authentication"
```

### 3. Finish a Feature
```bash
.\tools\windows\git\feature.bat finish
```

### 4. Create a Release
```bash
.\tools\windows\git\release.bat start 1.2.0
```

### 5. Publish a Feature Branch
```bash
.\tools\windows\git\feature.bat publish
```

## Workflow Process

### Feature Development
1. Create feature branch from develop
2. Make commits following convention
3. Push changes regularly
4. Create pull request to develop
5. After review, merge to develop

### Release Process
1. Create release branch from develop
2. Update version numbers
3. Fix release-specific bugs
4. Merge to main and develop
5. Tag the release

### Hotfix Process
1. Create hotfix branch from main
2. Fix the critical issue
3. Update version (patch)
4. Merge to main and develop
5. Tag the hotfix

## Git Hooks
The following hooks are automatically installed:
- **commit-msg**: Validates commit message format

## Configuration
Windows setup stores configuration in local git config (`git config gitflow.*`).
If you need custom branch prefixes or branch names, update:
- `.\tools\windows\git\setup.bat`
- Local git config values in your repository

## Troubleshooting

### Hook Permission Issues
```bash
git config core.filemode false
```

### Bypass Hooks (Emergency Only)
```bash
git commit --no-verify
```

### Reset GitFlow
```bash
.\tools\windows\git\setup.bat
```

### Hotfix Workflow on Windows
There is no dedicated `hotfix.bat` script yet. Create and manage hotfix branches manually:
```bash
git checkout main
git pull origin main
git checkout -b hotfix/ARTLEXIS-456-fix-login-crash
```

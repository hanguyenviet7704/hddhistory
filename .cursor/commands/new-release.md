# New Release Workflow Guide

## Overview
This guide provides step-by-step instructions for creating new releases in the Meup Flutter project using GitFlow workflow.

## Prerequisites
- Ensure you're on the correct branch (develop for new releases, or existing release branch)
- Have the latest changes from remote repositories
- Verify version numbers in pubspec.yaml

## Release Workflow

### 1. Check Current Branch
```bash
git branch --show-current
```

### 2. Branch Validation
- **If on develop branch**: Create new release branch
- **If on existing release branch**: Continue with release process
- **If on other branches**: Stop and switch to develop first

### 3. Create New Release Branch (if needed)
```bash
# Check current version in pubspec.yaml
grep "version:" pubspec.yaml

# Create release branch with version from pubspec.yaml
git checkout -b release/$(grep "version:" pubspec.yaml | head -1 | sed 's/.*version: \([0-9.]*\).*/\1/')
```

### 4. Generate Release Notes
```bash
# Get changes from main branch
git diff origin/main..HEAD --name-only

# Get commit history
git log origin/main..HEAD --oneline

# Get detailed statistics
git diff origin/main..HEAD --stat
```

### 5. Create Release Content
- Analyze the changes and categorize them into:
  - 🎉 New Features
  - 🔧 Improvements
  - 🐛 Bug Fixes
  - 📱 Platform Updates
  - 🔄 Dependencies & Tools
- Write comprehensive release notes in `release_content.md`

### 6. Create Git Tag

#### Option A: Simple Tag (Quick)
```bash
# Create simple annotated tag
git tag -a v$(grep "version:" pubspec.yaml | head -1 | sed 's/.*version: \([0-9.]*\).*/\1/') -m "Release v$(grep "version:" pubspec.yaml | head -1 | sed 's/.*version: \([0-9.]*\).*/\1/'): [Brief description]"
```

#### Option B: Detailed Tag (Recommended)
```bash
# Create detailed annotated tag with comprehensive information
git tag -a v$(grep "version:" pubspec.yaml | head -1 | sed 's/.*version: \([0-9.]*\).*/\1/') -m "Release v$(grep "version:" pubspec.yaml | head -1 | sed 's/.*version: \([0-9.]*\).*/\1/')

Version Information:
- Android: v$(grep "version:" pubspec.yaml | grep android | sed 's/.*version: \([0-9.]*+[0-9]*\).*/\1/')
- iOS: v$(grep "version:" pubspec.yaml | grep ios | sed 's/.*version: \([0-9.]*+[0-9]*\).*/\1/')

Changes included:
- [List major features and improvements]
- [List bug fixes and technical enhancements]
- [List UI/UX improvements]

Build and deployment improvements:
- [List build configuration changes]
- [List dependency updates]
- [List development tool improvements]

Release Date: $(date +"%Y-%m-%d")"
```

#### Option C: Manual Detailed Tag (Most Control)
```bash
# Create tag with manual content (use this for complex releases)
git tag -a v1.0.24 -m "Release v1.0.24

Version Information:
- Android: v1.0.24+25
- iOS: v1.0.14+5

Changes included:
- Enhanced user authentication with biometric support
- Improved offline mode functionality
- New dark theme implementation
- Performance optimizations for large datasets

Build and deployment improvements:
- Updated Firebase configuration for production
- Enhanced build scripts with better error handling
- Improved CI/CD pipeline with automated testing
- Updated dependencies to latest stable versions

Release Date: 2025-09-19"
```

### 7. Validate and Manage Tags
```bash
# Check if tag already exists
git tag -l | grep v$(grep "version:" pubspec.yaml | head -1 | sed 's/.*version: \([0-9.]*\).*/\1/')

# View tag content
git show v$(grep "version:" pubspec.yaml | head -1 | sed 's/.*version: \([0-9.]*\).*/\1/')

# Delete tag if needed (local only)
git tag -d v$(grep "version:" pubspec.yaml | head -1 | sed 's/.*version: \([0-9.]*\).*/\1/')

# Delete remote tag if needed
git push origin --delete v$(grep "version:" pubspec.yaml | head -1 | sed 's/.*version: \([0-9.]*\).*/\1/')
```

### 8. Push Changes
```bash
# Push release branch
git push origin release/$(grep "version:" pubspec.yaml | head -1 | sed 's/.*version: \([0-9.]*\).*/\1/')

# Push tags
git push origin --tags

# Verify remote tag
git ls-remote --tags origin | grep v$(grep "version:" pubspec.yaml | head -1 | sed 's/.*version: \([0-9.]*\).*/\1/')
```

## Release Notes Template

### Structure
```markdown
# Release Notes - Meup v[VERSION]

## 🎉 New Features
- [Feature 1]
- [Feature 2]

## 🔧 Improvements
- [Improvement 1]
- [Improvement 2]

## 🐛 Bug Fixes
- [Bug fix 1]
- [Bug fix 2]

## 📱 Platform Updates
### iOS
- [iOS specific changes]

### Android
- [Android specific changes]

## 🔄 Dependencies & Tools
- [Dependency updates]
- [Tool improvements]

## 📊 Statistics
- [X] files changed
- [X] additions, [X] deletions
- Net change: [X] lines

## 🎯 Key Focus Areas
1. [Focus area 1]
2. [Focus area 2]

## 🚀 What's Next
[Brief description of what this release enables]

---
**Release Date**: [DATE]
**Version**: [VERSION]
**Branch**: release/[VERSION]
```

## Common Categories

### New Features
- New functionality added to the app
- New user-facing capabilities
- New integrations or services

### Improvements
- Performance enhancements
- Code refactoring
- UI/UX improvements
- Technical debt reduction

### Bug Fixes
- Resolved user-reported issues
- Fixed crashes or errors
- Corrected incorrect behavior

### Platform Updates
- iOS-specific changes
- Android-specific changes
- Platform compatibility improvements

### Dependencies & Tools
- Package updates
- Build tool improvements
- Development workflow enhancements

## Version Management Best Practices

### Version Numbering
- **Android**: Use format `1.0.XX+YY` where XX is version and YY is build number
- **iOS**: Use format `1.0.XX+YY` where XX is version and YY is build number
- **Increment**: Always increment build number (+YY) for each release
- **Version**: Increment version (1.0.XX) for significant changes

### Version Extraction Commands
```bash
# Get Android version
grep "version:" pubspec.yaml | grep android | sed 's/.*version: \([0-9.]*+[0-9]*\).*/\1/'

# Get iOS version  
grep "version:" pubspec.yaml | grep ios | sed 's/.*version: \([0-9.]*+[0-9]*\).*/\1/'

# Get main version (first uncommented)
grep "version:" pubspec.yaml | head -1 | sed 's/.*version: \([0-9.]*\).*/\1/'
```

### Version Update Workflow
```bash
# 1. Update version in pubspec.yaml
# 2. Commit version change
git add pubspec.yaml
git commit -m "chore: Update version to 1.0.24+25"

# 3. Create release branch
git checkout -b release/1.0.24

# 4. Create tag with new version
git tag -a v1.0.24 -m "Release v1.0.24: [Description]"
```

## Best Practices

1. **Version Consistency**: Always use the version from pubspec.yaml
2. **Comprehensive Notes**: Include all significant changes
3. **User-Focused**: Write from user perspective when possible
4. **Technical Details**: Include technical improvements for developers
5. **Statistics**: Always include file change statistics
6. **Clear Categories**: Use consistent emoji and category structure
7. **Tag Management**: Always validate tags before pushing
8. **Version Tracking**: Keep Android and iOS versions synchronized when possible

## Troubleshooting

### Common Issues
- **Branch not found**: Ensure you're on the correct branch
- **Version mismatch**: Check pubspec.yaml version
- **No changes**: Verify you're comparing against the right base branch
- **Tag conflicts**: Check if tag already exists

### Validation Commands
```bash
# Check current branch
git branch --show-current

# Verify version
grep "version:" pubspec.yaml

# Check for existing tags
git tag -l | grep v[VERSION]

# Validate changes
git diff origin/main..HEAD --name-only
```

## Example Workflow

```bash
# 1. Check current state
git branch --show-current
git status

# 2. Check current version
grep "version:" pubspec.yaml

# 3. Create release branch (if needed)
git checkout -b release/1.0.24

# 4. Generate release notes
git diff origin/main..HEAD --stat > changes.txt
git log origin/main..HEAD --oneline > commits.txt

# 5. Create release content
# [Write release notes in release_content.md]

# 6. Validate tag doesn't exist
git tag -l | grep v1.0.24

# 7. Create detailed tag
git tag -a v1.0.24 -m "Release v1.0.24

Version Information:
- Android: v1.0.24+25
- iOS: v1.0.14+5

Changes included:
- Enhanced user authentication with biometric support
- Improved offline mode functionality
- New dark theme implementation
- Performance optimizations for large datasets

Build and deployment improvements:
- Updated Firebase configuration for production
- Enhanced build scripts with better error handling
- Improved CI/CD pipeline with automated testing
- Updated dependencies to latest stable versions

Release Date: $(date +"%Y-%m-%d")"

# 8. Validate tag content
git show v1.0.24

# 9. Push changes
git push origin release/1.0.24
git push origin --tags

# 10. Verify remote tag
git ls-remote --tags origin | grep v1.0.24
```

## Next Steps After Release

1. **Merge to Main**: Create pull request from release branch to main
2. **Merge to Develop**: Merge release branch back to develop
3. **Deploy**: Deploy the release to app stores
4. **Documentation**: Update any relevant documentation
5. **Cleanup**: Delete the release branch after successful merge

---

**Last Updated**: 2025-09-18  
**Version**: 1.0.23  
**Maintainer**: Development Team  
**Based on**: Release v1.0.23 experience with detailed git tag creation

Description: Create release branch, comprehensive notes, and git tags with automatic change categorization

# New Release

## What This Does
Automates release creation by:
- **Creating release branch** from develop
- **Analyzing all changes** since last release
- **Categorizing changes** (features, improvements, fixes)
- **Generating release notes** with statistics
- **Creating git tag** with detailed message
- **Pushing to remote** automatically

**Fully automated** change analysis and categorization.

## When to Use
- Creating new release from develop branch
- Updating existing release branch
- Need comprehensive release notes generated
- Time to tag and document a release

## Required Context
**Automatically detected:**
- Current branch (develop or release/*)
- Version from pubspec.yaml
- Git history since last release

**User confirms:**
- Version number from pubspec.yaml

## Command Flow

### 1. Ask Questions
Uses `AskUserQuestion` to gather:
```
1. Current status:
   - On develop (create new release)
   - On release branch (update existing)

2. Version confirmation:
   [Auto-detected from pubspec.yaml]
   Confirm version X.Y.Z?
```

### 2. Verify Current State
Executes bash commands in parallel:
```bash
git branch --show-current                    # Current branch
grep "version:" pubspec.yaml | head -1       # Version number
git status                                   # Clean state check
git tag -l                                   # Existing tags
```

Validation checks:
- ✅ On correct branch (develop or release/*)
- ✅ Clean working directory
- ✅ Version in pubspec.yaml is valid
- ✅ Tag doesn't already exist

### 3. Create Release Branch
If on develop:
```bash
VERSION=$(grep "version:" pubspec.yaml | head -1 | sed 's/.*version: \([0-9.]*\).*/\1/')
git checkout -b release/$VERSION
```

### 4. Analyze Changes Since Last Release
Spawns **Task agent (Plan)** to analyze:
```
Task: "Analyze all changes from main branch to current HEAD.
      Categorize commits by type: features, improvements, fixes.
      Summarize by architecture layer and impact.
      Identify breaking changes and migrations needed."
```

Executes git commands:
```bash
git diff origin/main..HEAD --stat            # Statistics
git diff origin/main..HEAD --name-only       # File list
git log origin/main..HEAD --oneline          # Commit list
git log origin/main..HEAD --pretty=format:"%s"  # Messages only
```

Example output:
```
Since last release (v1.0.24):
- 47 commits
- 89 files changed
- +2,341 additions, -876 deletions
```

### 5. Categorize Changes
Uses `TodoWrite` to track:
```
☐ Extract commits and categorize
☐ Analyze file changes by layer
☐ Generate feature summaries
☐ Generate improvement summaries
☐ Generate bug fix summaries
☐ Create statistics
☐ Write release notes
☐ Create git tag
☐ Push to remote
```

**Auto-categorize commits:**
```
🎉 New Features (feat, feature, add):
- feat-MEUP-123: User notification system
- add-MEUP-145: Payment integration

🔧 Improvements (improve, enhance, update, refactor):
- improve-MEUP-156: Optimize image loading
- refactor-MEUP-167: Clean up lesson flow

🐛 Bug Fixes (fix, bug, hotfix):
- fix-MEUP-178: Crash on lesson completion
- hotfix-MEUP-189: Login state persistence

📱 Platform Updates (android/, ios/ changes):
- Update Android target SDK to 34
- iOS minimum deployment target to 13.0

🔄 Dependencies (pubspec.yaml changes):
- Updated flutter_bloc to 8.1.0
- Added push_notifications package
```

**Auto-categorize files:**
```
Source Code: lib/src/**
Configuration: lib/config/**, .env/**
Assets: assets/**
Build: tools/**, .github/**
Tests: test/**
Docs: docs/**, *.md
```

### 6. Generate Release Notes
Creates comprehensive release notes:

```markdown
# Release Notes - Meup v[VERSION]

## 🎉 New Features
- **User Notifications**: Implemented push notification system with in-app notification center
  - Real-time notifications via Firebase Cloud Messaging
  - Notification preferences and management
  - Mark as read/unread functionality

- **Payment Integration**: Added payment processing with multiple providers
  - Stripe integration for card payments
  - PayPal support
  - Payment history tracking

[Auto-generated from feature commits and file analysis]

## 🔧 Improvements
- **Performance**: Optimized image loading with enhanced caching (40% faster)
- **UI/UX**: Refreshed lesson interface with new animations
- **Code Quality**: Refactored authentication flow for better maintainability

[Auto-generated from improvement commits]

## 🐛 Bug Fixes
- Fixed crash occurring when completing lessons
- Resolved login state persistence issue
- Fixed profile image upload on iOS

[Auto-generated from fix commits]

## 📱 Platform Updates

### iOS (v1.0.25+26)
- Updated minimum deployment target to iOS 13.0
- Fixed background task handling
- Improved push notification reliability

### Android (v1.0.25+26)
- Updated target SDK to 34
- Enhanced permission handling
- Fixed notification icon rendering

## 🔄 Dependencies & Tools
Updated:
- flutter_bloc: 8.0.1 → 8.1.0
- cached_network_image: 3.2.0 → 3.3.0

Added:
- push_notifications: ^1.0.0
- payment_sdk: ^2.1.0

Build Tools:
- Updated build scripts for better error handling
- Enhanced CI/CD pipeline with parallel testing

## 📊 Statistics
- **Files changed**: 89
- **Lines added**: +2,341
- **Lines deleted**: -876
- **Net change**: +1,465 lines
- **Commits**: 47

## 🎯 Key Focus Areas
1. **Notification System** - Complete push notification integration
2. **Payment Processing** - Multi-provider payment support
3. **Performance** - Significant image loading improvements
4. **Platform Updates** - iOS 13+ and Android SDK 34 support

## 🚀 What's Next
This release enables real-time user engagement through push notifications and seamless payment processing, setting the foundation for premium features and enhanced user experience.

---
**Release Date**: [Today's date]
**Version**: [VERSION]
**Branch**: release/[VERSION]
**Platform Versions**:
- Android: v1.0.25+26
- iOS: v1.0.25+26
```

### 7. Generate Git Tag Content
Creates detailed tag message:
```
Release v1.0.25

Version Information:
- Android: v1.0.25+26
- iOS: v1.0.25+26

Changes included:
- User notification system with push notifications
- Payment integration (Stripe + PayPal)
- Image loading performance improvements
- iOS 13+ and Android SDK 34 support
- 47 commits, 89 files changed

Release Date: 2025-01-29
```

### 8. Validate Tag Doesn't Exist
```bash
git tag -l | grep "v$VERSION"
```

If exists, asks user:
- Delete and recreate
- Increment build number
- Cancel operation

### 9. Create Release Assets
Saves files:
- `release_content.md` - Full release notes
- `release_tag.txt` - Tag message

### 10. Create Git Tag
```bash
git tag -a "v$VERSION" -m "$TAG_MESSAGE"
git show "v$VERSION"  # Verify
```

### 11. Push to Remote
```bash
git push origin release/$VERSION
git push origin v$VERSION
git ls-remote --tags origin | grep "v$VERSION"  # Verify
```

## Output Format

```
✅ Release v1.0.25 Created

📦 Release Information
Branch: release/1.0.25
Tag: v1.0.25

📱 Platform Versions
- Android: v1.0.25+26
- iOS: v1.0.25+26

📊 Changes Summary
- 🎉 5 new features
- 🔧 12 improvements
- 🐛 4 bug fixes
- 📱 3 platform updates
- 🔄 6 dependency updates

📈 Statistics
- 47 commits since last release (v1.0.24)
- 89 files changed
- +2,341/-876 lines changed
- Net: +1,465 lines

📁 Files Created
✓ release_content.md (Full release notes)
✓ release_tag.txt (Tag message)

🌐 Remote Status
✓ Branch pushed to origin/release/1.0.25
✓ Tag pushed to origin/v1.0.25

🎯 Next Steps
1. Review release_content.md for accuracy
2. Create PR: release/1.0.25 → main
3. After merge to main, build for app stores:
   - Android: ./tools/macos/build/build_appbundle.sh prod
   - iOS: ./tools/macos/build/build_ipa.sh prod
4. Deploy to stores (see /deploy-app docs)
5. Merge release/1.0.25 back to develop
```

## Example Usage

### Example 1: New Release from Develop
```
User: /new-release

Claude: Questions:
        1. Current status? → On develop ✓
        2. Version 1.0.25 from pubspec.yaml - Confirm? → Yes

        [Creates release/1.0.25 branch]
        [Analyzes 47 commits since v1.0.24]
        [Categorizes changes]
        [Generates comprehensive notes]
        [Creates git tag]
        [Pushes to remote]

        ✅ Release v1.0.25 Created
        - 5 features, 12 improvements, 4 fixes
        - Files: release_content.md ready
        - Remote: branch and tag pushed
```

### Example 2: Update Existing Release
```
User: /new-release

Claude: Questions:
        1. Current status? → On release/1.0.25
        2. Update release notes? → Yes

        [Analyzes latest changes]
        [Updates release_content.md]
        [Recreates tag if needed]

        ✅ Release v1.0.25 Updated
        - Release notes refreshed
        - Tag updated
```

## Smart Change Descriptions

Auto-generates descriptions from commits and files:

```
Commit: "feat-MEUP-123: Add push notification system"
Files: lib/src/notifications/**
→ "Implemented push notification system with in-app notification center"

Commit: "fix-MEUP-456: Resolve crash on lesson completion"
Files: lib/src/lesson/presentation/cubits/lesson_cubit.dart
→ "Fixed crash occurring when completing lessons"

Commit: "improve-MEUP-789: Optimize image loading"
Files: lib/core/utils/image_cache.dart, lib/src/*/widgets/*
→ "Optimized image loading performance (40% improvement)"
```

## Validation Checks

### Pre-Release
- [ ] Version in pubspec.yaml is valid
- [ ] Build number incremented
- [ ] No uncommitted changes
- [ ] On correct branch

### Post-Release
- [ ] Tag created successfully
- [ ] Branch pushed to remote
- [ ] Tag pushed to remote
- [ ] Release notes generated
- [ ] No conflicts with existing tags

## Edge Cases Handled

### Tag Already Exists
Options presented:
1. Delete local and remote tag, recreate
2. Increment build number, use new version
3. Cancel operation

### Wrong Branch
If not on develop or release/*:
- Detects current branch
- Warns user
- Asks to switch to correct branch

### Uncommitted Changes
If dirty working directory:
- Shows uncommitted changes
- Asks to commit or stash
- Won't proceed until clean

### Version Not Incremented
If version/build not bumped:
- Detects last tag
- Compares with pubspec.yaml
- Warns and suggests correct version

---

*See CLAUDE.md: Release Process for detailed release workflows*
*See CLAUDE.md: Versioning for version numbering conventions*

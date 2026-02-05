---
trigger: model_decision
description: Workflow for /new-release (New Release)
---

# New Release

## Invocation
Use only when the user explicitly requests `/new-release` or asks to run this workflow.
Ask the listed questions first, then execute the steps.

## Usage
Run from develop branch (for new release) or existing release branch (to update)

## Agent Questions (Ask First)
1. **Current status**: On develop (create new release) | On release branch (update existing)
2. **Version confirmed**: [Auto-detect from pubspec.yaml, ask for confirmation]

## Auto-Execute After Questions

### 1. Verify Current State
```bash
git branch --show-current                    # Verify branch
grep "version:" pubspec.yaml | head -1       # Get version
git status                                   # Check clean state
```

### 2. Create Release Branch (if on develop)
```bash
# Extract version from pubspec.yaml
VERSION=$(grep "version:" pubspec.yaml | head -1 | sed 's/.*version: \([0-9.]*\).*/\1/')

# Create and switch to release branch
git checkout -b release/$VERSION
```

### 3. Analyze Changes Since Last Release
```bash
# Get changes from main (last release)
git diff origin/main..HEAD --stat
git diff origin/main..HEAD --name-only
git log origin/main..HEAD --oneline
git log origin/main..HEAD --pretty=format:"%s"
```

### 4. Categorize Changes
**Auto-categorize commits by type:**
- 🎉 **New Features**: Commits with `feature/`
- 🔧 **Improvements**: Commits with `perf/`, `refactor/`, `style/`, `chore/`, `docs/`
- 🐛 **Bug Fixes**: Commits with `fix/`
- 📱 **Platform Updates**: iOS/Android specific changes
- 🔄 **Dependencies**: Changes to pubspec.yaml, packages
- 🛠️ **Build/Tools**: Build scripts, CI/CD, tools updates

**Auto-categorize files:**
- **Source Code**: lib/src/**
- **Configuration**: lib/config/**, .env/**, flavorizr.yaml
- **Assets**: assets/**
- **Build Scripts**: tools/**, .github/**
- **Tests**: test/**
- **Documentation**: docs/**, *.md files

### 5. Generate Release Notes
```markdown
# Release Notes - Meup v[VERSION]

## 🎉 New Features
[Auto-list from commits and changed files]
- Feature 1: [Description from commit]
- Feature 2: [Description from commit]

## 🔧 Improvements
[Auto-list improvements]
- Improvement 1: [Description]
- Improvement 2: [Description]

## 🐛 Bug Fixes
[Auto-list bug fixes]
- Fixed: [Issue description]
- Fixed: [Issue description]

## 📱 Platform Updates

### iOS
- Version: [from pubspec.yaml]
- Changes: [iOS specific updates]

### Android
- Version: [from pubspec.yaml]
- Changes: [Android specific updates]

## 🔄 Dependencies & Tools
[Auto-detect from pubspec.yaml changes]
- Updated: [package] to v[version]
- Added: [new_package] v[version]
- Build tools: [changes]

## 📊 Statistics
- **Files changed**: X
- **Lines added**: +X
- **Lines deleted**: -X
- **Net change**: X lines
- **Commits**: X

## 🎯 Key Focus Areas
[Auto-generate based on change volume]
1. [Area with most changes]
2. [Critical functionality updates]
3. [New capabilities]

## 🚀 What's Next
[Brief summary of what this release enables]

---
**Release Date**: [Today's date]
**Version**: [VERSION]
**Branch**: release/[VERSION]
**Platform Versions**:
- Android: [version+build]
- iOS: [version+build]
```

### 6. Generate Git Tag Content
```bash
# Create comprehensive tag message
TAG_MESSAGE="Release v$VERSION

Version Information:
- Android: $(grep "version:" pubspec.yaml | head -1 | sed 's/.*version: \([0-9.]*+[0-9]*\).*/\1/')
- iOS: $(grep "version:" pubspec.yaml | head -1 | sed 's/.*version: \([0-9.]*+[0-9]*\).*/\1/')

Changes included:
[Top 5-10 most important changes]

Release Date: $(date +"%Y-%m-%d")"
```

### 7. Validate Tag Doesn't Exist
```bash
# Check if tag already exists
git tag -l | grep "v$VERSION"

# If exists, ask user:
# - Delete and recreate
# - Use different version
# - Cancel
```

### 8. Create Release Assets
**Save to files:**
- `release_content.md` - Full release notes
- `release_tag.txt` - Tag message content

### 9. Create Git Tag
```bash
# Create annotated tag with detailed message
git tag -a "v$VERSION" -m "$TAG_MESSAGE"

# Verify tag created
git show "v$VERSION"
```

### 10. Push Release
```bash
# Push release branch
git push origin release/$VERSION

# Push tag
git push origin v$VERSION

# Verify remote tag
git ls-remote --tags origin | grep "v$VERSION"
```

## Output
```
✅ Release v[VERSION] Created

Branch: release/[VERSION]
Tag: v[VERSION]

Version Information:
- Android: v[VERSION]+[BUILD]
- iOS: v[VERSION]+[BUILD]

Changes Summary:
- 🎉 X new features
- 🔧 X improvements
- 🐛 X bug fixes
- 📱 X platform updates
- 🔄 X dependency updates

Statistics:
- X commits since last release
- X files changed
- +X/-X lines changed

Files Created:
- release_content.md (Full release notes)
- release_tag.txt (Tag message)

Remote Status:
- ✅ Branch pushed to origin
- ✅ Tag pushed to origin

Next Steps:
1. Review release_content.md
2. Create PR from release/[VERSION] to main
3. After merge, tag main with release tag
4. Build and deploy to app stores
5. Merge release/[VERSION] back to develop
```

## Release Notes Generation Rules

### Feature Detection
**Identify as feature if:**
- Commit message starts with `feature/`
- New files in `lib/src/*/domain/` or `lib/src/*/presentation/pages/`
- Significant new functionality

### Improvement Detection
**Identify as improvement if:**
- Commit message starts with `perf/`, `refactor/`, `style/`, `chore/`, `docs/`
- Performance optimizations
- Code quality improvements
- UI/UX enhancements

### Bug Fix Detection
**Identify as bug fix if:**
- Commit message starts with `fix/`
- Fixes regressions or issues

### Platform Update Detection
**Identify as platform update if:**
- Changes in `android/` or `ios/` directories
- Platform-specific configurations
- Native code modifications

### Dependency Update Detection
**Check:**
- `pubspec.yaml` changes
- Version bumps in dependencies
- New dependencies added

## Smart Change Descriptions

### Auto-generate descriptions from:
1. **Commit messages** - Use commit message as base
2. **File changes** - Infer purpose from files modified
3. **Code diffs** - Analyze key changes in code

### Example transformations:
```
Commit: "feature/MEUP-123: add user profile settings"
Files: lib/src/profile/presentation/pages/settings/
→ Release note: "Added user profile settings page with customization options"

Commit: "fix/MEUP-456: resolve crash on lesson completion"
Files: lib/src/lesson/presentation/cubits/lesson_cubit.dart
→ Release note: "Fixed crash occurring when completing lessons"

Commit: "perf/MEUP-789: optimize image loading performance"
Files: lib/core/utils/image_cache.dart
→ Release note: "Improved image loading performance with enhanced caching"
```

## Version Format Rules

### Version in pubspec.yaml
```yaml
version: 1.0.24+25
# 1.0.24 = version name (X.Y.Z)
# 25 = build number
```

### Git Tag Format
```
v1.0.24
```

### Release Branch Format
```
release/1.0.24
```

## Validation Checks

### Pre-Release Validation
- [ ] Version in pubspec.yaml is valid
- [ ] Build number is incremented
- [ ] No uncommitted changes
- [ ] All tests pass (optional, can run separately)
- [ ] Code generation is up to date

### Post-Release Validation
- [ ] Tag created successfully
- [ ] Branch pushed to remote
- [ ] Tag pushed to remote
- [ ] Release notes generated
- [ ] No conflicts with existing tags

## Edge Cases Handling

### If Tag Already Exists
**Options:**
1. Delete local and remote tag, recreate
2. Increment build number and use new version
3. Cancel operation

### If on Wrong Branch
**Actions:**
1. Detect current branch
2. If not develop or release/*, warn user
3. Ask to switch to correct branch

### If Uncommitted Changes
**Actions:**
1. Show uncommitted changes
2. Ask user to commit or stash
3. Don't proceed until clean

### If Version Not Incremented
**Actions:**
1. Detect last tag
2. Compare with pubspec.yaml version
3. Warn if version/build not incremented
4. Suggest correct version

## Release Checklist Integration

### Before Creating Release
- [ ] All PRs merged to develop
- [ ] Tests passing
- [ ] Code analysis clean
- [ ] Documentation updated

### After Creating Release
- [ ] Create PR to main
- [ ] Build app for all flavors
- [ ] Test on devices
- [ ] Prepare store listings
- [ ] Create store release

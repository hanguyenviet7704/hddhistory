---
trigger: model_decision
description: Workflow for /new-pull-request-to-develop (New Pull Request to Develop)
---

# New Pull Request to Develop

## Invocation
Use only when the user explicitly requests `/new-pull-request-to-develop` or asks to run this workflow.
Ask the listed questions first, then execute the steps.

## Usage
Run from your feature branch when ready to create PR

## Agent Questions (Ask First)
1. **Target branch**: develop (default) | main | other
2. **Include screenshots**: Yes | No (only if UI changes)

## Auto-Execute After Questions

### 1. Get Git Information
```bash
git branch --show-current              # Current branch name
git diff [target]..HEAD --stat         # Change statistics
git diff [target]..HEAD --name-only    # Changed files list
git log [target]..HEAD --oneline       # Commit history
```

### 2. Extract Ticket ID
**From branch name pattern:**
- `feature/TICKET-123/description` → TICKET-123
- `feature/TICKET-123-description` → TICKET-123
- `feature/description` → Ask user for ticket ID

### 3. Analyze Changes
**Auto-categorize files:**
- **Domain**: `lib/src/<feature>/domain/**`
- **Data**: `lib/src/<feature>/data/**`
- **Presentation**: `lib/src/<feature>/presentation/**`
- **Config**: `lib/config/**`
- **Assets**: `assets/**`
- **Tests**: `test/**`
- **Build**: Build scripts, CI/CD files
- **Docs**: Documentation files

**Count changes:**
- Files changed
- Lines added/deleted
- Net change

### 4. Analyze Commits
**Extract from commit messages:**
- Feature additions (`feature/` commits)
- Bug fixes (`fix/` commits)
- Refactoring (`refactor/` commits)
- Tests (`test/` commits)
- Documentation (`docs/` commits)

### 5. Generate PR Content

**Title format:**
```
feature/TICKET-ID: [Brief description from commits]
```

**Content structure:**
```markdown
## Summary
[Auto-generated high-level overview based on commits and changes]

## Ticket
- Ticket ID: TICKET-XXX
- Branch: feature/TICKET-XXX/description

## Changes Overview

### Statistics
- **Files changed**: X
- **Lines added**: +X
- **Lines deleted**: -X
- **Net change**: X lines

### Commits
[List of commits with messages]

### Key Changes

#### Domain Layer
[List domain files changed with brief description]

#### Data Layer
[List data files changed with brief description]

#### Presentation Layer
[List presentation files changed with brief description]

#### Configuration
[List config changes]

#### Tests
[List test files added/updated]

### Files Changed by Category

<details>
<summary>Domain (X files)</summary>

- path/to/file1.dart
- path/to/file2.dart
</details>

<details>
<summary>Data (X files)</summary>

- path/to/file1.dart
- path/to/file2.dart
</details>

[... other categories ...]

## Testing Checklist
- [ ] Unit tests pass
- [ ] Widget tests pass (if UI changes)
- [ ] Manual testing completed
- [ ] All flavors tested (dev, stg, prod)
- [ ] No regression issues

## Code Quality
- [ ] `flutter analyze` passes
- [ ] Code follows Clean Architecture
- [ ] Proper error handling implemented
- [ ] Localization keys added (if needed)
- [ ] Code generation completed

## Review Focus
[Auto-generated based on change types]
- Focus on [specific areas with most changes]
- Verify [data flow/state management/UI implementation]
- Check [error handling/edge cases]

## Deployment Notes
[Auto-generated if needed]
- Requires code generation: [Yes/No]
- New dependencies added: [List if any]
- Breaking changes: [None/List if any]
- Migration required: [No/Yes with details]

## Screenshots
[If UI changes and user selected Yes]
[Placeholder for user to add screenshots]


```

### 6. Save PR Content
```bash
# Save to pr_content.md for easy copying
```

### 7. Optional: Create PR Directly (if gh CLI available)
```bash
gh pr create --title "[title]" --body "[content]" --base [target]
```

## Output
```
✅ PR Content Generated

Title:
feature/TICKET-123: implement user profile management

Target Branch: develop
Source Branch: feature/TICKET-123/user-profile

Statistics:
- 23 files changed
- +847 additions
- -123 deletions

Changes:
- 8 domain files (entities, use cases)
- 7 data files (models, repositories)
- 6 presentation files (cubits, widgets)
- 2 test files

PR content saved to: pr_content.md

Next Steps:
1. Review pr_content.md
2. Add screenshots if needed
3. Copy content to GitHub/GitLab PR
   OR
   Run: gh pr create (if gh CLI installed)
```

## PR Content Template (Auto-Applied)

### For Feature Implementation
```markdown
## Summary
Implemented [feature_name] feature with complete Clean Architecture layers including domain entities, data models, repository implementations, and state management.

## Key Highlights
- ✅ Domain layer with [X] entities and [X] use cases
- ✅ Data layer with [API/GraphQL] integration
- ✅ [BLoC/Cubit] state management
- ✅ Error handling with AppException
- ✅ Test coverage for critical paths
```

### For UI Update
```markdown
## Summary
Updated UI for [feature/page] based on latest Figma designs, implementing responsive layouts and new design tokens.

## Key Highlights
- ✅ Implemented Figma design: [URL]
- ✅ Responsive design with ScreenUtil
- ✅ New design tokens added to theme
- ✅ Maintains existing functionality
```

### For Bug Fix
```markdown
## Summary
Fixed [issue_description] affecting [component/feature].

## Key Highlights
- 🐛 Fixed: [specific issue]
- ✅ Root cause: [explanation]
- ✅ Solution: [approach taken]
- ✅ Added tests to prevent regression
```

### For Refactoring
```markdown
## Summary
Refactored [component/layer] to improve [code quality/performance/maintainability].

## Key Highlights
- ♻️ Refactored: [what was changed]
- ✅ Improved: [specific improvements]
- ✅ No functional changes
- ✅ All tests still passing
```

## Smart Detection Rules

### Detect Breaking Changes
**Auto-flag if:**
- Public API method signatures changed
- Model field removed/renamed
- Repository interface changed
- Navigation routes modified

### Detect New Dependencies
**Check:**
- pubspec.yaml modifications
- New imports from external packages

### Detect Migration Needs
**Flag if:**
- Database schema changed
- Local storage structure modified
- API contract breaking changes

### Suggest Review Focus
**Based on change volume:**
- High churn files (>100 lines changed)
- New files requiring architecture review
- Critical paths (auth, payment, data sync)

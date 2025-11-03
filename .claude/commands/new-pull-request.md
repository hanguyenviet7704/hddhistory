Description: Generate comprehensive PR content by analyzing git changes with smart categorization

# New Pull Request

## What This Does
Generates complete PR content by:
- **Analyzing all git changes** (commits, files, diffs)
- **Extracting ticket ID** from branch name
- **Categorizing changes** by architecture layer and type
- **Detecting breaking changes** and new dependencies
- **Creating structured PR description** with checklists
- **Smart change summarization** based on commit patterns

**Fully autonomous** - No manual content writing needed.

## When to Use
- Ready to create PR from feature branch to develop/main
- Need comprehensive PR description generated
- Want changes categorized by Clean Architecture layers
- Need to communicate impact of changes clearly

## Required Context
**Automatically gathered:**
- Current branch (feature branch)
- Git diff vs target branch
- Commit history
- File changes

**User only needs:**
- To be on the correct feature branch
- Clean git state (no uncommitted changes)

## Command Flow

### 1. Ask Questions
Uses `AskUserQuestion` to gather:
```
1. Target branch:
   - develop (default)
   - main
   - other

2. Include screenshots:
   - Yes (for UI changes)
   - No (no UI changes)
```

### 2. Gather Git Information
Executes bash commands in parallel:
```bash
git branch --show-current              # Current branch
git diff [target]..HEAD --stat         # Change statistics
git diff [target]..HEAD --name-only    # File list
git log [target]..HEAD --oneline       # Commit history
git log [target]..HEAD --pretty=format:"%s"  # Commit messages
```

Example output:
```
Branch: feature/MEUP-123/user-notifications
Stats: 23 files changed, +847 additions, -123 deletions
Commits: 15 commits since develop
```

### 3. Extract Ticket ID
From branch name patterns:
- `feature/TICKET-123/TICKET-123/description` → TICKET-123
- `feature/TICKET-123/description` → TICKET-123
- `feature/TICKET-123-description` → TICKET-123
- `feature/description` → Ask user for ticket ID

### 4. Categorize Changes
Spawns **Task agent (Plan)** to analyze:
```
Task: "Analyze git changes and categorize by:
      - Architecture layer (Domain, Data, Presentation, Config)
      - Change type (feature, bugfix, refactor, test)
      - Impact level (high, medium, low)
      Return structured categorization"
```

Auto-categorize files by path:
```
lib/src/domain/** → Domain Layer
lib/src/data/** → Data Layer
lib/src/presentation/** → Presentation Layer
lib/config/** → Configuration
assets/** → Assets
test/** → Tests
tools/** → Build Tools
*.md → Documentation
```

Auto-categorize commits by type:
```
feat|feature|add → New Features
fix|bug|hotfix → Bug Fixes
improve|enhance|update|refactor → Improvements
test → Tests
docs → Documentation
build|ci|tool → Build/Tools
```

### 5. Detect Breaking Changes
Checks for:
- ✅ Repository interface method signature changes
- ✅ Model field removed/renamed
- ✅ Public API changes
- ✅ Route path modifications
- ✅ Database schema changes

Example detection:
```
⚠️ Breaking Change Detected:
- I UserRepository.getUser() signature changed
- UserModel.email field renamed to emailAddress
→ Requires migration in dependent features
```

### 6. Detect New Dependencies
Checks `pubspec.yaml` diff:
```yaml
+ dependencies:
+   push_notifications: ^1.0.0
+   permission_handler: ^10.0.0

⚠️ New Dependencies Added:
- push_notifications v1.0.0
- permission_handler v10.0.0
```

### 7. Analyze Change Impact
Uses `TodoWrite` to track analysis:
```
☐ Extract commit messages
☐ Categorize files by layer
☐ Detect breaking changes
☐ Check dependencies
☐ Generate summaries
☐ Create PR structure
```

Generates impact assessment:
```
Impact Analysis:
- 🎯 High Impact: Domain layer changes (3 entities, 2 repositories)
- 🔧 Medium Impact: New API integration (notification service)
- ✅ Low Impact: UI updates (presentation layer only)

Review Focus:
1. UserRepository interface changes (breaking)
2. New notification service integration
3. State management for notification flow
```

### 8. Generate PR Content
Creates structured PR description:

```markdown
## Summary
[Auto-generated from commits and changes]

## Ticket
- **Ticket ID**: MEUP-123
- **Branch**: feature/MEUP-123/user-notifications
- **Target**: develop

## Changes Overview

### Statistics
- **Files changed**: 23
- **Lines added**: +847
- **Lines deleted**: -123
- **Net change**: +724 lines
- **Commits**: 15

### Commits
[Chronological list with sha and message]

### Key Changes

#### 🏗️ Domain Layer (5 files)
- Added `UserNotificationEntity` with notification types
- Created `INotificationRepository` interface
- Implemented 3 use cases:
  - `GetNotificationsUseCase`
  - `MarkAsReadUseCase`
  - `DeleteNotificationUseCase`

#### 📦 Data Layer (7 files)
- Added `NotificationModel` with JSON serialization
- Implemented `NotificationRepository` with REST API
- Created `NotificationApi` client with Retrofit
- Added notification caching with local storage

#### 🎨 Presentation Layer (6 files)
- Created `NotificationsCubit` with 4 states
- Implemented `NotificationsPage` with pull-to-refresh
- Added `NotificationCard` widget
- Integrated with navigation stack

#### ⚙️ Configuration (2 files)
- Updated DI registration
- Added notification routes

#### 🧪 Tests (3 files)
- Added use case tests
- Added repository tests
- Added cubit tests

### Files Changed by Category

<details>
<summary>Domain Layer (5 files)</summary>

- lib/src/domain/entities/notification_entity.dart
- lib/src/domain/repositories/i_notification_repository.dart
- lib/src/domain/usecases/notifications/get_notifications_usecase.dart
- lib/src/domain/usecases/notifications/mark_as_read_usecase.dart
- lib/src/domain/usecases/notifications/delete_notification_usecase.dart
</details>

<details>
<summary>Data Layer (7 files)</summary>

- lib/src/data/models/notification_model.dart
- lib/src/data/repositories/notification_repository.dart
- lib/src/data/datasources/apis/notification_api.dart
- [... other files]
</details>

[... other categories ...]

## Testing Checklist
- [ ] Unit tests pass (`flutter test`)
- [ ] Widget tests pass (if UI changes)
- [ ] Manual testing completed on dev environment
- [ ] Tested on iOS devices/simulators
- [ ] Tested on Android devices/emulators
- [ ] All flavors tested (dev, stg, prod)
- [ ] No regression in existing features

## Code Quality
- [ ] `flutter analyze` passes with no errors
- [ ] Code follows Clean Architecture principles
- [ ] Proper error handling with AppException
- [ ] Localization keys added for user-facing text
- [ ] Code generation completed successfully
- [ ] No hardcoded values or magic numbers

## Review Focus
Based on change analysis, reviewers should focus on:
1. **Domain Layer Changes** - Interface contracts and business logic
2. **Repository Implementation** - API integration and error handling
3. **State Management** - Cubit logic and state transitions
4. **UI Implementation** - User experience and responsive design

## Deployment Notes

### Code Generation
- ✅ Requires `dart run build_runner build --delete-conflicting-outputs`
- Generates: Freezed models, JSON serialization, DI config

### New Dependencies
⚠️ Added:
- `push_notifications` ^1.0.0
- `permission_handler` ^10.0.0

Run `flutter pub get` after merging.

### Breaking Changes
⚠️ None

### Migration Required
✅ No migration needed

### Configuration Changes
- Updated DI registration for new repositories
- Added routes for notification screens
- No environment variable changes

## Screenshots
[Placeholder if user selected Yes]

---

Generated by Claude Code
```

### 9. Save PR Content
Saves to `pr_content.md` in project root for easy copying.

### 10. Optional: Create PR Directly
If `gh` CLI available:
```bash
gh pr create \
  --title "feature-MEUP-123: Implement user notifications" \
  --body "$(cat pr_content.md)" \
  --base develop
```

## Output Format

```
✅ PR Content Generated

📋 Pull Request Details
Title: feature-MEUP-123: Implement user notifications
Target: develop ← feature/MEUP-123/user-notifications

📊 Change Statistics
- 23 files changed
- +847 additions, -123 deletions
- 15 commits

🏗️ Changes by Layer
- Domain: 5 files (entities, repos, use cases)
- Data: 7 files (models, repos, APIs)
- Presentation: 6 files (cubits, pages, widgets)
- Config: 2 files (DI, routes)
- Tests: 3 files

⚠️ Important Notices
- New dependencies: 2 packages added
- Breaking changes: None detected
- Migration required: No

📁 File Created
pr_content.md - Ready to copy to GitHub/GitLab

🎯 Next Steps
1. Review pr_content.md
2. Add screenshots if UI changes (marked with [Placeholder])
3. Copy content to GitHub/GitLab PR
   OR
   Run: gh pr create (if gh CLI installed)

💡 Quick Actions
- View: cat pr_content.md
- Copy: pbcopy < pr_content.md (macOS)
- Create PR: gh pr create --fill
```

## Example Usage

### Example 1: Feature PR
```
User: /new-pull-request

Claude: Questions:
        1. Target branch? → develop
        2. Include screenshots? → Yes (UI changes)

        [Analyzes git changes]
        [Categorizes by layer and type]
        [Detects 2 new dependencies]
        [Generates comprehensive PR content]

        ✅ PR Content Generated
        - Title: feature-MEUP-123: Implement user notifications
        - 23 files, 15 commits
        - Saved to pr_content.md
        - Screenshot placeholders added
```

### Example 2: Bugfix PR
```
User: /new-pull-request

Claude: Questions:
        1. Target branch? → main (hotfix)
        2. Include screenshots? → No

        [Analyzes changes]
        [Detects bug fix pattern]
        [Generates focused PR]

        ✅ PR Content Generated
        - Title: fix-MEUP-456: Resolve crash on lesson completion
        - 3 files, 2 commits
        - Focus: Bug fix in LessonCubit
```

## PR Content Templates

### Feature Implementation
```markdown
## Summary
Implemented [feature_name] feature with complete Clean Architecture layers including domain entities, data models, repository implementations, and presentation layer with state management.

## Key Highlights
- ✅ Domain layer with X entities and X use cases
- ✅ Data layer with [REST/GraphQL] integration
- ✅ State management with [Feature]Cubit
- ✅ Error handling with AppException
- ✅ Test coverage for critical paths
```

### Bug Fix
```markdown
## Summary
Fixed [issue_description] affecting [component/feature].

## Key Highlights
- 🐛 Fixed: [specific issue]
- ✅ Root cause: [explanation]
- ✅ Solution: [approach taken]
- ✅ Added tests to prevent regression
```

### UI Update
```markdown
## Summary
Updated UI for [feature/page] based on latest Figma designs, implementing responsive layouts and new design tokens.

## Key Highlights
- ✅ Implemented Figma design: [URL]
- ✅ Responsive design with ScreenUtil
- ✅ New design tokens added to theme
- ✅ Maintains existing functionality
```

## Smart Detection Features

### Detects Breaking Changes
Auto-flags if:
- Repository method signatures changed
- Model fields removed/renamed
- Public API contracts modified
- Route paths changed

### Detects Dependencies
Checks:
- `pubspec.yaml` modifications
- New package imports
- Version bumps

### Detects Migration Needs
Flags if:
- Database schema changes
- Local storage structure modified
- API contract breaking changes

### Suggests Review Focus
Based on:
- High churn files (>100 lines changed)
- New files requiring architecture review
- Critical paths (auth, payment, data sync)
- Complexity metrics

---

*See CLAUDE.md: Git Workflow for commit message conventions*
*See CLAUDE.md: Pull Request Guidelines for review processes*

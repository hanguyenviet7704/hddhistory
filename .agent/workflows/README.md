---
trigger: model_decision
description: Antigravity workflow catalog for migrated Cursor commands
---

# Cursor Commands for Meup Flutter Project

## Antigravity Workflow Mapping
Workflows live in `.agent/workflows/` and should be invoked explicitly.

| Cursor Command | Workflow File |
| --- | --- |
| `/build-app` | `.agent/workflows/build-app.md` |
| `/debug-issues` | `.agent/workflows/debug-issues.md` |
| `/deploy-app` | `.agent/workflows/deploy-app.md` |
| `/generate-code` | `.agent/workflows/generate-code.md` |
| `/new-clean-architechture-flow` | `.agent/workflows/new-clean-architechture-flow.md` |
| `/new-pull-request-to-develop` | `.agent/workflows/new-pull-request-to-develop.md` |
| `/new-release` | `.agent/workflows/new-release.md` |
| `/onboard-new-developer` | `.agent/workflows/onboard-new-developer.md` |
| `/run-tests` | `.agent/workflows/run-tests.md` |
| `/setup-new-feature` | `.agent/workflows/setup-new-feature.md` |
| `/sync-localization` | `.agent/workflows/sync-localization.md` |
| `/update-clean-architecture-flow` | `.agent/workflows/update-clean-architecture-flow.md` |
| `/update-graph-schema` | `.agent/workflows/update-graph-schema.md` |
| `/update-new-ux-ui` | `.agent/workflows/update-new-ux-ui.md` |

## Overview
Optimized Cursor AI commands for autonomous task execution in the Meup Flutter project. These commands are designed for quick execution where you provide context files and the agent handles the rest.

## Command Philosophy

### Optimized for Agent Execution
- **Ask upfront**: Agent asks all necessary questions first
- **Execute autonomously**: Agent handles all implementation automatically
- **Concise output**: Brief summary of what was done
- **Review-ready**: User reviews results after completion

### Usage Pattern
```
1. User calls command with context file(s)
2. Agent asks clarifying questions
3. Agent executes everything automatically
4. Agent provides concise summary
5. User reviews and approves
```

## Core Commands

### 🏗️ Feature Development

#### `/setup-new-feature`
Create complete Clean Architecture feature (Domain + Data layers).

**Provide:**
- Ticket description OR API documentation OR similar feature reference

**Agent will:**
- Ask: feature name, data source type, state management needs
- Create: Domain layer (entities, repositories, use cases)
- Create: Data layer (models, repositories, data sources)
- Create: Cubit (if requested)
- Create: Test scaffolds
- Run: Code generation and validation
- Output: Summary of what was created

**UI layer excluded** - Use `/update-new-ux-ui` for presentation layer

---

#### `/update-new-ux-ui`
Implement UI from Figma designs.

**Provide:**
- Figma design URL (required)
- Component/page name

**Agent will:**
- Ask: component type, feature name, state integration
- Fetch: Figma design and extract tokens
- Map: Design tokens to existing theme
- Generate: Pages/widgets with responsive design
- Add: Routes and localization (if needed)
- Output: Summary with design tokens used

---

### 📋 Release Management

#### `/new-pull-request-to-develop`
Generate PR content from git changes.

**Provide:**
- Run from feature branch (current branch analyzed)

**Agent will:**
- Ask: target branch, include screenshots
- Analyze: All commits and file changes
- Categorize: Changes by layer and type
- Detect: Breaking changes, new dependencies
- Generate: Complete PR content with checklist
- Save: `pr_content.md` for review
- Output: PR summary and next steps

---

#### `/new-release`
Create release branch, notes, and tags.

**Provide:**
- Run from develop branch (for new) or release branch (to update)

**Agent will:**
- Ask: Confirm version from pubspec.yaml
- Create: Release branch (if needed)
- Analyze: All changes since last release
- Categorize: Features, improvements, fixes
- Generate: Comprehensive release notes
- Create: Git tag with detailed message
- Save: `release_content.md` and push to remote
- Output: Release summary and next steps

---

### 🔧 Maintenance Commands

#### `/generate-code`
Run all code generation tasks.
- Build runner for models, DI, routes
- Localization from Google Sheets
- Firebase configuration

#### `/debug-issues`
Troubleshoot common development issues.
- Build runner problems
- Dependency injection errors
- Platform-specific issues

#### `/build-app`
Build app for specific flavor and platform.
- APK/AAB for Android
- IPA for iOS
- All flavors: dev, stg, prod

#### `/run-tests`
Execute test suite with coverage.
- Unit tests
- Widget tests
- Integration tests

#### `/deploy-app`
Deploy to distribution channels.
- Firebase App Distribution
- Google Play Store
- Apple App Store

---

## Less Frequently Used Commands

### `/new-clean-architecture-flow`
**Status:** Reference document
Step-by-step guide for Clean Architecture implementation.

### `/update-clean-architecture-flow`
**Status:** Reference document
Update existing Clean Architecture module when data model changes.

### `/update-graph-schema`
**Status:** Semi-automated
Update GraphQL queries when schema changes.

### `/onboard-new-developer`
**Status:** Reference document
Onboarding guide for new team members.

---

## Command Structure Reference

### Optimized Command Format
```markdown
# Command Name

## Usage
What to provide to call this command

## Agent Questions (Ask First)
1-5 questions agent must ask upfront

## Auto-Execute After Questions
Step-by-step what agent does automatically

## Output
Concise summary format
```

### Old Format (Being Phased Out)
Long documentation-style commands with:
- Extensive checklists
- Manual step-by-step instructions
- Troubleshooting sections
- Reference materials

**Note:** Old commands still work but will be migrated to new format over time.

---

## Quick Start Examples

### Example 1: Create New Feature
```
User: "I need to implement user notifications feature. Here's the API doc: [paste]"

Agent:
- Feature name? → user_notifications
- Data source? → REST API
- State management? → Yes (BLoC)
- Skip UI? → Yes

[Agent creates everything automatically]

Agent: "✅ Feature 'user_notifications' created
- Domain: UserNotificationEntity, IUserNotificationRepository, 2 use cases
- Data: UserNotificationModel, repository, API client
- Cubit: UserNotificationsCubit with states
- Tests: 6 test scaffolds
- Build: ✅ Successful"
```

### Example 2: Implement UI from Figma
```
User: "Implement this Figma design: [URL]"

Agent:
- Component type? → New page
- Feature? → notifications
- State integration? → Use existing NotificationsCubit
- Special requirements? → Animations for list items

[Agent implements everything]

Agent: "✅ UI Implementation Complete: NotificationsPage
- Created: notifications_page.dart, notifications_view.dart
- Design tokens: 3 colors, 4 text styles, responsive
- State: Connected to NotificationsCubit
- Route: Added /notifications path"
```

### Example 3: Create Release
```
User: "Create new release"

Agent:
- Current: On develop ✓
- Version: 1.0.25+26 from pubspec.yaml - Confirm? → Yes

[Agent analyzes, categorizes, generates]

Agent: "✅ Release v1.0.25 Created
- 🎉 3 new features
- 🔧 7 improvements
- 🐛 2 bug fixes
- Branch: release/1.0.25 pushed
- Tag: v1.0.25 pushed
- Files: release_content.md ready"
```

---

## Project Context

### Architecture
- **Clean Architecture**: Domain, Data, Presentation layers
- **State Management**: BLoC/Cubit with HydratedBloc
- **DI**: get_it with injectable, `@lazySingleton` pattern
- **Navigation**: GoRouter with code generation
- **Localization**: YAML files with Google Sheets sync (slang)

### Flavors
- **dev**: Development with debug features
- **stg**: Staging mirroring production
- **prod**: Production for live deployment

### Key Files
- `CLAUDE.md`: Project quick reference
- `lib/src/<feature>/domain/`: Business logic layer
- `lib/src/<feature>/data/`: Data layer with repos/models
- `lib/src/<feature>/presentation/`: UI layer with pages/cubits
- `lib/config/`: App configuration (DI, routes, themes)

---

## Command Maintenance

### How to Update Commands
Commands evolve with project needs. To update:

1. **Modify the .md file** in `.agent/workflows/`
2. **Follow the optimized structure** (Usage → Questions → Auto-Execute → Output)
3. **Test with actual use case**
4. **Update this README** if adding/removing commands

### Command Versioning
- **v1 (Old)**: Documentation-heavy, manual checklists
- **v2 (Current)**: Agent-optimized, autonomous execution
- **Migration**: Gradual update of high-use commands first

### Feedback Loop
If a command doesn't work well:
1. Note what questions agent should have asked upfront
2. Note what agent did that required manual intervention
3. Update command to ask those questions first
4. Update auto-execute section to handle that case

---

## Tips for Best Results

### For Users
- **Provide context files** when calling commands
- **Answer agent questions** clearly upfront
- **Let agent work autonomously** after questions
- **Review results** when complete
- **Provide feedback** for command improvements

### For Agents
- **Ask all questions upfront** - don't come back for more info
- **Execute everything automatically** after questions answered
- **Follow project patterns** from similar existing code
- **Provide concise summaries** - user wants quick review
- **Save detailed logs** to files for user reference

---

## Getting Help

### Documentation
- **This README**: Command overview and usage
- **CLAUDE.md**: Project-wide reference
- **Individual commands**: Detailed execution steps

### Support
- Review existing similar features for patterns
- Check git history for how things were done before
- Use `/debug-issues` for common problems

---

**Last Updated:** 2025-01-29
**Optimized for:** Autonomous agent execution with minimal back-and-forth
**Philosophy:** Ask upfront, execute autonomously, summarize concisely

# Claude Code Commands for Meup Flutter Project

## Overview
Optimized slash commands for Claude Code that leverage Task agents, TodoWrite tracking, and intelligent codebase exploration for autonomous task execution.

## Philosophy
- **Ask once, execute fully** - All questions upfront, then autonomous execution
- **Use agents smartly** - Spawn Explore/Plan agents for complex operations
- **Track progress** - Use TodoWrite for multi-step workflows
- **Reference context** - Link to CLAUDE.md instead of embedding everything
- **Validate thoroughly** - Check before and after changes

## Core Commands

### 🏗️ Feature Development

#### `/setup-new-feature`
Create complete Clean Architecture feature (Domain + Data layers) by analyzing similar patterns in your codebase.

**Use when:** Starting new feature with backend integration
**Provides:** Entities, repositories, use cases, models, tests
**Agent usage:** Explore agent finds similar features to follow patterns

---

#### `/update-new-ux-ui`
Implement UI from Figma designs using MCP integration and design token mapping.

**Use when:** Implementing new UI or updating existing screens from Figma
**Provides:** Pages, widgets, routes, design tokens
**Agent usage:** Figma MCP extraction + Explore agent for similar UI patterns

---

### 📋 Release Management

#### `/new-pull-request`
Generate comprehensive PR content by analyzing all changes with smart categorization.

**Use when:** Ready to create PR from feature branch
**Provides:** PR title, description, change categorization, checklists
**Agent usage:** Analyze agent for change impact assessment

---

#### `/new-release`
Create release branch, comprehensive release notes, and git tags automatically.

**Use when:** Creating new release from develop branch
**Provides:** Release branch, categorized notes, git tags
**Agent usage:** Analyze agent for commit categorization and change summarization

---

### 🔧 Maintenance

#### `/generate-code`
Run all code generation tasks (build_runner, localization, Firebase config).

**Use when:** After model/route/DI changes
**Provides:** Generated code, validation report
**Agent usage:** Sequential execution with validation

---

#### `/update-clean-architecture-flow`
Update existing Clean Architecture module when data models change.

**Use when:** API contract changes require model updates
**Provides:** Updated models, entities, repositories with proper conversions
**Agent usage:** Explore agent finds all related files in flow

---

#### `/update-graph-schema`
Synchronize GraphQL queries with updated schema.graphql.

**Use when:** GraphQL schema changes
**Provides:** Updated query files, missing fields added
**Agent usage:** Analyze schema changes, update all affected queries

---

## Command Usage Pattern

### Standard Flow
```
1. User: /command-name
2. Claude: Asks 3-5 clarifying questions
3. User: Answers all questions
4. Claude: Spawns agents if needed, tracks with todos
5. Claude: Executes workflow autonomously
6. Claude: Provides concise summary with file references
```

### Example: Feature Creation
```
User: /setup-new-feature
      "Need to implement push notifications"

Claude: Questions:
        1. Feature name? → push_notifications
        2. Data source? → REST API
        3. State management? → Yes (Cubit)

        [Spawns Explore agent to find similar features]
        [Creates all layers in parallel]
        [Tracks progress with TodoWrite]
        [Validates with build_runner]

        ✅ Complete: push_notifications feature
        - Domain: PushNotificationEntity, 3 use cases
        - Data: API client, repository, models
        - Cubit: PushNotificationsCubit with 4 states
        - Tests: 8 test scaffolds
        Files: lib/src/push_notifications/...
```

## Tool Usage Patterns

### Task Agents
Commands use specialized agents for complex operations:
- **Explore**: Find similar code patterns, analyze codebase structure
- **Plan**: Plan complex multi-step workflows before execution

### TodoWrite Tracking
Multi-step commands track progress:
```
☐ Analyze codebase patterns
☑ Create domain layer
☑ Create data layer
☐ Run code generation
☐ Validate build
```

### Parallel Execution
Independent operations run simultaneously:
- Create multiple files at once
- Run multiple git commands together
- Validate while generating

### MCP Integration
- **Figma MCP**: Direct design token extraction for UI commands
- **Git context**: Full git history and diff analysis

## Project Context Integration

### References CLAUDE.md
Commands reference your project documentation for:
- Clean Architecture patterns
- Dependency injection setup
- State management patterns
- Code generation workflows
- Testing conventions

### Understands Project Structure
```
lib/
├── src/
│   ├── domain/ (entities, repos, use cases)
│   ├── data/ (models, repos, APIs)
│   └── presentation/ (pages, widgets, cubits)
├── config/ (DI, routes, themes)
└── core/ (utils, constants)
```

### Follows Conventions
- `@lazySingleton` for DI
- `Either<AppException, T>` for error handling
- `HydratedCubit` for state persistence
- Freezed for immutable models
- GraphQL + REST patterns

## Command Capabilities

### Intelligent Code Analysis
- Finds similar features automatically
- Detects patterns in existing code
- Identifies related files across layers
- Understands architectural relationships

### Smart Generation
- Uses templates from similar code
- Maintains naming conventions
- Follows project patterns
- Generates proper imports

### Thorough Validation
- Checks compilation before/after
- Verifies DI registration
- Validates code generation
- Runs flutter analyze

### Context-Aware Output
- Provides file:line references
- Links to similar code
- Explains architectural decisions
- Suggests next steps

## Best Practices

### For Users
1. **Provide clear context** - Share requirements, API docs, or Figma links
2. **Answer questions completely** - Agent needs all info upfront
3. **Trust the process** - Let agents explore and execute
4. **Review the output** - Check generated code and summaries
5. **Give feedback** - Help improve command accuracy

### For Optimal Results
- Run commands from project root
- Ensure clean git state for PR/release commands
- Have Figma links ready for UI commands
- Provide API documentation for new features
- Review CLAUDE.md for project patterns

## Differences from Cursor Commands

### Enhanced with Claude Code Features
1. **Task agents** - Explore/Plan agents for intelligent codebase analysis
2. **TodoWrite** - Visual progress tracking for multi-step operations
3. **Better context** - Direct reference to CLAUDE.md patterns
4. **Parallel execution** - Multiple independent operations simultaneously
5. **MCP integration** - Direct Figma access without manual exports
6. **Smarter validation** - Before/after checks with detailed reporting

### Streamlined for Efficiency
- Removed: build-app, deploy-app (better as scripts/CI)
- Removed: debug-issues (better as conversational help)
- Removed: onboard-new-developer (better as documentation)
- Kept: Core workflows that benefit from AI intelligence

## Command Maintenance

### Updating Commands
Commands evolve with your project. To update:
1. Edit the .md file in `.claude/commands/`
2. Test with real scenarios
3. Update README if behavior changes
4. Share feedback with team

### Adding New Commands
When creating new commands:
1. Follow the structure in existing commands
2. Use Task agents for complex operations
3. Reference CLAUDE.md for patterns
4. Include concrete examples
5. Test thoroughly before committing

### Feedback Loop
Commands improve through use:
- Note missing questions that should be asked upfront
- Identify patterns that agents should recognize
- Document edge cases and solutions
- Share learnings with team

## Getting Started

1. **Try a simple command**: `/generate-code`
2. **Create a feature**: `/setup-new-feature` with API docs
3. **Implement UI**: `/update-new-ux-ui` with Figma link
4. **Make a release**: `/new-release` when ready

## Support

- **CLAUDE.md**: Project architecture and patterns
- **Individual commands**: Detailed workflow documentation
- **Git history**: See how features were implemented before
- **Ask Claude**: Conversational help for edge cases

---

**Last Updated:** 2025-01-29
**Optimized for:** Claude Code with Task agents and TodoWrite tracking
**Philosophy:** Intelligent exploration → Autonomous execution → Concise summary

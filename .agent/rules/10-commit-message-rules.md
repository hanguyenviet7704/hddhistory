---
trigger: model_decision
description: Commit message generation rules following GitFlow convention with automatic ticket ID detection
---

# Commit Message Generation Rules

When generating commit messages for this project, follow the GitFlow convention with these guidelines:

## Format

Always use this format:
- `type-TICKET-ID: subject` - Always include the ticket ID in the commit message

## Valid Types

- `feature` - New feature implementation
- `fix` - Bug fixes
- `refactor` - Code refactoring
- `style` - Code style changes
- `docs` - Documentation changes
- `test` - Test additions or modifications
- `chore` - Maintenance tasks
- `perf` - Performance improvements

## Automatic Ticket ID Detection

Extract ticket ID from current branch name:
- Pattern: `type/TICKET-ID-description` → Use `TICKET-ID`
- Pattern: `type/TICKET-ID/TICKET-ID-description` → Use the second `TICKET-ID`
- Pattern: `type/TICKET-ID/TICKET-ID` → Use the second `TICKET-ID`

Examples:
- From `feature/ARTLEXIS-123-feature-name` → Use `ARTLEXIS-123`
- From `feature/ARTLEXIS-123/feature-name` → Use `ARTLEXIS-123`
- From `feature/ARTLEXIS-271/ARTLEXIS-409` → Use `ARTLEXIS-409`
- From `feature/ARTLEXIS-271/ARTLEXIS-409-description` → Use `ARTLEXIS-409`

## Scope Detection

Based on file paths, the appropriate commit type can be determined:
- `lib/src/presentation/blocs/*` → type: `feature` for new blocs/cubits
- `lib/src/presentation/pages/*` → type: `feature` for new pages, `style` for UI changes
- `lib/src/presentation/widgets/*` → type: `feature` for new widgets, `style` for UI changes
- `lib/config/routes/*` → type: `feature` for new routes, `fix` for routing issues
- `lib/src/data/*` → type: `feature` for new data models, `fix` for data-related bugs
- `lib/src/domain/*` → type: `feature` for new domain entities/usecases

## Examples Based on File Types

### State Management Files
```
feature-ARTLEXIS-123: Add state management
feature-ARTLEXIS-123: Implement cubit
```

### UI Component Files
```
feature-ARTLEXIS-123: Add new page
style-ARTLEXIS-123: Update view layout
```

### Routing Files
```
feature-ARTLEXIS-123: Add routes
fix-ARTLEXIS-123: Correct navigation parameters
```

### Multiple Related Files
```
feature-ARTLEXIS-123: Implement complete feature
```

## Commit Message Rules

1. Use imperative mood ("Add" not "Added")
2. Capitalize first letter
3. No period at end of subject
4. Keep under 50 characters
5. Be specific and descriptive

## Context-Aware Suggestions

When generating commit messages:
1. Check current branch for ticket ID
2. Analyze files for appropriate commit type
3. Group related changes
4. Always include the ticket ID in the format `type-TICKET-ID: subject`

## Special Cases

### Initial Implementation
`feature-ARTLEXIS-123: Initial implementation of [feature name]`

### Bug Fixes
`fix-ARTLEXIS-123: Resolve [specific issue]`

### UI Updates
`style-ARTLEXIS-123: Update [what changed]`

### Refactoring
`refactor-ARTLEXIS-123: Extract [what was extracted]`
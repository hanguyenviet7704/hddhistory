---
trigger: model_decision
description: Commit message rules with ticket extraction and file-based guidance
---

# Commit Message Rules

Use this format for all commits:
- `type/TICKET-ID: description` - Always include the ticket ID

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
- Pattern: `type/TICKET-ID/description` → Use `TICKET-ID`
- Pattern: `type/TICKET-ID/TICKET-ID-description` → Use the second `TICKET-ID`
- Pattern: `type/TICKET-ID/TICKET-ID` → Use the second `TICKET-ID`

Examples:
- From `feature/MEUP-123-feature-name` → Use `MEUP-123`
- From `feature/MEUP-123/feature-name` → Use `MEUP-123`
- From `feature/MEUP-271/MEUP-409` → Use `MEUP-409`
- From `feature/MEUP-271/MEUP-409-description` → Use `MEUP-409`

## Scope Detection

Based on file paths, the appropriate commit type can be determined:
- `lib/src/<feature>/presentation/cubits/*` → type: `feature` for new cubits
- `lib/src/<feature>/presentation/blocs/*` → type: `feature` for new blocs
- `lib/src/<feature>/presentation/pages/*` → type: `feature` for new pages, `style` for UI changes
- `lib/src/<feature>/presentation/widgets/*` → type: `feature` for new widgets, `style` for UI changes
- `lib/config/routes/*` → type: `feature` for new routes, `fix` for routing issues
- `lib/src/<feature>/data/*` → type: `feature` for new data models, `fix` for data-related bugs
- `lib/src/<feature>/domain/*` → type: `feature` for new domain entities/usecases

## Examples Based on File Types

### State Management Files
```
feature/MEUP-123: add state management
feature/MEUP-123: add cubit
```

### UI Component Files
```
feature/MEUP-123: add new page
style/MEUP-123: update view layout
```

### Routing Files
```
feature/MEUP-123: add routes
fix/MEUP-123: correct navigation parameters
```

### Multiple Related Files
```
feature/MEUP-123: implement complete feature
```

## Commit Message Rules

1. Use imperative mood ("add" not "added")
2. Keep the subject under 50 characters
3. No period at end of subject
4. Prefer lowercase description
5. Be specific and descriptive

## Context-Aware Suggestions

When generating commit messages:
1. Check current branch for ticket ID
2. Analyze files for appropriate commit type
3. Group related changes
4. Always include the ticket ID in the format `type/TICKET-ID: description`

## Special Cases

### Initial Implementation
`feature/MEUP-123: initial implementation of [feature name]`

### Bug Fixes
`fix/MEUP-123: resolve [specific issue]`

### UI Updates
`style/MEUP-123: update [what changed]`

### Refactoring
`refactor/MEUP-123: extract [what was extracted]`

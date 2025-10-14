# Commit Message Conventions

This document outlines the commit message conventions used across Flutter projects, following the established GitFlow workflow.

## Commit Message Format

### Standard Format
```
type-TICKET-ID: subject

[optional body]

[optional footer]
```

### Components

#### 1. Type
The type indicates the category of change:
- **`feature`**: New feature implementation
- **`fix`**: Bug fixes
- **`refactor`**: Code refactoring without changing functionality
- **`style`**: Code style changes (formatting, naming, etc.)
- **`docs`**: Documentation changes
- **`test`**: Adding or modifying tests
- **`chore`**: Maintenance tasks, dependency updates
- **`perf`**: Performance improvements

#### 2. Ticket ID
Always include the ticket/issue ID when available:
- Extract from branch name (e.g., `ARTLEXIS-123`)
- Use the format established in your ticketing system
- Essential for traceability and project management

#### 3. Subject
- Use imperative mood: "Add feature" not "Added feature"
- Keep under 50 characters
- Capitalize first letter
- No period at the end
- Be descriptive and specific

## Examples by Type

### Feature Commits
```
feature-ARTLEXIS-123: Add social login functionality
feature-ARTLEXIS-456: Implement dark mode toggle
feature-ARTLEXIS-789: Add user profile management
```

### Bug Fix Commits
```
fix-ARTLEXIS-234: Correct email validation regex pattern
fix-ARTLEXIS-567: Resolve null pointer in user service
fix-ARTLEXIS-890: Fix memory leak in image cache
```

### Refactoring Commits
```
refactor-ARTLEXIS-345: Extract authentication logic to service
refactor-ARTLEXIS-678: Simplify user model structure
refactor-ARTLEXIS-901: Optimize API response handling
```

### Style Commits
```
style-ARTLEXIS-456: Update gallery view layout
style-ARTLEXIS-789: Improve button spacing consistency
style-ARTLEXIS-012: Apply new color scheme
```

### Documentation Commits
```
docs-ARTLEXIS-567: Add API integration guide
docs-ARTLEXIS-890: Update README with setup instructions
docs-ARTLEXIS-123: Document state management patterns
```

### Testing Commits
```
test-ARTLEXIS-678: Add unit tests for user repository
test-ARTLEXIS-901: Add widget tests for login screen
test-ARTLEXIS-234: Add integration tests for API calls
```

### Chore Commits
```
chore-ARTLEXIS-789: Update dependencies to latest versions
chore-ARTLEXIS-012: Configure CI/CD pipeline
chore-ARTLEXIS-345: Update build scripts
```

## Context-Aware Commit Messages

### By File Location
When working with specific parts of the codebase, include relevant context:

#### State Management Files
```
feature-ARTLEXIS-123: Add authentication bloc
fix-ARTLEXIS-456: Resolve state persistence in user cubit
refactor-ARTLEXIS-789: Simplify navigation bloc logic
```

#### UI Components
```
feature-ARTLEXIS-234: Add custom date picker widget
style-ARTLEXIS-567: Update login screen layout
fix-ARTLEXIS-890: Correct text field validation styling
```

#### API Integration
```
feature-ARTLEXIS-345: Implement user authentication API
fix-ARTLEXIS-678: Handle API timeout exceptions
refactor-ARTLEXIS-901: Optimize API request interceptors
```

#### Routing
```
feature-ARTLEXIS-456: Add deep link support for profiles
fix-ARTLEXIS-789: Resolve navigation stack issues
refactor-ARTLEXIS-012: Simplify route definitions
```

## Extended Commit Messages

### When to Use Body
Use the optional body when:
- The change is complex and needs explanation
- Multiple files are affected
- Breaking changes are introduced
- Special instructions are needed

### Example with Body
```
feature-ARTLEXIS-123: Implement user authentication system

- Add login and registration screens
- Integrate with OAuth providers (Google, Apple)
- Implement secure token storage
- Add biometric authentication support

This change introduces a complete authentication flow
that supports both traditional email/password and
social login options.
```

### Breaking Changes
```
refactor-ARTLEXIS-456: Restructure user model architecture

BREAKING CHANGE: User model properties have been renamed
- `userName` is now `username`
- `userEmail` is now `email`
- `userStatus` is now `status`

Migration guide available in docs/migration/user-model.md
```

## Branch Name to Ticket ID Extraction

### Supported Branch Formats
1. `feature/ARTLEXIS-123-description` → Use `ARTLEXIS-123`
2. `feature/ARTLEXIS-123/ARTLEXIS-123-description` → Use `ARTLEXIS-123`
3. `fix/ARTLEXIS-456-bug-description` → Use `ARTLEXIS-456`

### Examples
```bash
# Branch: feature/ARTLEXIS-123-add-login-screen
git commit -m "feature-ARTLEXIS-123: Add login form validation"

# Branch: fix/ARTLEXIS-456/ARTLEXIS-456-email-validation
git commit -m "fix-ARTLEXIS-456: Correct email regex pattern"
```

## Best Practices

### Writing Good Commit Messages
1. **Be atomic**: Each commit should represent one logical change
2. **Be specific**: Describe what was changed, not just that it was changed
3. **Use present tense**: "Add feature" not "Added feature"
4. **Include context**: Reference related issues or documentation
5. **Review before committing**: Ensure the message accurately describes the change

### Common Mistakes to Avoid
```bash
# Too vague
git commit -m "fix stuff"

# Missing ticket ID
git commit -m "feature: add new functionality"

# Wrong tense
git commit -m "feature-ARTLEXIS-123: Added user login"

# Too long subject
git commit -m "feature-ARTLEXIS-123: Add comprehensive user authentication system with support for multiple providers"
```

### Good Examples
```bash
# Clear and specific
git commit -m "feature-ARTLEXIS-123: Add email validation to login form"

# Includes scope
git commit -m "fix-ARTLEXIS-456: Resolve memory leak in image cache manager"

# Breaking change indication
git commit -m "refactor-ARTLEXIS-789: Update user model structure

BREAKING CHANGE: Username field renamed to displayName"
```

## Integration with Development Workflow

### Pre-commit Hooks
Consider setting up pre-commit hooks to validate commit messages:

```bash
#!/bin/sh
# .git/hooks/commit-msg
commit_regex='^(feature|fix|refactor|style|docs|test|chore|perf)-[A-Z]+-[0-9]+: .{1,50}$'

if ! grep -qE "$commit_regex" "$1"; then
    echo "Invalid commit message format!"
    echo "Format: type-TICKET-ID: subject"
    echo "Example: feature-ARTLEXIS-123: Add user authentication"
    exit 1
fi
```

### IDE Integration
Most IDEs can be configured to:
- Auto-extract ticket ID from branch names
- Provide commit message templates
- Validate commit message format
- Show commit message history and suggestions
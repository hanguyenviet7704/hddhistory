Description: Synchronize GraphQL queries with updated schema.graphql automatically

# Update GraphQL Schema

## What This Does
Synchronizes GraphQL query files when schema changes by:
- **Analyzing schema.graphql changes** to identify modified types
- **Finding all related query files** that use those types
- **Detecting missing fields** by comparing queries to schema
- **Adding new fields** to queries automatically
- **Removing deprecated fields** from queries
- **Validating** all queries against new schema

**Keeps queries in sync** with GraphQL schema automatically.

## When to Use
- GraphQL schema.graphql file updated
- Backend added new fields to types
- Fields removed or deprecated in schema
- Need to ensure all queries are complete

**After backend schema updates** - Keep frontend queries synchronized.

## Required Context
**Automatically detected:**
- Path to schema.graphql file
- Git diff showing schema changes (if available)

**Or provide:**
- List of types that changed
- Specific query files to update

## Command Flow

### 1. Ask Questions
Uses `AskUserQuestion` to gather:
```
1. Schema changes:
   - Automatic (detect from git diff)
   - Specify types manually

2. Update approach:
   - Add missing fields only
   - Full synchronization (add + remove)
   - Show preview first (safe)

3. Run code generation after:
   - Yes (recommended)
   - No (I'll run it later)
```

### 2. Analyze Schema Changes
Spawns **Task agent (Explore)** to analyze:
```
Task: "Compare schema.graphql changes:
      1. If git diff available, identify changed types
      2. Otherwise, read schema and list all types
      3. For each type, extract fields and their types
      4. Identify new fields, removed fields, type changes
      Return structured change list"
```

Example analysis:
```
Schema Changes Detected:

Type: Profile
  Added fields:
    - timestamps: ProfileTimestamps
    - subscription_tier: String
  Modified fields:
    - booster_uses_remaining: Int → Int! (now required)

Type: ProfileTimestamps (NEW TYPE)
  Fields:
    - last_lesson_completed_at: DateTime
    - last_login_at: DateTime
```

### 3. Find Related Query Files
Uses `Glob` and `Grep` to find:
```bash
# Find all GraphQL query files
glob: lib/src/data/datasources/graphql/template/*.graphql

# Search for queries using changed types
grep: "query.*Profile" in *.graphql files
```

Example findings:
```
Found queries using Profile type:
- lib/src/data/datasources/graphql/template/profile.graphql
  • GetMyProfile query
  • UpdateProfile mutation

- lib/src/data/datasources/graphql/template/roadmap.graphql
  • GetRoadmapWithProfile query
```

### 4. Track Update Process
Uses `TodoWrite` to track:
```
☐ Analyze schema changes
☐ Find related query files
☐ Update profile.graphql (2 queries)
☐ Update roadmap.graphql (1 query)
☐ Validate queries against schema
☐ Run GraphQL code generation
☐ Validate generated code
```

### 5. Update Each Query File
For each query file, uses `Read` then `Edit`:

**Before (profile.graphql):**
```graphql
query GetMyProfile($version: String) {
  myProfiles(version: $version) {
    id
    user_id
    nickname
    avatar_url
    skill_level
    preferred_language
    unlocked_tools
    booster_uses_remaining
    geolocation {
      current_country
      current_city
    }
    active_subscriptions {
      id
      status
    }
    number_lesson_completed
  }
}
```

**After (with new fields):**
```graphql
query GetMyProfile($version: String) {
  myProfiles(version: $version) {
    id
    user_id
    nickname
    avatar_url
    skill_level
    preferred_language
    unlocked_tools
    booster_uses_remaining
    geolocation {
      current_country
      current_city
    }
    active_subscriptions {
      id
      status
    }
    number_lesson_completed
    timestamps {                        # NEW
      last_lesson_completed_at
      last_login_at
    }
    subscription_tier                    # NEW
  }
}
```

### 6. Handle Nested Types
Automatically includes nested type fields:

```graphql
# Schema defines:
type ProfileTimestamps {
  last_lesson_completed_at: DateTime
  last_login_at: DateTime
  created_at: DateTime
  updated_at: DateTime
}

# Query includes all fields:
timestamps {
  last_lesson_completed_at
  last_login_at
  created_at
  updated_at
}
```

### 7. Handle Removed Fields
If fields removed from schema:

```diff
query GetMyProfile {
  myProfiles {
    id
    name
-   deprecated_field  # Removed from schema
    email
  }
}
```

Reports:
```
⚠️ Removed deprecated fields:
- Profile.deprecated_field (no longer in schema)
```

### 8. Validate Against Schema
Checks each query:
- ✅ All queried fields exist in schema
- ✅ Field types match schema
- ✅ Required fields are included
- ✅ Nested types are complete

### 9. Run GraphQL Code Generation
Executes:
```bash
dart run build_runner build --delete-conflicting-outputs
```

Regenerates:
- `*.graphql.dart` - Query/mutation classes
- Type-safe API clients
- Generated types from schema

### 10. Validate Generated Code
Checks:
- ✅ All queries compile
- ✅ No type mismatches
- ✅ Imports resolve
- ✅ flutter analyze passes

## Output Format

```
✅ GraphQL Schema Synchronized

📊 Schema Changes Analyzed
Modified Types: 2
- Profile (2 new fields, 1 modified)
- ProfileTimestamps (new type)

📝 Query Files Updated
✓ profile.graphql
  • GetMyProfile: Added 2 fields
  • UpdateProfile: No changes needed

✓ roadmap.graphql
  • GetRoadmapWithProfile: Added 1 field

📋 Changes Summary

profile.graphql - GetMyProfile:
  + timestamps.last_lesson_completed_at
  + timestamps.last_login_at
  + subscription_tier

profile.graphql - UpdateProfile:
  No changes required

roadmap.graphql - GetRoadmapWithProfile:
  + timestamps.last_lesson_completed_at

🔧 Code Generation
✓ GraphQL code generated successfully
✓ 3 query classes updated
✓ Type-safe clients regenerated

✅ Validation
✓ All queries valid against schema
✓ No missing required fields
✓ All nested types complete
✓ flutter analyze: 0 issues

⚠️ Deprecated Fields Removed
- Profile.old_field (no longer in schema)

🎯 Next Steps
1. Update models if new fields affect data layer
2. Update UI to display new data
3. Update tests for new query fields
```

## Example Usage

### Example 1: Automatic Schema Sync
```
User: /update-graph-schema
      "Schema updated, need to sync queries"

Claude: Questions:
        1. Schema changes? → Automatic (from git diff)
        2. Update approach? → Add missing fields only
        3. Run code generation? → Yes

        [Detects Profile type changes]
        [Finds 2 query files using Profile]
        [Adds timestamps and subscription_tier fields]
        [Runs code generation]
        [Validates everything]

        ✅ Complete
        - 2 query files updated
        - 3 new fields added
        - Code generation successful
```

### Example 2: Specific Type Update
```
User: /update-graph-schema
      "Lesson type has new fields, update lesson.graphql"

Claude: Questions:
        1. Schema changes? → Specify: Lesson type
        2. Update approach? → Show preview first
        3. Run code generation? → Yes

        [Analyzes Lesson type in schema]
        [Shows preview of changes to lesson.graphql]
        [User confirms]
        [Applies changes]
        [Generates code]

        ✅ Complete
        - lesson.graphql updated
        - Preview confirmed before applying
```

## Smart Features

### Nested Type Handling
Automatically queries all fields of nested types:
```graphql
# Schema:
type Profile {
  geolocation: ProfileGeolocation
}

type ProfileGeolocation {
  country: String
  city: String
  timezone: String
}

# Auto-generates complete query:
geolocation {
  country
  city
  timezone
}
```

### Required Field Detection
Ensures required fields are included:
```graphql
# Schema marks field as required:
type Profile {
  id: ID!         # Required
  email: String!  # Required
  phone: String   # Optional
}

# Query validation checks:
✓ id is queried (required)
✓ email is queried (required)
⚠ phone not queried (optional, ok)
```

### Fragment Handling
Updates fragments used by queries:
```graphql
fragment ProfileFragment on Profile {
  id
  name
  # Adds new fields to fragment
  timestamps {
    last_lesson_completed_at
  }
}

query GetProfile {
  profile {
    ...ProfileFragment
  }
}
```

### Mutation Updates
Also updates mutations:
```graphql
mutation UpdateProfile($input: UpdateProfileInput!) {
  updateProfile(input: $input) {
    id
    name
    # Adds new return fields
    timestamps {
      last_lesson_completed_at
    }
  }
}
```

## Common Issues and Solutions

### Issue: New Required Field
```
⚠️ Schema added required field: email: String!
```
**Solution:** Automatically adds to all queries using that type

### Issue: Type Changed
```
⚠️ Field type changed: age: Int → age: String
```
**Solution:** Reports breaking change:
```
⚠️ Breaking Change:
- Profile.age type changed: Int → String
- Update models and code handling this field
```

### Issue: Field Removed from Schema
```
⚠️ Field deprecated_field no longer exists in schema
```
**Solution:** Removes from queries:
```
Removed from queries:
- profile.graphql: deprecated_field
```

### Issue: Deep Nesting
```
Schema has 3+ levels of nested types
```
**Solution:** Asks about depth:
```
ProfileTimestamps has nested LastAction type.
Include all nested fields? [Yes/No/Specify depth]
```

## Validation Rules

### Pre-Update Checks
- [ ] schema.graphql file exists and is valid
- [ ] Query files are syntactically correct
- [ ] No uncommitted query changes

### Post-Update Checks
- [ ] All queries valid against schema
- [ ] No missing required fields
- [ ] All nested types complete
- [ ] Code generation successful
- [ ] No compilation errors

## Advanced Usage

### Compare Specific Queries
```
User: /update-graph-schema
      "Just check if profile.graphql is in sync"

Claude: [Analyzes only profile.graphql]
        [Shows missing fields without modifying]

        📊 Analysis: profile.graphql
        Missing fields:
        - timestamps (ProfileTimestamps)
        - subscription_tier (String)

        Apply updates? [Yes/No]
```

### Batch Update All Queries
```
User: /update-graph-schema
      "Update all .graphql files to match schema"

Claude: [Scans all *.graphql files]
        [Updates all queries systematically]
        [Generates complete report]

        ✅ Updated 8 query files
        - 23 fields added
        - 5 deprecated fields removed
```

---

*See CLAUDE.md: GraphQL Integration for schema management*
*See CLAUDE.md: Code Generation for build_runner GraphQL setup*

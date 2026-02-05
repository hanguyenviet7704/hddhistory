---
trigger: model_decision
description: Workflow for /update-graph-schema (GraphQL Schema Update Guide)
---

# GraphQL Schema Update Guide

## Invocation
Use only when the user explicitly requests `/update-graph-schema` or asks to run this workflow.
Ask the listed questions first, then execute the steps.

## Overview
This guide provides instructions for updating GraphQL query files when the schema.graphql file is modified. This ensures that all GraphQL queries remain in sync with the schema definitions.

## Process Summary

### What Was Done
1. **Analyzed schema.graphql changes**: Identified new fields in the Profile type
2. **Compared with existing queries**: Found missing fields in profile.graphql
3. **Updated profile.graphql**: Added the missing `timestamps` field with its sub-fields

### Changes Made
- **File**: `lib/src/<feature>/data/datasources/graphql/template/profile.graphql`
- **Added**: `timestamps` field to the GetMyProfile query
- **Sub-fields**: `last_lesson_completed_at` from ProfileTimestamps type

## Step-by-Step Process for Future Updates

### 1. Identify Schema Changes
```bash
# Check git status for modified schema files
git status lib/src/<feature>/data/datasources/graphql/template/schema.graphql
```

### 2. Analyze Type Definitions
- Open `lib/src/<feature>/data/datasources/graphql/template/schema.graphql`
- Identify modified type definitions (e.g., Profile, Lesson, RoadmapNode, etc.)
- Note any new fields, removed fields, or type changes

### 3. Find Related Query Files
- Look for corresponding `.graphql` files in the same directory
- Common patterns:
  - `profile.graphql` → queries Profile type
  - `roadmap.graphql` → queries RoadmapNode type
  - `lesson.graphql` → queries Lesson type

### 4. Compare and Update Queries
For each query file:
- Compare the query fields with the schema type definition
- Add missing fields that are available in the schema
- Remove fields that no longer exist in the schema
- Update field types if they've changed

### 5. Common Field Patterns to Check

#### Profile Type Fields
```graphql
type Profile {
  id: ID!
  user_id: ID!
  nickname: String
  avatar_url: String
  skill_level: String
  preferred_language: String
  unlocked_tools: [Tool]
  booster_uses_remaining: Int
  geolocation: ProfileGeolocation
  active_subscriptions: [Subscription!]
  number_lesson_completed: Int
  timestamps: ProfileTimestamps  # ← Check if this is included
}
```

#### Nested Type Fields
Always include nested type fields when they're available:
```graphql
# ProfileTimestamps
timestamps {
  last_lesson_completed_at
}

# ProfileGeolocation
geolocation {
  profile_id
  current_country
  current_country_code
  current_city
  current_region
  current_timezone
  current_latitude
  current_longitude
  geo_source
  geo_last_updated_at
}
```

### 6. Validation Steps
1. **Syntax Check**: Ensure GraphQL syntax is valid
2. **Field Existence**: Verify all queried fields exist in schema
3. **Type Matching**: Confirm field types match schema definitions
4. **Nested Fields**: Include all available nested fields

### 7. Testing
After updates:
```bash
# Run GraphQL code generation
dart run build_runner build --delete-conflicting-outputs

# Check for any compilation errors
flutter analyze
```

## File Structure Reference

```
lib/src/<feature>/data/datasources/graphql/template/
├── schema.graphql          # Main schema definition
├── profile.graphql         # Profile-related queries
├── roadmap.graphql         # Roadmap-related queries
├── lesson.graphql          # Lesson-related queries
└── [other].graphql         # Other feature-specific queries
```

## Common Commands

### Check Schema Changes
```bash
git diff lib/src/<feature>/data/datasources/graphql/template/schema.graphql
```

### Regenerate GraphQL Code
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Validate GraphQL Files
```bash
# Check for syntax errors
flutter analyze lib/src/<feature>/data/datasources/graphql/
```

## Best Practices

1. **Always update queries when schema changes**
2. **Include all available fields** unless specifically excluded for performance
3. **Maintain consistent field ordering** in queries
4. **Use descriptive field names** that match schema
5. **Comment out deprecated fields** instead of removing them immediately
6. **Test queries after updates** to ensure they work correctly

## Troubleshooting

### Common Issues
- **Missing fields**: Add fields that exist in schema but not in query
- **Type mismatches**: Update field types to match schema
- **Nested field omissions**: Include all available nested fields
- **Syntax errors**: Validate GraphQL syntax after changes

### Error Messages
- `Field "fieldName" doesn't exist on type "TypeName"` → Remove non-existent fields
- `Cannot query field "fieldName" on type "TypeName"` → Add missing fields
- `Expected type "TypeA" but got "TypeB"` → Fix type mismatches

## Example Update Process

### Before (Missing timestamps field)
```graphql
query GetMyProfile($version: String) {
  myProfiles(version: $version) {
    id
    user_id
    nickname
    # ... other fields
    number_lesson_completed
  }
}
```

### After (Complete with timestamps)
```graphql
query GetMyProfile($version: String) {
  myProfiles(version: $version) {
    id
    user_id
    nickname
    # ... other fields
    number_lesson_completed
    timestamps {
      last_lesson_completed_at
    }
  }
}
```

## Notes for Cursor Agents

- Always check the current branch for ticket ID when making commits
- Use format: `feature/TICKET-ID: update GraphQL queries for schema changes`
- Verify all changes work before committing
- Follow the established GraphQL patterns in the codebase
- Maintain backward compatibility when possible

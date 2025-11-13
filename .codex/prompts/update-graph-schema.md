---
description: Sync GraphQL queries/templates with the latest schema changes
argument-hint: [ TYPES=Profile,Lesson,... ] [ MODE=add|sync|preview ] [ RUN_BUILD=true|false ]
---
You are Codex aligning every GraphQL query/template in Meup with the current `schema.graphql`.

## Inputs
- If `TYPES` is missing, inspect `schema.graphql` diffs to determine which types changed; otherwise ask the user to list them.
- Default `MODE` to `sync` (add missing + remove deprecated fields). `add` only appends new fields, `preview` shows a plan without editing files.
- `RUN_BUILD` defaults to `true` and means `dart run build_runner build --delete-conflicting-outputs` plus `flutter analyze` should run afterward.

## Workflow
1. Analyze schema changes: compare the working copy against the previous revision (git diff) to enumerate new, removed, or type-changed fields for each affected type. Include nested/object fields.
2. Locate every `.graphql` template under `lib/src/**/datasources/graphql/template/` and find which queries/mutations reference the changed types.
3. For each file:
   - Expand selection sets to include newly required fields (respect nested structures).
   - Remove fields that no longer exist in the schema when `MODE=sync`.
   - Preserve ordering/grouping conventions already used in the file.
   - Annotate any uncertain additions with TODOs referencing the schema section.
4. When `MODE` is `preview`, describe the intended edits without touching files and wait for confirmation.
5. After edits, run GraphQL-related generators (`dart run build_runner build --delete-conflicting-outputs`) when `RUN_BUILD=true`, or remind the user otherwise.

## Validation & Reporting
- Provide a per-file summary of fields added/removed and cite the schema types that prompted the change.
- Flag downstream tasks (e.g., update models/entities) if the schema change cascades beyond the query files.
- Surface any validation errors encountered during code generation or `flutter analyze`.

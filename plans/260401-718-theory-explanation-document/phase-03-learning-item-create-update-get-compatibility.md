## Context Links
- `docs/718-theory-explanation-document.md`
- `plans/2026-04-01-718-theory-explanation-document/plan.md`

## Overview
- Priority: Medium
- Status: Completed
- Brief description: Ensure learning-item create, update, and get flows accept and return explanation documents without changing response shape.

## Key Insights
- `learning_item` persistence uses `SchemaTypes.Array` / `Mixed`, so the main backend risk is validation and serialization, not schema migration.
- `findOne` currently hydrates tags at theory block level only; explanation documents do not need extra hydration.
- Service logic for exercise IDs should remain untouched by this theory-only change.

## Requirements
- Accept explanation documents in create and update payloads.
- Return explanation documents unchanged in get detail/list responses.
- Do not alter `documents[]` ordering or theory block shape.
- Keep compatibility for legacy theory documents.

## Architecture
- Controller and service entrypoints stay the same.
- Repository and schema remain structurally compatible because `documents` is already stored as array/mixed content.
- No migration step is required for existing records.

## Related Code Files
- Modify:
  - `src/modules/courses/src/modules/learning-item/learning-item.service.ts`
  - `src/modules/courses/src/modules/learning-item/learning-item.controller.ts`
  - `src/modules/courses/src/modules/learning-item/schema/learning-item.schema.ts`
  - `src/modules/courses/src/modules/learning-item/repository/learning-item.repository.ts`
- Create:
  - none
- Delete:
  - none

## Implementation Steps
1. Verify create/update paths accept new nested DTO shape with no extra service branching.
2. Confirm schema typing and repository read/write paths need no structural migration.
3. Keep `findOne` tag hydration at theory block level only.
4. Add minimal inline comments where explanation payload semantics are not obvious.

## Todo List
- [x] Review create flow impact
- [x] Review update flow impact
- [x] Review get detail flow impact
- [x] Confirm no repository migration needed
- [x] Keep service logic unchanged because DTO validation and existing mixed-array persistence are sufficient

## Success Criteria
- Existing theory payloads still persist normally.
- New explanation documents round-trip through create/update/get unchanged.
- No unintended changes to exercise or roleplay behavior.

## Risk Assessment
- Over-editing service logic could introduce regressions unrelated to theory documents.
- Mixed content arrays may mask validation issues if DTO wiring is incomplete.

## Security Considerations
- No new permission surface.
- Rely on DTO validation to block malformed nested arrays before persistence.

## Next Steps
- Add focused tests and rollout notes.

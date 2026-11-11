# Phase 01: Audit and Rename Document Data Typing

## Context Links
- PRD: [docs/718-theory-form-explanation-document-type.md](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/docs/718-theory-form-explanation-document-type.md)
- Main form: [TheoryForm.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/theories/TheoryForm.tsx)
- Shared type: [document.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/learning-item/document.interface.ts)

## Overview
- Priority: High
- Status: Completed
- Goal: remove remaining `IMediaDocument` references and align helper naming with `IDocumentData`.

## Key Insights
- Remaining `IMediaDocument` usages exist in theory, exercise, and roleplay forms.
- `IDocumentData` already includes `options`, so old "media" naming is now misleading.
- Rename is type-level only; runtime payload shape must stay backward compatible.

## Requirements
- Replace all imports/usages of `IMediaDocument` with `IDocumentData`.
- Update helper type aliases like `keyof IMediaDocument`.
- Rename local helper factories where practical to avoid semantic drift.
- Leave runtime behavior unchanged outside planned `EXPLANATION` support.

## Architecture
- Shared document typing remains centralized in `document.interface.ts`.
- Consumer forms continue mutating `IDocument.data`, but now via `IDocumentData`.
- No API contract change; only frontend type normalization.

## Related Code Files
- Modify: [TheoryForm.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/theories/TheoryForm.tsx)
- Modify: [ExerciseForm.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/exercises/ExerciseForm.tsx)
- Modify: [RoleplayFromDetail.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/roleplays/RoleplayFromDetail.tsx)
- Read only: [document.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/learning-item/document.interface.ts)

## Implementation Steps
1. Replace type imports from `IMediaDocument` to `IDocumentData`.
2. Rename local aliases and factory helpers to `document data` naming.
3. Update function signatures using `keyof IMediaDocument` to `keyof IDocumentData`.
4. Verify no stale `IMediaDocument` references remain in `src/`.

## Todo List
- [x] Rename imports in all affected files
- [x] Rename local helper/type aliases
- [x] Verify search for `IMediaDocument` returns zero results

## Success Criteria
- All frontend code compiles against `IDocumentData`.
- No behavior change introduced by rename-only edits.
- Verified in `TheoryForm`, `ExerciseForm`, and `RoleplayFromDetail`.

## Risk Assessment
- Risk: rename leaks into logic changes unintentionally.
- Mitigation: keep this phase scoped to type/helper names only.

## Security Considerations
- No auth or sensitive data impact.

## Next Steps
- Hand off to Phase 02 for `EXPLANATION` UI and payload logic.
 - Completed.

## Unresolved Questions
- None.

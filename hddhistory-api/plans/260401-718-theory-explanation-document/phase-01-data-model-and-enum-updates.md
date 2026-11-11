## Context Links
- `docs/718-theory-explanation-document.md`
- `plans/2026-04-01-718-theory-explanation-document/plan.md`

## Overview
- Priority: High
- Status: Completed
- Brief description: Update enum and interface layer so theory explanation content is first-class in the backend model.

## Key Insights
- Existing theory block shape already works for ordered content composition.
- The change belongs at `IDocument` level, not `ITheoryDocument` level.
- `IMediaDocument` is no longer semantically correct once `options` is added.

## Requirements
- Add `EXPLANATION` to `DocumentType`.
- Rename `IMediaDocument` to `IDocumentData`.
- Add `IExplanationOption { id, value, explanation }`.
- Add `options?: IExplanationOption[]` to `IDocumentData`.
- Keep `ITheoryDocument` unchanged.

## Architecture
- `learning_item.documents[]` remains an array of theory blocks.
- Each theory block still owns `document[]`.
- Explanation behavior is determined by `document.type = explanation`.
- `document.data.content` is the prompt/title; `document.data.options` is the selectable explanation list.

## Related Code Files
- Modify:
  - `src/modules/courses/src/modules/learning-item/enum/learning-item.enum.ts`
  - `src/modules/courses/src/modules/learning-item/interface/document.interface.ts`
  - `src/modules/courses/src/modules/learning-item/interface/theories/theory.interface.ts`
- Create:
  - none
- Delete:
  - none

## Implementation Steps
1. Add `EXPLANATION` to `DocumentType`.
2. Replace `IMediaDocument` with `IDocumentData`.
3. Introduce `IExplanationOption`.
4. Update `IDocument.data` typing to use `IDocumentData`.
5. Verify theory interfaces and schema typings still compile without top-level payload changes.

## Todo List
- [x] Add new enum member
- [x] Rename interface
- [x] Add explanation option type
- [x] Wire new data type into `IDocument`
- [x] Check compile impact from renamed interface

## Success Criteria
- Type layer expresses explanation documents without using `any`.
- No top-level theory payload changes are required.
- Import graph is updated cleanly after rename.

## Risk Assessment
- Widespread interface rename may leave stale imports.
- Shared `IDocument` usage outside theory may need harmless typing updates.

## Security Considerations
- No auth or permission changes.
- Validation remains the primary protection against malformed nested payloads.

## Next Steps
- Move to DTO validation and Swagger updates once interfaces compile cleanly.

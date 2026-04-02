# Phase 02: Implement Theory Form Explanation Document Editor

## Context Links
- PRD: [docs/MEUP-718-theory-form-explanation-document-type.md](/Users/macbook/Documents/eUp Group/admin-ai-tutor/docs/MEUP-718-theory-form-explanation-document-type.md)
- Form implementation: [TheoryForm.tsx](/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/pages/theories/TheoryForm.tsx)
- Shared type: [document.interface.ts](/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/types/interface/learning-item/document.interface.ts)

## Overview
- Priority: Highest
- Status: Completed
- Goal: add full create/edit/save/preview support for `DocumentType.EXPLANATION`.

## Key Insights
- Current form splits document handling into textual branch and media branch.
- `EXPLANATION` needs both translation content and nested translation options, so it needs a dedicated render path.
- Existing `cleanDocumentItems` only considers text/media completeness; it must be extended to explanation-specific validity.

## Requirements
- Add `EXPLANATION` to the document type selector.
- When type is `EXPLANATION`, render:
  - `content` textarea backed by current language in `ITranslation`
  - repeatable option blocks with `value` and `explanation`
  - add/remove option controls
- On type switch:
  - switching to `EXPLANATION` resets data to default explanation-safe shape
  - switching away clears `options` by resetting to the target type default shape
- Save behavior:
  - keep explanation docs when `content` has value, even if `options` is empty
  - remove explanation options whose `value` and `explanation` are both empty after clean
  - omit empty `url` and `thumbnail`
- Preview behavior:
  - show explanation content summary
  - show valid option count

## Architecture
- Add explanation-specific helper functions inside `TheoryForm`:
  - create default document data
  - create empty explanation option
  - clean explanation options
  - count valid options for preview
- Keep existing modal flow and payload conversion flow unchanged.
- Extend `cleanDocumentItems` rather than adding separate submit pipeline.

## Related Code Files
- Modify: [TheoryForm.tsx](/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/pages/theories/TheoryForm.tsx)
- Read only: [theory.interface.ts](/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/types/interface/learning-item/theories/theory.interface.ts)
- Read only: [course.enum.ts](/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/utils/enum/course.enum.ts)

## Implementation Steps
1. Replace default document data factory with a name and shape suitable for both media and explanation documents.
2. Add explanation option helpers:
   - create option with stable numeric `id`
   - update option `value`
   - update option `explanation`
   - remove option by index
3. Extend document type dropdown with `EXPLANATION`.
4. Add dedicated render branch for `DocumentType.EXPLANATION`.
5. Extend `handleDocumentChange` to reset data correctly on type switch.
6. Extend `handleDataChange` typing to allow `options`.
7. Update `cleanDocumentItems` to clean explanation content and options.
8. Update document list preview to render explanation summary and option count.

## Todo List
- [x] Add `EXPLANATION` option to selector
- [x] Add explanation content textarea
- [x] Add add/edit/remove option controls
- [x] Clean explanation options before submit
- [x] Render explanation preview in document list

## Success Criteria
- Editor can create and edit explanation documents end to end.
- Saved payload contains cleaned `content` and optional cleaned `options`.
- Existing document types still work unchanged.
- Added empty-state guidance when explanation has zero options.

## Risk Assessment
- Risk: nested option updates make form state brittle.
- Mitigation: isolate option mutations in small helpers and reuse translation helpers.
- Risk: type switch leaves stale fields behind.
- Mitigation: always reset full `data` object on type change.

## Security Considerations
- Inputs remain plain text/translation values; no new HTML handling.
- Do not trust client validation alone; keep payload cleaning strict.

## Next Steps
- Move to Phase 03 for compile, targeted testing, review, and docs sync.
 - Completed.

## Unresolved Questions
- None.

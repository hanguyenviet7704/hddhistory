# MEUP-718 Plan

## Overview
- Task: add `DocumentType.EXPLANATION` support in theory documents and finish `IMediaDocument -> IDocumentData` rename.
- Priority: High
- Status: Completed
- Plan dir: `plans/20260401-1706-meup-718-theory-explanation-document-type`

## Phase Status
- Phase 01: Completed - typing audit and rename
- Phase 02: Completed - `TheoryForm` explanation editor and payload handling
- Phase 03: Completed - validation and review

## Context Links
- PRD: [docs/MEUP-718-theory-form-explanation-document-type.md](/Users/macbook/Documents/eUp Group/admin-ai-tutor/docs/MEUP-718-theory-form-explanation-document-type.md)
- Phase 01: [phase-01-audit-and-rename-document-data-typing.md](/Users/macbook/Documents/eUp Group/admin-ai-tutor/plans/20260401-1706-meup-718-theory-explanation-document-type/phase-01-audit-and-rename-document-data-typing.md)
- Phase 02: [phase-02-implement-theory-form-explanation-document-editor.md](/Users/macbook/Documents/eUp Group/admin-ai-tutor/plans/20260401-1706-meup-718-theory-explanation-document-type/phase-02-implement-theory-form-explanation-document-editor.md)
- Phase 03: [phase-03-validate-compile-review-and-doc-sync.md](/Users/macbook/Documents/eUp Group/admin-ai-tutor/plans/20260401-1706-meup-718-theory-explanation-document-type/phase-03-validate-compile-review-and-doc-sync.md)

## Key Decisions
- `EXPLANATION` uses dedicated UI branch, not shared textual branch.
- `content` alone is sufficient for valid `EXPLANATION`; `options` remain optional.
- Preview shows explanation content summary plus valid option count, not full option list.
- Rename `IMediaDocument` to `IDocumentData` everywhere still referenced in frontend.

## Dependencies
- Existing `DocumentType.EXPLANATION` enum.
- Existing `IDocumentData` and `IExplanationOption` interfaces.
- Existing translation helpers in `src/utils/translation.ts`.

## Success Signal
- Theory editor can create/edit/save explanation documents with cleaned payload.
- Repo compiles after type rename with no lingering `IMediaDocument` references.
- `npm run build` passes.
- `npm test -- --watchAll=false` passes.

## Unresolved Questions
- None. Plan assumes `content`-only explanation documents are valid.

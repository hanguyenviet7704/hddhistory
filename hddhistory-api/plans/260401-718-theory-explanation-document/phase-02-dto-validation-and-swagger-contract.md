## Context Links
- `docs/718-theory-explanation-document.md`
- `plans/2026-04-01-718-theory-explanation-document/plan.md`

## Overview
- Priority: High
- Status: Completed
- Brief description: Make request validation and Swagger contract explicitly support explanation documents.

## Key Insights
- The main correctness risk is nested conditional validation on `DocumentDto.data`.
- Swagger must show `explanation` and `options` clearly or client integration will drift.
- DTO naming should match interface naming to reduce confusion.

## Requirements
- Rename `MediaDto` to `DocumentDataDto`.
- Add `ExplanationOptionDto`.
- Add `options` field to `DocumentDataDto`.
- Make `options` required when `type = explanation`.
- Keep `options` absent or ignored for other document types.

## Architecture
- `DocumentDto` remains the entry point for nested theory content.
- Conditional validation belongs at DTO level because payload rules depend on `document.type`.
- Swagger examples should include one normal document and one explanation document.

## Related Code Files
- Modify:
  - `src/modules/courses/src/modules/learning-item/dto/document.dto.ts`
  - `src/modules/courses/src/modules/learning-item/dto/theories/theory.dto.ts`
  - `src/modules/courses/src/modules/learning-item/dto/create-learning-item.dto.ts`
  - `src/modules/courses/src/modules/learning-item/dto/update-learning-item.dto.ts`
- Create:
  - none
- Delete:
  - none

## Implementation Steps
1. Rename `MediaDto` to `DocumentDataDto`.
2. Create `ExplanationOptionDto` with nested multilingual validation.
3. Add `options` array to `DocumentDataDto`.
4. Implement validation rule for `type = explanation`.
5. Update Swagger decorators, examples, and descriptions to document the new type clearly.

## Todo List
- [x] Rename DTO class
- [x] Add nested option DTO
- [x] Add `options` field
- [x] Add conditional validation for explanation documents
- [x] Update Swagger decorators for the new DTO shape

## Success Criteria
- Invalid explanation payloads are rejected at DTO layer.
- Swagger clearly documents `DocumentType.EXPLANATION` and nested option shape.
- Existing non-explanation documents remain valid.

## Risk Assessment
- Class-validator conditional rules can become brittle if based on the wrong nesting context.
- Swagger examples may drift if not updated in every affected DTO.

## Security Considerations
- Reject malformed nested translation objects early.
- Keep payload shape explicit to reduce unsafe downstream assumptions.

## Next Steps
- Move to service-path verification for create, update, and get flows.

---
title: "Plan - #718 theory explanation document"
status: completed
priority: P1
created: 2026-04-01
owner: backend
---

## Goal
- Add `DocumentType.EXPLANATION` for theory content.
- Rename `IMediaDocument` to `IDocumentData`.
- Extend theory `IDocument.data` with `options` for explanation content.
- Keep `ITheoryDocument` and top-level `documents` payload unchanged.

## Scope
- In scope: enum, interfaces, DTOs, validation, Swagger, learning-item API compatibility, tests, docs sync.
- Out of scope: scoring, correctness logic, new learning-item type, DB migration/backfill, frontend implementation.

## Phase Status
- [x] Phase 01: Data model and enum updates
- [x] Phase 02: DTO validation and Swagger contract
- [x] Phase 03: Learning-item create/update/get compatibility
- [x] Phase 04: Tests and rollout checklist

## Key Decisions
- Theory stays `learning_item.type = theory`.
- Theory block shape stays `{ id, tagId, document[] }`.
- New behavior is modeled as `document.type = explanation`.
- `IDocumentData.content` acts as prompt/title for explanation documents.
- `IDocumentData.options` stores `{ id, icon?, value, explanation }[]`, where `icon` may be `null` or empty.
- No `isCorrect`, `maxScore`, `exerciseId`, `level`, or `mainQuestion`.

## Related Files (expected)
- `docs/718-theory-explanation-document.md`
- `src/modules/courses/src/modules/learning-item/enum/learning-item.enum.ts`
- `src/modules/courses/src/modules/learning-item/interface/document.interface.ts`
- `src/modules/courses/src/modules/learning-item/dto/document.dto.ts`
- `src/modules/courses/src/modules/learning-item/interface/theories/theory.interface.ts`
- `src/modules/courses/src/modules/learning-item/dto/theories/theory.dto.ts`
- `src/modules/courses/src/modules/learning-item/dto/create-learning-item.dto.ts`
- `src/modules/courses/src/modules/learning-item/dto/update-learning-item.dto.ts`
- `src/modules/courses/src/modules/learning-item/schema/learning-item.schema.ts`
- `src/modules/courses/src/modules/learning-item/learning-item.service.ts`

## Risks
- `MediaDto` -> `DocumentDataDto` rename can ripple through imports and Swagger examples.
- Conditional validation for `type = explanation` can be bypassed if DTO nesting is not wired correctly.
- Older clients may ignore `type = explanation` until frontend rollout is complete.

## Resolved Decisions
- No top-level `kind` on theory blocks.
- No schema migration required in phase 1.
- `options` is only valid for `DocumentType.EXPLANATION`.

## Verification
- `npm run build` passed on 2026-04-01.
- `npm run lint` passed on 2026-04-01.
- `swagger-spec.json` was not regenerated because app bootstrap stops on local MySQL connection failure before Swagger file generation.

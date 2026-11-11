---
title: "Excel Import Keypoint Theory Exercise"
status: approved
priority: P1
created: 2026-05-06
---

# Excel Import Keypoint Theory Exercise

## Scope

Implement backend Excel import APIs for:

- keypoints
- learning item theories
- learning item exercises

## Decisions

- Keypoint import reads only `keypoints` sheet and returns an Excel file in the same columns as the keypoint template.
- Theory import reads `theories`, `theory_documents`, `theory_explanation_options`.
- Exercise import reads `exercises`, `exercise_documents`, `exercise_options`, `exercise_document_groups`.
- Output Excel keeps media cells as originally entered. It only fills created row `id`.
- No status/message columns in returned Excel.
- Validate whole workbook first. If invalid, return JSON error and do not write partial DB data.
- Existing `id` means update. Empty `id` means create.
- Update only fields represented by Excel columns. Preserve fields not in Excel such as `status`, `index`, old `exerciseId`.
- If update has child rows, replace rebuilt nested `documents`/`questions`; if no child rows, keep old nested data.
- Nested numeric ids are auto-filled from 1 upward.
- Media filenames are resolved to CDN URLs for DB only. Existing full URLs are preserved.

## Implementation Steps

1. Add shared Excel import helpers for workbook read/write, row extraction, media URL resolution, document building, and validation errors.
2. Add keypoint import service/controller endpoint.
3. Add theory import service/controller endpoint.
4. Add exercise import service/controller endpoint.
5. Fix `DragDropAnswerDto` to use `correctAnswer`.
6. Run TypeScript build.

## Validation

- `npm run build`
- Manual code review of import mapping and update semantics.

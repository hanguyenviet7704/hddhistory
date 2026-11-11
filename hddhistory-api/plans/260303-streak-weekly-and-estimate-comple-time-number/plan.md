---
title: "Plan - Weekly streak + estimateCompleTimeNumber (minutes)"
status: in_progress
priority: P1
created: 2026-03-03
owner: backend
---

## Goal
- Implement streak logic with weekly UI state and auto-lower on `GET streak` when user misses day.
- Add numeric `estimateCompleTimeNumber` (minutes) to `lesson` and `keypoint`.
- Keep code easy to read/maintain via explicit column comments and logic comments.

## Scope
- In scope: data model, streak compute flow, migration/backfill strategy, API adjustments, tests.
- Out of scope: UI redesign, notification scheduler, historical analytics.

## Phase Status
- [x] Phase 01: Data model and schema update
- [x] Phase 02: Streak compute flow (`GET` + completion updates)
- [ ] Phase 03: `estimateCompleTimeNumber` migration/backfill
- [x] Phase 04: API contract + validation + docs
- [x] Phase 05: Test cases and rollout checklist
- [x] Phase 06: Refactor `user-streak` to standalone module (parallel to `user-progress`)

## Key Decisions
- Keep one streak record per user.
- Keep weekly state fields: `weekStartDate`, `weekStudy`, `studyTime`.
- Keep cross-week fields: `currentStreak`, `bestStreak`.
- Do not persist `lastActiveDay`; infer last completion date from `weekStartDate + weekStudy`.
- `estimateCompleTimeNumber` is numeric minutes, source of truth for time calculation.

## Related Files (expected)
- `src/modules/courses/src/modules/progress/src/modules/user-progress/user-progress.service.ts`
- `src/modules/courses/src/modules/progress/src/modules/user-streak/*`
- `src/modules/courses/src/modules/progress/src/modules/progress.module.ts`
- `src/modules/courses/src/modules/lesson/schema/lesson.schema.ts`
- `src/modules/courses/src/modules/keypoint/schema/keypoint.schema.ts`
- `src/modules/courses/src/modules/lesson/dto/*`
- `src/modules/courses/src/modules/keypoint/dto/*`

## Risks
- Infer-last-day logic can be wrong if week reset order is incorrect.
- Existing `estimateCompleTime` text values are inconsistent for parsing.
- Duplicate completion events may inflate `studyTime` if idempotency not handled.

## Resolved Decisions
- Repeated completion in same day does not increase `currentStreak` again, but still adds `studyTime` by `estimateCompleTimeNumber` per completion event.
- Learning completion does not require `passed=true`; only update event is needed:
  - Lesson grade: `ROLEPLAY`/`OUTPUT` with valid `lessonId`.
  - Keypoint grade: keypoint items with valid `keypointId`.

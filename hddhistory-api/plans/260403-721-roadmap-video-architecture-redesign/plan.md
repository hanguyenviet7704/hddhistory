---
title: "Plan - Roadmap video lesson architecture"
status: proposed
priority: P1
created: 2026-04-03
owner: backend
---

## Goal
- Add `LessonType.VIDEO` with minimal roadmap and client disruption.
- Support `video: { url, thumbnail, summary }` for video lessons.
- Keep roadmap node structure mostly unchanged by adding only 2 fixed video slots.
- Move per-user video note/watch/answer state to a separate collection.
- Move timed video questions to `learning_item`.

## Scope
- In scope: lesson enum/model updates, fixed roadmap video slots, learning-item timed video questions, per-user activity model, API plan, verification plan.
- Out of scope: frontend player implementation, media upload pipeline, analytics dashboard, recommendation engine.

## Phase Status
- [ ] Phase 01: Video lesson type and lesson data model
- [ ] Phase 02: Roadmap node fixed video slots
- [ ] Phase 03: Learning-item timed video questions for video lessons
- [ ] Phase 04: User video lesson activity model
- [ ] Phase 05: Tests and rollout

## Key Decisions
- Add `LessonType.VIDEO`.
- Keep existing lesson `description`.
- Add `video: { url, thumbnail, summary }`.
- Do not add `thumbnail` in phase 1.
- Keep roadmap node shape and add only `openingVideoId` and `closingVideoId`.
- Timed video questions move to `learning_item`, not roadmap.
- Per-user video state uses a separate collection keyed by video lesson id.

## Related Files (expected)
- `docs/roadmap-node-video-redesign.md`
- `src/modules/courses/src/modules/lesson/enum/lesson.enum.ts`
- `src/modules/courses/src/modules/lesson/interface/lesson.interface.ts`
- `src/modules/courses/src/modules/lesson/dto/create-lesson.dto.ts`
- `src/modules/courses/src/modules/lesson/schema/lesson.schema.ts`
- `src/modules/courses/src/modules/course/interface/roadmap.interface.ts`
- `src/modules/courses/src/modules/course/dto/create-roadmap.dto.ts`
- `src/modules/courses/src/modules/course/schema/roadmap.schema.ts`
- `src/modules/courses/src/modules/course/course.service.ts`
- `src/modules/courses/src/modules/learning-item/*`
- new user-video-lesson activity module files

## Risks
- Fixed `opening/closing` slots only support 2 videos per node.
- `video.summary` contains HTML text and requires sanitization.
- Learning-item timed video questions need a clean contract to avoid mixing lesson-only semantics.
- Need a clear rule for whether video lessons count toward course progress in phase 1.

## Verification
- Verify lesson DTO/schema compile with `LessonType.VIDEO`.
- Verify roadmap read/write works with `openingVideoId` and `closingVideoId`.
- Verify lesson deletion cleans up the 2 video slots.
- Verify per-user video activity writes do not affect roadmap static data.

## Open Questions
- Is `video.summary` required for video lessons or optional?
- Do video lessons allow `keypoints[]` in phase 1?
- Do video lessons count toward course progress in phase 1?

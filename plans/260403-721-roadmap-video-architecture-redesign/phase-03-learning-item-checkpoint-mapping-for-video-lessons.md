## Context Links
- `docs/roadmap-node-video-redesign.md`
- `plans/2026-04-03-roadmap-video-architecture-redesign/plan.md`

## Overview
- Priority: High
- Status: In Progress
- Brief description: Represent timed video questions in `learning_item` instead of roadmap or lesson schema.

## Key Insights
- Product wants timed questions moved out of roadmap.
- Video lesson already has `learningItemId`, which is the right bridge.
- `ExerciseInput` already covers the supported interactive payload shapes.

## Requirements
- Support mapping from timestamp to exercise.
- Reuse `ExerciseInput` instead of inventing a parallel question schema.
- Avoid duplicating timed question payload in lesson or roadmap.

## Architecture
- Add `videoQuestions[]` to learning item.
- Each video question contains:
  - `atSecond`
  - `exercise`
- `exercise` reuses `ExerciseInput`.

## Related Code Files
- Modify:
  - `src/modules/courses/src/modules/learning-item/interface/learning-item.interface.ts`
  - `src/modules/courses/src/modules/learning-item/dto/create-learning-item.dto.ts`
  - `src/modules/courses/src/modules/learning-item/dto/update-learning-item.dto.ts`
  - `src/modules/courses/src/modules/learning-item/schema/learning-item.schema.ts`
  - `src/modules/courses/src/modules/learning-item/learning-item.service.ts`
- Create:
  - `src/modules/courses/src/modules/learning-item/dto/videos/video-question.dto.ts`
  - `src/modules/courses/src/modules/learning-item/interface/videos/video-question.interface.ts`
- Delete:
  - old checkpoint DTO/interface files if unused

## Implementation Steps
1. Define `IVideoQuestion` in learning item.
2. Add DTO support for `videoQuestions[]`.
3. Reuse `ExerciseInput` in each `videoQuestions[].exercise`.
4. Ensure nested video question exercises also receive `exerciseId`.

## Todo List
- [x] Define video question contract
- [x] Add DTO support
- [x] Add schema field
- [x] Reuse `ExerciseInput`
- [x] Ensure `exerciseId` generation for `videoQuestions`

## Success Criteria
- Timed video questions are fully represented in learning item.
- Roadmap and lesson schemas stay lighter.
- Video player can resolve timestamps to full exercise payload from the linked learning item.

## Risk Assessment
- Weak validation can allow malformed nested exercises.
- Mixed semantics between lesson exercise and video question flows can drift.

## Security Considerations
- Validate nested video question payloads strictly enough for current exercise union.
- Prevent invalid `atSecond` values from being persisted.

## Next Steps
- Add per-user activity model for notes and answers.

# Phase 02 - Backend Daily Warm-up API

## Context Links

- Progress controller: `src/modules/courses/src/modules/progress/src/modules/user-progress/user-progress.controller.ts`
- Progress service: `src/modules/courses/src/modules/progress/src/modules/user-progress/user-progress.service.ts`
- Progress repository: `src/modules/courses/src/modules/progress/src/modules/user-progress/repository/user-progress.repository.ts`
- Learning item repository: `src/modules/courses/src/modules/learning-item/repository/learning-item.repository.ts`
- Progress module: `src/modules/courses/src/modules/progress/src/modules/user-progress/user-progress.module.ts`
- Learning item module: `src/modules/courses/src/modules/learning-item/learning-item.module.ts`

## Overview

- Priority: High
- Status: Pending
- Goal: Add API that returns up to 3 Daily Warm-up exercise questions from the latest keypoint a user studied.

## Key Insights

- Daily Warm-up is user-wide; the client does not pass `courseId`.
- `user_progress` already has `{ userId: 1, courseId: 1 }` index, but this endpoint should add/use a `{ userId: 1 }` index.
- Latest keypoint should be based on `keypointsResult.submittedAt`, not top-level `lastTime`, because the feature needs a specific keypoint.
- `exercisesResult.exerciseId` can be matched against `learning_item.questions.exerciseId`.
- `LearningItemRepository` is exported by `LearningItemModule`; import that module into `UserProgressModule` via `forwardRef`.

## Requirements

- Add endpoint `GET /courses-user-progress/daily-warm-up`.
- Use authenticated `requestService.user` for `userId`.
- Return `questions: []` when no progress, no latest keypoint, or no flagged attempted questions.
- Return `isCourseCompleted` from whether the user passed the last keypoint of the current course.
- Return `suggestedCourseId`: current `courseId` when keypoint is not completed; otherwise a random published course from the same skillset, falling back to current course.
- Randomly return max 3 eligible questions.
- Only include questions where:
  - learning item `type === LearningItemType.EXERCISE`
  - learning item `keypointId` equals latest studied keypoint
  - question `exerciseId` is in latest keypoint `exercisesResult`
  - question `isDailyWarmUp === true`

## Architecture

Repository methods:

```ts
UserProgressRepository.findLatestStudiedKeypoint(userId)
LearningItemRepository.findDailyWarmUpQuestions(keypointId, exerciseIds)
```

Service flow:

1. Resolve `userId` from auth context.
2. Aggregate latest keypoint from all progress documents of that user.
3. Build attempted `exerciseId` set.
4. Fetch eligible Daily Warm-up questions from `learning_item`.
5. Resolve `isCourseCompleted` and `suggestedCourseId`.
6. Shuffle with Fisher-Yates and return first 3.

## Related Code Files

- Create: `src/modules/courses/src/modules/progress/src/modules/user-progress/dto/get-daily-warm-up.dto.ts`
- Create: `src/modules/courses/src/modules/progress/src/modules/user-progress/interface/daily-warm-up.interface.ts`
- Modify: `src/modules/courses/src/modules/progress/src/modules/user-progress/user-progress.controller.ts`
- Modify: `src/modules/courses/src/modules/progress/src/modules/user-progress/user-progress.service.ts`
- Modify: `src/modules/courses/src/modules/progress/src/modules/user-progress/repository/user-progress.repository.ts`
- Modify: `src/modules/courses/src/modules/progress/src/modules/user-progress/user-progress.module.ts`
- Modify: `src/modules/courses/src/modules/learning-item/repository/learning-item.repository.ts`
- Modify: `src/modules/courses/src/modules/learning-item/schema/learning-item.schema.ts`

## Implementation Steps

1. Add `LearningItemModule` import to `UserProgressModule`.
2. Inject `LearningItemRepository` into `UserProgressService`.
3. Add repository aggregation to find latest keypoint:

```ts
[
  { $match: { userId } },
  { $unwind: '$lessonsResult' },
  { $unwind: '$lessonsResult.keypointsResult' },
  { $sort: { 'lessonsResult.keypointsResult.submittedAt': -1 } },
  { $limit: 1 },
  {
    $project: {
      lessonId: '$lessonsResult.lessonId',
      courseId: 1,
      keypoint: '$lessonsResult.keypointsResult',
    },
  },
]
```

4. Add learning item repository query:

```ts
find({
  keypointId,
  type: LearningItemType.EXERCISE,
  'questions.exerciseId': { $in: exerciseIds },
  'questions.isDailyWarmUp': true,
})
.select('_id keypointId questions')
.lean()
```

5. Filter questions in service to exactly match `exerciseId` and `isDailyWarmUp`.
6. Randomize and cap to 3.
7. Add controller route before parameterized routes to avoid path collision.

## Todo List

- [ ] Interface created
- [ ] UserProgress repository aggregation added
- [ ] LearningItem repository query added
- [ ] Service method added
- [ ] Suggested course logic added
- [ ] Controller endpoint added
- [ ] Module dependency wired
- [ ] Learning item index added

## Success Criteria

- API returns 0 to 3 eligible questions for the authenticated user.
- If the latest keypoint has 5 attempted flagged questions, each request returns a random 3.
- If it has 3 or fewer, API returns all eligible questions.
- If it has none, API returns `questions: []`.
- No database access occurs outside repository layer.

## Risk Assessment

- `requestService.user` shape must be checked during implementation for the correct user id field.
- Path order matters because controller has `GET /users/:userId` routes.

## Security Considerations

- Use authenticated user by default to prevent reading another user's progress.
- Do not expose answers differently from existing learning-item API unless product requires hiding answer data.

## Next Steps

- Validate with local sample progress and build.

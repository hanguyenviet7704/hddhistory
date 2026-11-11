# Daily Warm-up Implementation Plan

## Status

- Phase 01: Pending - Data contract and admin flag
- Phase 02: Pending - API query and response
- Phase 03: Pending - Validation, docs, and rollout

## Context

- API repo: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api`
- Admin repo: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin`
- Main storage: MongoDB `learning_item.questions[]`, `learning_item.subQuestions[]`, `user_progress.lessonsResult[].keypointsResult[]`
- Current question identity: `exerciseId` on each exercise question

## Decision Summary

- Add a boolean field on each exercise question: `isDailyWarmUp?: boolean`.
- Only `learning_item.questions[]` is eligible for Daily Warm-up, matching the requirement. `subQuestions[]` stays out unless product confirms otherwise.
- API should find the most recently submitted keypoint for the authenticated user across all courses from `user_progress`, collect the attempted `exerciseId`s in that keypoint, then query `learning_item` for exercise questions in the same keypoint where `isDailyWarmUp === true` and `exerciseId` was attempted.
- If no eligible Daily Warm-up question exists, return an empty `questions` array.
- Randomization should happen after filtering eligible questions and cap at 3.

## Phases

1. [Phase 01 - Data Contract And Admin Flag](./phase-01-data-contract-and-admin-flag.md)
2. [Phase 02 - Backend Daily Warm-up API](./phase-02-backend-daily-warm-up-api.md)
3. [Phase 03 - Validation Docs And Rollout](./phase-03-validation-docs-and-rollout.md)

## Recommended API Shape

`GET /v1/courses-user-progress/daily-warm-up`

Response:

```ts
{
  keypointId: string;
  courseId: string;
  suggestedCourseId: string;
  lessonId: string;
  isCourseCompleted: boolean;
  submittedAt: string;
  questions: Array<{
    learningItemId: string;
    keypointId: string;
    question: ExerciseInput;
  }>;
}
```

`suggestedCourseId` rule:

- If latest keypoint is not completed, use current `courseId`.
- If latest keypoint is completed, choose one random published course in the same category.
- If no other published course exists in the same category, fallback to current `courseId`.

## Performance Notes

- Add `UserProgressSchema.index({ userId: 1 })` for the user-wide lookup.
- Keep the existing `{ userId: 1, courseId: 1 }` index for current course-specific APIs.
- Add `LearningItemSchema.index({ keypointId: 1, type: 1 })`.
- Query only `keypointId`, `type`, and `questions` from `learning_item`.
- Avoid scanning all progress in service code. Add repository aggregation for latest keypoint.

## Open Questions

- Should Daily Warm-up include `subQuestions[]` too, or only top-level `questions[]`?
- Should the endpoint use current authenticated user only, or allow `userId` query for admin/debug?

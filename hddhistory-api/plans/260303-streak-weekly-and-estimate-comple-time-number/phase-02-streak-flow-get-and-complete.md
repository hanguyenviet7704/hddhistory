## Context Links
- `plans/2026-03-03-streak-weekly-and-estimate-comple-time-number/plan.md`

## Overview
- Priority: High
- Status: Pending
- Purpose: Finalize exact streak update rules for `GET streak` and completion events.

## Core Logic
- `GET streak` must auto-lower streak if user missed day.
- Completion event updates streak and week flags.
- Week reset is lazy (triggered on GET/COMPLETE), not by cron.

## GET Streak Flow
1. Read streak record.
2. Infer `lastCompletedDate` from current stored `weekStartDate + weekStudy`.
3. Compute `gapDays` to today.
4. If `gapDays >= 2`, set `currentStreak = 0`.
5. If current week changed:
6. Reset `weekStudy` and `studyTime`.
7. Set new `weekStartDate`.
8. Persist and return.

## Completion Flow
1. Validate event type:
- Roleplay: `GradeResultType.LESSON` + `LessonType.ROLEPLAY`.
- Practice: `GradeResultType.LESSON` + `LessonType.OUTPUT`.
- Keypoint: `GradeResultType.KEYPOINT` + `LessonType.LESSON`.
2. Run same stale-week + missed-day check as GET.
3. Add `estimateCompleTimeNumber` into `studyTime`.
4. If today not yet marked in `weekStudy`:
5. If previous completed day is yesterday -> `currentStreak += 1`.
6. Else -> `currentStreak = 1`.
7. Mark today in `weekStudy`.
8. Update `bestStreak = max(bestStreak, currentStreak)`.

## Edge Cases
- Same-day repeated completion: no streak increase; time policy to confirm.
- First activity ever: initialize streak record and set `currentStreak = 1`.
- New week first completion on Monday after Sunday streak: must continue streak.

## Implementation Steps
1. Extract reusable helper methods (`inferLastDay`, `resetWeekIfNeeded`, `applyGapRule`).
2. Add explicit logic comments before each helper.
3. Wire helper into GET endpoint and completion update point.

## Success Criteria
- No false increase on same day.
- Correct reset after missed day.
- Correct continuation across week boundary when gap is 1 day.

## Risks
- Wrong ordering can wipe old week data before infer-last-day.

## Unresolved Questions
- Exact policy for repeated completion time accumulation in same day.

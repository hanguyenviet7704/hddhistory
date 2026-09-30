## Context Links
- `plans/2026-03-03-streak-weekly-and-estimate-comple-time-number/plan.md`

## Overview
- Priority: High
- Status: Pending
- Purpose: Define stable fields for weekly streak + cross-week streak + numeric estimate time.

## Requirements
- One streak record per user.
- Weekly fields for Home popup and weekly reset.
- Numeric minutes field on lesson/keypoint for time math.

## Proposed Data Structure
- `userId`: unique key.
- `weekStartDate`: Monday date (system timezone).
- `weekStudy`: 7 booleans (`Mon..Sun`).
- `studyTime`: total week minutes (or seconds, to confirm).
- `currentStreak`: cross-week streak count.
- `bestStreak`: historical max streak.

## Lesson/Keypoint Schema Change
- Add `estimateCompleTimeNumber: number` (minutes) to:
- `lesson.schema.ts`
- `keypoint.schema.ts`
- Keep old `estimateCompleTime` text for display/backward compatibility.

## Implementation Steps
1. Define streak schema/interface (single record per user).
2. Add indexes (`userId` unique).
3. Add `estimateCompleTimeNumber` to lesson/keypoint interfaces + DTOs + schema.
4. Add detailed comments for each new column.

## Commenting Standards (mandatory)
- On schema columns: explain unit, allowed values, reset behavior.
- On streak methods: explain why update order matters (`infer -> compare -> reset -> persist`).
- On estimate time: explain this numeric field is source of truth.

## Success Criteria
- New fields compile and expose correctly in create/update/get flows.
- Column comments make unit and behavior unambiguous.

## Risks
- Unit confusion (minutes vs seconds) if naming/comments not consistent.

## Unresolved Questions
- Confirm `studyTime` unit in streak record.

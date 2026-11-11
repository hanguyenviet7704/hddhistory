## Context Links
- `plans/2026-03-03-streak-weekly-and-estimate-comple-time-number/plan.md`

## Overview
- Priority: High
- Status: Completed
- Purpose: Move streak into dedicated module to reduce `user-progress` coupling and improve maintainability.

## Why Refactor
- `user-progress.service.ts` is large and now contains unrelated streak domain logic.
- Streak has its own schema/repository/rules and should be isolated.
- Future streak features (notification, leaderboard, analytics) should not touch progress internals.

## Target Architecture
- `progress/src/modules/user-progress/*`: progress domain only.
- `progress/src/modules/user-streak/*`: streak domain only.
- `user-progress` calls `UserStreakService.trackLearningCompletion(...)`.
- `GET streak` served by `UserStreakController`.

## Refactor Steps
1. Create `user-streak` module with service/controller/schema/repository/helper.
2. Move streak files from `user-progress` subtree to `user-streak` subtree.
3. Move streak methods from `UserProgressService` to `UserStreakService`.
4. Replace direct streak logic in `updateUserProgressResult` with service call.
5. Update `ProgressModule` imports so `user-streak` is sibling module.
6. Keep API backward compatibility for `/courses-user-progress/streak` (proxy) or move path with version note.
7. Run lint/build and verify swagger route ownership.

## Success Criteria
- `UserProgressService` no longer imports streak schema/repository/helper.
- Streak API and completion tracking still work without behavior change.
- Build/lint pass.

## Risks
- Circular dependency between progress and streak services if not wired carefully.
- API path change may break client if backward compatibility is removed.

## Unresolved Questions
- Keep `GET /courses-user-progress/streak` as legacy alias, or migrate client to new path immediately?

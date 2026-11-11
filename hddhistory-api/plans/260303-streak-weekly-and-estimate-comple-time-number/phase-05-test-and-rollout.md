## Context Links
- `plans/2026-03-03-streak-weekly-and-estimate-comple-time-number/plan.md`

## Overview
- Priority: High
- Status: Pending
- Purpose: Validate streak correctness and prevent regressions.

## Test Scenarios
1. First completion creates streak = 1.
2. Same day second completion does not increase streak.
3. Consecutive day completion increases streak.
4. Missed day then GET streak lowers to 0.
5. Missed day then completion resets to 1.
6. Cross-week Sunday -> Monday continuation keeps streak increment.
7. New week reset clears `weekStudy` and `studyTime`.
8. `bestStreak` only increases, never decreases.
9. Time accumulation uses `estimateCompleTimeNumber` only.

## Rollout Checklist
1. Run lint and compile checks.
2. Run migration dry-run and real run.
3. Verify streak values on seeded test users.
4. Verify API response shape on GET streak.
5. Monitor logs for parse fallback and data anomalies.

## Observability
- Log when week reset occurs.
- Log when invalid estimate data is encountered.
- Log when gap-based streak drop is applied.

## Success Criteria
- All streak scenarios pass.
- No production parse-from-text in runtime hot path.
- Team can debug quickly via explicit logs/comments.

## Risks
- Race conditions from concurrent completion requests.

## Unresolved Questions
- Do we need lightweight lock/idempotency guard on completion endpoint?

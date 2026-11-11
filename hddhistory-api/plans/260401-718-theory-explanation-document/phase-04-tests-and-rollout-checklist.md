## Context Links
- `docs/718-theory-explanation-document.md`
- `plans/2026-04-01-718-theory-explanation-document/plan.md`

## Overview
- Priority: High
- Status: Completed
- Brief description: Validate the new theory explanation document end-to-end and capture rollout constraints.

## Key Insights
- The highest-value tests are DTO validation and create/get round-trip behavior.
- No DB migration is required, but frontend rollout must understand `type = explanation`.
- Existing theory rendering should remain untouched for all old document types.

## Requirements
- Cover valid explanation payloads.
- Cover invalid explanation payloads.
- Confirm backward compatibility for old theory documents.
- Document rollout dependency on frontend renderer support.

## Architecture
- Test at DTO/service/API contract level.
- Keep tests focused on learning-item theory payload behavior.
- Rollout note should explicitly say backend can ship first, but frontend must ignore or render `explanation` safely.

## Related Code Files
- Modify:
  - `src/modules/courses/src/modules/learning-item/**/*`
  - `swagger-spec.json`
  - `docs/718-theory-explanation-document.md`
- Create:
  - `*.spec.ts` near modified learning-item DTO/service files if test harness exists
- Delete:
  - none

## Implementation Steps
1. Add tests for valid `DocumentType.EXPLANATION` payload.
2. Add tests for missing `options`, missing `value`, and missing `explanation`.
3. Add regression test for legacy theory documents without explanation type.
4. Run compile/lint/test commands relevant to the module.
5. Update docs/changelog if implementation changes shipped behavior.

## Todo List
- [ ] Valid explanation payload test
- [ ] Invalid explanation payload tests
- [ ] Legacy theory payload regression test
- [x] Compile and lint verification
- [x] Docs sync after implementation

## Success Criteria
- Valid explanation payload passes.
- Malformed explanation payload fails before service logic.
- Legacy theory payload remains valid.
- Swagger and docs match implementation.

## Risk Assessment
- Missing automated test harness may force manual verification for part of the rollout.
- Frontend lag can make the new type appear unsupported even when backend is correct.

## Security Considerations
- Ensure oversized nested arrays are still constrained by existing API protections.
- Do not expose internal validation traces beyond normal API error responses.

## Next Steps
- Implementation can start from Phase 01 and proceed sequentially through Phase 04.

## Verification Notes
- `npm run build` passed.
- `npm run lint` passed.
- No Jest/test runner is configured in this repo yet, so focused automated tests were not added or executed in this implementation pass.
- Attempted Swagger regeneration, but full app bootstrap is blocked by local MySQL connection failure (`127.0.0.1:3306`).

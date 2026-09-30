# Phase 03 - Validation Docs And Rollout

## Context Links

- API package scripts: `package.json`
- Admin package scripts: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/package.json`
- Project docs path: `docs/` may need to be created if documentation updates are required.

## Overview

- Priority: Medium
- Status: Pending
- Goal: Verify compile behavior, document API usage, and prepare rollout notes.

## Requirements

- Run API build after backend changes.
- Run admin build after UI/type changes.
- Manually verify API with seeded/local data.
- Update changelog/architecture docs if docs directory exists or create minimal docs if required by project policy.

## Validation Commands

API:

```bash
npm run build
npm run lint
```

Admin:

```bash
cd /Users/macbook/Documents/eUp\ Group/hddhistory-admin
npm run build
```

## Manual Test Matrix

- No user progress: returns empty `questions`.
- User has latest keypoint but no exercises: returns empty `questions`.
- Latest keypoint has attempted exercises but none flagged: returns empty `questions`.
- Latest keypoint has 1-3 flagged attempted questions: returns all.
- Latest keypoint has more than 3 flagged attempted questions: returns 3 random questions.
- Older keypoint has flagged questions but latest does not: returns empty `questions`.
- Flagged question was not attempted in `user_progress`: not returned.

## Documentation Updates

- Add changelog entry for Daily Warm-up API and admin flag.
- Document endpoint request/response.
- Document data field `questions[].isDailyWarmUp`.
- If Excel import column is added, document supported column names.

## Todo List

- [ ] API build passes
- [ ] API lint reviewed
- [ ] Admin build passes
- [ ] Manual API scenarios checked
- [ ] Docs/changelog updated if available

## Success Criteria

- Both repos compile.
- Endpoint behavior is deterministic except intended random selection.
- Existing learning-item create/update flows still work.

## Risk Assessment

- No Jest suite exists in API repo; rely on build plus focused manual checks unless tests are added.
- Admin repo is outside current writable root; implementation may require filesystem approval.

## Security Considerations

- Confirm endpoint does not allow cross-user reads.
- Avoid logging full question payloads or answers.

## Next Steps

- After plan approval, implement Phase 01 first, then Phase 02, then validation.

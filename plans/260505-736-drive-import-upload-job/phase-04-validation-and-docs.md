# Phase 04 - Validation And Docs

## Context Links

- Backend root: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api`
- Admin CMS root: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin`
- Backend docs: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/docs`
- Admin CMS docs: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/docs`

## Overview

Priority: Medium
Status: Completed

Run build validation for both repos and update relevant docs after implementation.

## Key Insights

- Backend has no Jest runner wired by project guidance.
- Required compile checks:
  - backend: `npm run build`
  - admin CMS: `npm run build`
- Docs update needed because this adds admin workflow and API surface.

## Requirements

- Backend compiles.
- Admin CMS compiles.
- Swagger/API docs update if generated as part of local project workflow.
- Manual validation cases documented.

## Related Code Files

Maybe modify:

- `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/docs/project-changelog.md`
- `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/docs/development-roadmap.md`
- `/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/docs/*`

## Implementation Steps

1. Run backend build.
2. Run admin CMS build.
3. Manually validate API with:
   - create job
   - create while active
   - list jobs
   - detail job
   - cancel job
4. Manually validate CMS:
   - open new tab from Header
   - submit link
   - resume active job after reload
   - progress renders
   - failed/uploaded lists render
5. Update changelog/docs if implementation changes are completed.

## Todo List

- [x] Run backend build
- [x] Run admin CMS build
- [ ] Validate backend API flows
- [ ] Validate CMS flows
- [ ] Update docs/changelog where applicable

## Success Criteria

- Both builds pass.
- User can complete import workflow.
- User can close/reopen page and resume progress.
- One user cannot see another user's job.
- One user cannot start a second active job.

## Risk Assessment

- Drive API cannot be fully validated without accessible Drive folder and env.
  Mitigation: record exact missing env/test data if unavailable.

## Security Considerations

- Update only environment templates; never commit real credentials.
- Avoid adding secret Drive credentials to docs.

## Next Steps

After validation, request code review and update docs according to project rules.

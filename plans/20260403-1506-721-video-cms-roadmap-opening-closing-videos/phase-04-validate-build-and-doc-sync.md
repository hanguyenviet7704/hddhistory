# Phase 04: Validate Build and Doc Sync

## Context Links
- PRD: [docs/721-video-cms-roadmap-opening-closing-videos.md](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/docs/721-video-cms-roadmap-opening-closing-videos.md)
- Plan: [plan.md](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/plans/20260403-1506-721-video-cms-roadmap-opening-closing-videos/plan.md)

## Overview
- Priority: High
- Status: Pending
- Goal: verify the final implementation compiles, the main flows work, and docs stay aligned.

## Key Insights
- The repo already has user edits in core type files, so validation must distinguish task changes from unrelated worktree changes.
- This ticket touches routing, sidebar navigation, roadmap editing, and hybrid persistence, so smoke coverage must span more than a single screen.

## Requirements
- Run compile validation after code changes.
- Run relevant tests if present or document gaps if not.
- Review for regressions in roadmap, lesson routing, and linked learning item persistence.
- Sync docs if implementation deviates from the current PRD or plan assumptions.

## Architecture
- Validation is layered:
  - type/build check
  - targeted runtime smoke paths
  - code review findings
  - docs reconciliation

## Related Code Files
- Read only: [CourseDetail.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/courses/CourseDetail.tsx)
- Read only: [Sidebar.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/components/layout/Sidebar.tsx)
- Read only: [VideoForm.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/video/VideoForm.tsx)
- Read only: [VideoList.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/video/VideoList.tsx)

## Implementation Steps
1. Run `npm run build`.
2. Run targeted tests if new or existing test coverage exists for touched modules.
3. Smoke-check:
   - sidebar navigation to video module
   - roadmap node opening/closing video selection
   - video create/edit/delete flow
   - linked video question persistence
4. Perform code review focused on regressions and missing safeguards.
5. Update PRD/plan/docs if implementation differs from assumptions.

## Todo List
- [ ] Run build validation
- [ ] Run relevant tests or record test gap
- [ ] Smoke-check roadmap and video module
- [ ] Review hybrid persistence logic
- [ ] Update docs if implementation drift appears

## Success Criteria
- Build passes.
- Core admin flows for roadmap video selection and video CMS work without regression.
- Docs and implementation remain aligned.

## Risk Assessment
- Risk: regression hides in route navigation or selector caching.
- Mitigation: manually smoke-check navigation and cached selector flows.
- Risk: tests are sparse for this area.
- Mitigation: document explicit manual verification steps if automated coverage is limited.

## Security Considerations
- Reconfirm HTML rendering is sanitized.
- Reconfirm deletion/update flows cannot operate on empty IDs.

## Next Steps
- Mark plan complete and sync project docs/changelog as appropriate after implementation lands.

## Unresolved Questions
- None.

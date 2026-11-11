# Phase 05: Validate Build, Review, and Doc Sync

## Context Links
- PRD: [docs/721-video-lesson-admin-cms-and-roadmap-opening-closing-video.md](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/docs/721-video-lesson-admin-cms-and-roadmap-opening-closing-video.md)
- Plan root: [plan.md](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/plans/20260403-1505-721-video-lesson-admin-cms-and-roadmap-opening-closing-video/plan.md)

## Overview
- Priority: High
- Status: Pending
- Goal: verify the final implementation, review regressions, and sync docs.

## Key Insights
- This ticket touches routes, sidebar, lesson flows, learning item flows, and roadmap editor in one pass.
- The biggest regression risks are partial save flows and stale roadmap payload fields.

## Requirements
- Run compile/build check after code changes.
- Run relevant tests if available or document gaps.
- Use `code-reviewer` agent after implementation.
- Update docs if actual implementation diverges from PRD or plan assumptions.

## Architecture
- Validation order:
  1. Type/build validation
  2. Manual route smoke checks
  3. Save/reload checks for video and roadmap
  4. Code review
  5. Docs sync

## Related Code Files
- Entire #721 change set

## Implementation Steps
1. Run `npm run build`.
2. If tests exist for touched areas, run targeted tests; otherwise note absence.
3. Smoke check:
   - `/video`
   - `/video/create`
   - `/video/:id`
   - `/course/:courseId`
4. Review for stale references to removed roadmap video model.
5. Update PRD/plan/doc statuses after implementation completes.

## Todo List
- [ ] Build passes
- [ ] Relevant tests pass or gaps documented
- [ ] Review completed
- [ ] Docs synced with actual implementation

## Success Criteria
- Final code compiles.
- No stale roadmap inline video references remain.
- Review finds no critical regression blockers.

## Risk Assessment
- Risk: build passes but cross-entity save flow still breaks in runtime.
- Mitigation: include manual save/reload smoke checks in admin UI.

## Security Considerations
- Verify HTML preview uses sanitized content.

## Next Steps
- Mark plan phases complete after implementation.

## Unresolved Questions
- None.

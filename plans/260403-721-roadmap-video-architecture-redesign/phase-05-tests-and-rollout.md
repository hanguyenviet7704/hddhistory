## Context Links
- `docs/roadmap-node-video-redesign.md`
- `plans/2026-04-03-roadmap-video-architecture-redesign/plan.md`

## Overview
- Priority: High
- Status: Proposed
- Brief description: Verify video lesson behavior and release without breaking current roadmap consumers.

## Key Insights
- The main risk is not the new lesson type itself; it is the interactions between lesson, roadmap slot ids, and learning item checkpoints.
- This plan avoids full roadmap migration, so backward compatibility should be easier to maintain.

## Requirements
- Verify lesson CRUD for `type = video`.
- Verify roadmap update/find with `openingVideoId` and `closingVideoId`.
- Verify lesson deletion clears video slots.
- Verify user video activity isolation.

## Architecture
- No migration of existing roadmap shape is required.
- Testing focuses on additive lesson and roadmap changes.

## Related Code Files
- Create:
  - tests for lesson video DTOs/services
  - tests for roadmap video slot behavior
  - tests for learning item checkpoint validation
  - tests for user video activity APIs
- Modify:
  - swagger contract if needed
- Delete:
  - none

## Implementation Steps
1. Add DTO tests for video lesson fields.
2. Add service tests for roadmap slot hydration and cleanup.
3. Add learning item checkpoint validation tests.
4. Add user activity endpoint tests.
5. Run build and lint checks.

## Todo List
- [ ] DTO tests
- [ ] Roadmap service tests
- [ ] Learning item tests
- [ ] Activity endpoint tests
- [ ] Build/lint verification

## Success Criteria
- Existing roadmap payload without video slots still works.
- Video lesson payload validates and persists correctly.
- User activity remains isolated by user and lesson.
- Existing roleplay/lesson/output roadmap behavior remains intact.

## Risk Assessment
- Hidden branches that assume lesson types are only lesson/roleplay/output may fail.
- Roadmap cleanup may miss one of the 2 video slot ids if deletion logic is incomplete.

## Security Considerations
- Sanitize HTML summary content.
- Ensure user activity endpoints cannot read/write another user's data.

## Next Steps
- Start coding after unresolved rules are confirmed.

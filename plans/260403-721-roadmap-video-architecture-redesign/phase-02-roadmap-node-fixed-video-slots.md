## Context Links
- `docs/roadmap-node-video-redesign.md`
- `plans/2026-04-03-roadmap-video-architecture-redesign/plan.md`

## Overview
- Priority: High
- Status: Proposed
- Brief description: Keep roadmap node structure stable by adding only fixed opening and closing video lesson ids.

## Key Insights
- The business rule is now fixed: one video at the start and one at the end of a node.
- Generic `videos[]` or `items[]` would overcomplicate the current system.
- Business naming should be used instead of numeric suffixes.

## Requirements
- Add an opening video slot.
- Add a closing video slot.
- Keep current roadmap node fields untouched otherwise.
- Allow node read response to hydrate these lesson ids if needed.

## Architecture
- Add `openingVideoId?: string`.
- Add `closingVideoId?: string`.
- Optional hydrated fields in response:
  - `openingVideo?: ILessonBrief | null`
  - `closingVideo?: ILessonBrief | null`

## Related Code Files
- Modify:
  - `src/modules/courses/src/modules/course/interface/roadmap.interface.ts`
  - `src/modules/courses/src/modules/course/dto/create-roadmap.dto.ts`
  - `src/modules/courses/src/modules/course/schema/roadmap.schema.ts`
  - `src/modules/courses/src/modules/course/course.service.ts`
- Create:
  - none
- Delete:
  - none

## Implementation Steps
1. Add the 2 roadmap slot ids to interfaces and DTOs.
2. Add hydration in roadmap read response.
3. Update lesson removal flow to clear these ids.
4. Review whether `numberOfLesson` should count video lessons.

## Todo List
- [ ] Add `openingVideoId`
- [ ] Add `closingVideoId`
- [ ] Add response hydration
- [ ] Add cleanup-on-delete logic
- [ ] Decide count semantics

## Success Criteria
- Current roadmap payload remains valid.
- New payload can point to start/end video lessons.
- Existing roleplay/lesson/output behavior remains stable.

## Risk Assessment
- Fixed slots only support 2 videos per node.
- Counting video lessons may affect existing dashboards if not documented.

## Security Considerations
- Validate that slot ids reference only `LessonType.VIDEO`.
- Preserve existing authorization on roadmap update.

## Next Steps
- Move timed checkpoints to learning item.

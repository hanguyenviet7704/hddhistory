## Context Links
- `docs/roadmap-node-video-redesign.md`
- `plans/2026-04-03-roadmap-video-architecture-redesign/plan.md`

## Overview
- Priority: High
- Status: Proposed
- Brief description: Introduce `LessonType.VIDEO` and extend lesson data for video-specific authoring.

## Key Insights
- Video now behaves like a lesson, not a roadmap attachment.
- Existing lesson lifecycle can be reused with minimal change.
- `video.summary` should be separate from `description`.

## Requirements
- Add `LessonType.VIDEO`.
- Add `video: { url, thumbnail, summary }`.
- Keep `description` unchanged.
- Do not add `thumbnail` in phase 1.

## Architecture
- Extend lesson enum, interface, DTOs, and schema.
- Add conditional validation for `video.url` when `type = video`.
- `video.summary` remains optional unless product decides otherwise.

## Related Code Files
- Modify:
  - `src/modules/courses/src/modules/lesson/enum/lesson.enum.ts`
  - `src/modules/courses/src/modules/lesson/interface/lesson.interface.ts`
  - `src/modules/courses/src/modules/lesson/dto/create-lesson.dto.ts`
  - `src/modules/courses/src/modules/lesson/dto/update-lesson.dto.ts`
  - `src/modules/courses/src/modules/lesson/schema/lesson.schema.ts`
  - `src/modules/courses/src/modules/lesson/lesson.service.ts`
- Create:
  - none
- Delete:
  - none

## Implementation Steps
1. Add `VIDEO` to `LessonType`.
2. Add `video` to lesson types and schema.
3. Add DTO validation rules for video lessons.
4. Review lesson service rules that depend on lesson type.

## Todo List
- [ ] Add enum member
- [ ] Add lesson fields
- [ ] Add DTO validation
- [ ] Review service branches by lesson type

## Success Criteria
- Video lessons can be created and updated cleanly.
- Existing lesson types remain unaffected.
- The API contract is explicit about video-specific fields.

## Risk Assessment
- Conditional DTO validation can be missed if create/update paths diverge.
- Existing code that branches on lesson type may silently ignore `VIDEO`.

## Security Considerations
- Sanitize `video.summary` HTML before persistence.
- Validate `video.url` format.

## Next Steps
- Add fixed video slots to roadmap node.

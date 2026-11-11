## Context Links
- `docs/roadmap-node-video-redesign.md`
- `plans/2026-04-03-roadmap-video-architecture-redesign/plan.md`

## Overview
- Priority: High
- Status: Proposed
- Brief description: Create a separate per-user activity model for video lessons.

## Key Insights
- Watch position, notes, and checkpoint answers are high-write user data.
- `user_progress` should not be reshaped for this in phase 1.
- Video is now a lesson, so activity should key by `lessonId`.

## Requirements
- Store last watched position.
- Store notes per user/video lesson.
- Store checkpoint answer state per user/video lesson.
- Keep roadmap and lesson authoring data immutable during normal user actions.

## Architecture
- Create collection `user_video_lesson_activity`.
- One document per `userId + lessonId + nodeId`.
- Embed notes and checkpoint results in that document.

## Related Code Files
- Create:
  - user video lesson activity interface
  - schema
  - repository
  - DTOs for notes and checkpoint answers
- Modify:
  - module wiring under courses/progress area
- Delete:
  - none

## Implementation Steps
1. Define activity schema and indexes.
2. Define note and checkpoint result subdocuments.
3. Add repository upsert methods.
4. Add API endpoints for notes and checkpoint answers.

## Todo List
- [ ] Define schema
- [ ] Add indexes
- [ ] Add note model
- [ ] Add checkpoint result model
- [ ] Add endpoints

## Success Criteria
- User writes do not mutate roadmap or lesson documents.
- Video player can load and save per-user state independently.
- Activity lookup remains keyed to the video lesson id.

## Risk Assessment
- Note arrays can grow if not bounded.
- Concurrent updates need careful write patterns.

## Security Considerations
- Enforce ownership by `userId`.
- Validate note content and answer payloads.

## Next Steps
- Integrate all pieces and verify backward compatibility.

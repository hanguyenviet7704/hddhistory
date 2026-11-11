# Phase 01: Audit Video Roadmap Typing and Save Flow

## Context Links
- PRD: [docs/721-video-cms-roadmap-opening-closing-videos.md](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/docs/721-video-cms-roadmap-opening-closing-videos.md)
- Roadmap types: [course.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/course.interface.ts)
- Roadmap enum: [course.enum.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/enum/course.enum.ts)
- Video lesson types: [lesson.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/lesson.interface.ts)
- Learning item types: [learning-item.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/learning-item/learning-item.interface.ts)
- Roleplay reference flow: [RoleplayForm.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/roleplays/RoleplayForm.tsx)

## Overview
- Priority: Highest
- Status: Pending
- Goal: lock the frontend data contract before UI edits start.

## Key Insights
- Repo currently has mixed old/new roadmap typing for video.
- User already changed lesson and learning item interfaces in the worktree.
- `videoQuestions` still live on `ILearningItem`, so video save flow cannot be lesson-only unless backend changes again.

## Requirements
- Confirm all roadmap typing and payloads stop referencing `INodeVideo`.
- Confirm whether `VideoPositionInNode` can be removed from frontend safely.
- Define the save/load bridge between video lesson and its linked learning item.
- Identify exact reusable blocks from `LessonForm`, `LessonList`, and `RoleplayForm`.

## Architecture
- Roadmap becomes reference-only: node stores IDs of related lessons, including optional opening/closing video lessons.
- Video entity is lesson-first for routing/list/detail, with linked learning item persistence for `videoQuestions`.
- `learningItemId` becomes the bridge field, matching roleplay lesson behavior.

## Related Code Files
- Modify: [course.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/course.interface.ts)
- Modify: [course.enum.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/enum/course.enum.ts)
- Read only: [lesson.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/lesson.interface.ts)
- Read only: [learning-item.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/learning-item/learning-item.interface.ts)
- Read only: [RoleplayForm.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/roleplays/RoleplayForm.tsx)

## Implementation Steps
1. Remove deprecated roadmap video typing from frontend types and imports.
2. Audit all `VideoPositionInNode` usages and replace/delete them.
3. Define helper mapping for video lesson <-> linked learning item payloads.
4. Decide what shared helpers should be copied vs extracted to avoid large risky refactors.

## Todo List
- [ ] Remove `INodeVideo` usage from roadmap typings
- [ ] Remove `VideoPositionInNode` usage from roadmap flow
- [ ] Document lesson/learning item persistence sequence for video
- [ ] Identify shared helper candidates for HTML editor and exercise blocks

## Success Criteria
- No roadmap code path depends on old inline video shape.
- Video persistence assumptions are explicit before form work starts.
- Search for `VideoPositionInNode` only returns acceptable non-roadmap leftovers or zero results.

## Risk Assessment
- Risk: user worktree already changed core types, causing merge friction.
- Mitigation: read and preserve existing uncommitted type edits; only remove deprecated fields intentionally.
- Risk: saving `videoQuestions` via wrong entity causes data loss.
- Mitigation: mirror `RoleplayForm` save order and verify by inspecting returned IDs.

## Security Considerations
- No auth scope change.
- Avoid trusting unsanitized HTML from summary editor.

## Next Steps
- Move to Phase 02 to replace roadmap editor UI and save payload.

## Unresolved Questions
- None.

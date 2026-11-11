# Phase 03: Implement Video Form and Video Question Editor

## Context Links
- PRD: [docs/721-video-lesson-admin-cms-and-roadmap-opening-closing-video.md](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/docs/721-video-lesson-admin-cms-and-roadmap-opening-closing-video.md)
- Reference forms:
  - [LessonForm.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/lessons/LessonForm.tsx)
  - [RoleplayForm.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/roleplays/RoleplayForm.tsx)
  - [ExerciseForm.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/exercises/ExerciseForm.tsx)
- Upload: [CloudflareFileUpload.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/components/files/CloudflareFileUpload.tsx)

## Overview
- Priority: Highest
- Status: Pending
- Goal: create a dedicated video editor that manages lesson shell fields plus video-specific content and questions.

## Key Insights
- `VideoForm` should not inherit lesson keypoint UX.
- `summary` needs HTML editing, and repo already has TipTap + DOMPurify patterns to reuse.
- `videoQuestions` belongs to learning item typing, so video form likely needs dual save orchestration.
- `RoleplayForm` is the closest precedent for a lesson-backed screen with extra linked learning-item data.

## Requirements
- Base lesson payload:
  - `type: LessonType.VIDEO`
  - `title`
  - `description`
  - `image`
  - `status`
  - `courseId`
  - `index`
  - `summary`
  - `videoUrl`
- No keypoint picker block.
- `summary` is edited as HTML per current language.
- `videoUrl` uses video upload.
- `videoQuestions` supports add/edit/delete and maps to learning item payload.

## Architecture
- Maintain local `currentVideoLesson: ILesson`.
- Maintain local `currentVideoItem: ILearningItem` for `videoQuestions`.
- Save order proposal:
  1. create or update lesson
  2. resolve linked `learningItemId`
  3. create or update learning item with `videoQuestions`
  4. patch lesson with `learningItemId` if backend requires second round trip
- Extract small shared helpers only if reuse is obvious; avoid refactor spiral.

## Related Code Files
- Add/modify: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/video/VideoForm.tsx`
- Modify if needed: [lesson.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/lesson.interface.ts)
- Modify if needed: [learning-item.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/learning-item/learning-item.interface.ts)
- Modify if needed: [lessonService.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/services/lessonService.ts)
- Read only: [RoleplayForm.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/roleplays/RoleplayForm.tsx)

## Implementation Steps
1. Define default empty video lesson state with `type: LessonType.VIDEO`.
2. Define default empty learning item state for `videoQuestions`.
3. Reuse/select minimal shared lesson fields from `LessonForm`.
4. Add rich text editor for `summary` with sanitize-on-save flow.
5. Add `CloudflareFileUpload` for `videoUrl`.
6. Build `videoQuestions` editor UI:
   - `atSecond`
   - embedded `exercise` editor
7. Convert `videoQuestions` to payload form before submit.
8. Implement create/update orchestration for lesson + linked learning item.
9. Implement delete behavior for video lesson and linked learning item if appropriate.

## Todo List
- [ ] Create default video lesson state
- [ ] Create default linked learning item state
- [ ] Add summary HTML editor
- [ ] Add video upload field
- [ ] Add video question CRUD UI
- [ ] Add lesson + learning item save flow
- [ ] Add detail load flow

## Success Criteria
- Video can be created and edited from dedicated form.
- `summary` HTML persists correctly.
- `videoUrl` persists correctly.
- `videoQuestions` load and save correctly.

## Risk Assessment
- Risk: embedded exercise editor scope becomes too large for one file.
- Mitigation: support focused subset first if full parity proves too heavy, but document the subset explicitly.
- Risk: lesson/learning-item sync creates partial-save states.
- Mitigation: serialize requests and keep user feedback explicit on failed second save.

## Security Considerations
- Sanitize HTML before preview/render.
- Do not trust uploaded URL without backend validation.

## Next Steps
- Hand off to Phase 04 for roadmap integration.

## Unresolved Questions
- Whether `videoQuestions.exercise` should support full parity with `ExerciseForm` or only practical variants used in videos.

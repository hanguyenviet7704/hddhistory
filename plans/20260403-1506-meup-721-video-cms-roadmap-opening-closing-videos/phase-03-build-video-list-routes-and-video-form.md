# Phase 03: Build Video List, Routes, and Video Form

## Context Links
- PRD: [docs/MEUP-721-video-cms-roadmap-opening-closing-videos.md](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/docs/MEUP-721-video-cms-roadmap-opening-closing-videos.md)
- Sidebar: [Sidebar.tsx](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/components/layout/Sidebar.tsx)
- Routes: [index.tsx](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/routes/index.tsx)
- Lesson list reference: [LessonList.tsx](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/pages/lessons/LessonList.tsx)
- Lesson form reference: [LessonForm.tsx](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/pages/lessons/LessonForm.tsx)
- Exercise editor reference: [ExerciseForm.tsx](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/pages/exercises/ExerciseForm.tsx)
- Roleplay persistence reference: [RoleplayForm.tsx](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/pages/roleplays/RoleplayForm.tsx)
- HTML editor reference: [OnboardingManagemant.tsx](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/pages/onboardings/OnboardingManagemant.tsx)

## Overview
- Priority: Highest
- Status: Pending
- Goal: add a complete video admin module with lesson-linked metadata and video-question editing.

## Key Insights
- `LessonList` already solves course filter, search, and pagination for lesson-backed content.
- `LessonForm` contains many reusable lesson metadata controls, but keypoint handling must be removed for video.
- `ExerciseForm` is large; reusing the whole page inline is risky, so video question editing should likely extract or adapt the minimum exercise editor surface needed.
- `RoleplayForm` proves the repo already accepts a hybrid screen that saves both lesson and linked learning item.

## Requirements
- Add sidebar item `Video`.
- Add routes and pages under `src/pages/video/`.
- `VideoList` fetches lesson type `VIDEO` only.
- `VideoForm` supports create/edit/delete for lesson type `VIDEO`.
- `VideoForm` must not render keypoint selection.
- `VideoForm` must render:
  - HTML summary editor
  - video upload
  - video question list
  - lesson metadata fields retained for videos
- Save flow must keep `learningItemId` synchronized when video questions are stored separately.

## Architecture
- Create dedicated files:
  - `VideoList.tsx`
  - `VideoCreate.tsx`
  - `VideoDetail.tsx`
  - `VideoForm.tsx`
- Treat video module as lesson-backed navigation surface.
- Inside `VideoForm`:
  - lesson state manages core lesson fields
  - linked learning item state manages `videoQuestions`
  - save function persists linked learning item first, then lesson
- Reuse `CloudflareFileUpload` for `videoUrl` with `accept="video/*"`.
- Reuse Tiptap summary editor pattern with sanitization before save/preview.

## Related Code Files
- Modify: [Sidebar.tsx](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/components/layout/Sidebar.tsx)
- Modify: [index.tsx](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/routes/index.tsx)
- Create: [VideoList.tsx](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/pages/video/VideoList.tsx)
- Create: [VideoCreate.tsx](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/pages/video/VideoCreate.tsx)
- Create: [VideoDetail.tsx](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/pages/video/VideoDetail.tsx)
- Create: [VideoForm.tsx](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/pages/video/VideoForm.tsx)
- Possibly modify: [lessonService.ts](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/services/lessonService.ts)
- Possibly modify: [learningItemService.ts](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/services/learningItemService.ts)

## Implementation Steps
1. Add sidebar menu item and routes for the video module.
2. Implement `VideoList` by adapting lesson list behavior with `LessonType.VIDEO`.
3. Implement `VideoCreate` and `VideoDetail` shells.
4. Build `VideoForm` lesson state:
   - title, description, image, status, course, timing, icons, other retained fields
   - summary HTML
   - video URL upload
5. Build linked learning item state for `videoQuestions`.
6. Create minimal reusable editor helpers for `ExerciseInput` if necessary, instead of embedding the whole `ExerciseForm`.
7. Implement hybrid save flow:
   - save linked learning item
   - bind `learningItemId`
   - save lesson with `type: VIDEO`
8. Implement delete flow and detail reload flow.

## Todo List
- [ ] Add `Video` to sidebar
- [ ] Add `/video`, `/video/create`, `/video/:videoId` routes
- [ ] Implement `VideoList`
- [ ] Implement `VideoForm`
- [ ] Add summary HTML editor
- [ ] Add Cloudflare video upload
- [ ] Add `videoQuestions` editor and payload conversion
- [ ] Implement lesson + learning item save sequencing

## Success Criteria
- User can create and edit video content end to end from the new module.
- `VideoList` is isolated from regular lessons.
- Video details reload without losing linked `videoQuestions`.
- No keypoint selection UI appears in `VideoForm`.

## Risk Assessment
- Risk: copying too much from `ExerciseForm` creates a massive file and fragile logic.
- Mitigation: extract only the exercise-question subset needed for `videoQuestions`.
- Risk: video lesson edit page needs both lesson ID and linked learning item ID but backend responses may be inconsistent.
- Mitigation: normalize fetch results, refresh linked entity after save, and mirror the roleplay flow.
- Risk: `VideoForm.tsx` grows beyond manageable size.
- Mitigation: split helper components early if file approaches 200 lines of dense logic.

## Security Considerations
- Sanitize summary HTML before preview/render.
- Do not trust uploaded URL shape; rely on upload result and trim empty values.

## Next Steps
- Move to Phase 04 for compile, regression checks, and doc sync.

## Unresolved Questions
- None.

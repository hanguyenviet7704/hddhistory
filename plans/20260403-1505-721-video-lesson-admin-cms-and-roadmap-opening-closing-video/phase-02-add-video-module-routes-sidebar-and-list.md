# Phase 02: Add Video Module Routes, Sidebar, and List

## Context Links
- PRD: [docs/721-video-lesson-admin-cms-and-roadmap-opening-closing-video.md](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/docs/721-video-lesson-admin-cms-and-roadmap-opening-closing-video.md)
- Navigation: [Sidebar.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/components/layout/Sidebar.tsx)
- Router: [index.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/routes/index.tsx)
- Reference list pages:
  - [LessonList.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/lessons/LessonList.tsx)
  - [RoleplayList.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/roleplays/RoleplayList.tsx)

## Overview
- Priority: High
- Status: Pending
- Goal: expose a first-class `Video` module in admin CMS.

## Key Insights
- Existing list pages for lesson, roleplay, output share the same fetch/filter/pagination pattern.
- `LessonType.VIDEO` already exists, so `VideoList` can ride on `lessonService`.
- New module should live under `src/pages/video/` to keep routing and ownership clear.

## Requirements
- Add sidebar menu item for `Video`.
- Add routes:
  - `/video`
  - `/video/create`
  - `/video/:videoId`
- Create list page filtered by `LessonType.VIDEO`.
- Create create/detail page shells that mount `VideoForm`.

## Architecture
- `VideoList` parallels lesson/roleplay list structure but queries `type: LessonType.VIDEO`.
- `VideoCreate` and `VideoDetail` mirror lesson module structure.
- Keep write ownership isolated to new `src/pages/video/*` files plus router/sidebar.

## Related Code Files
- Modify: [Sidebar.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/components/layout/Sidebar.tsx)
- Modify: [index.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/routes/index.tsx)
- Add: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/video/VideoList.tsx`
- Add: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/video/VideoCreate.tsx`
- Add: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/video/VideoDetail.tsx`
- Add: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/video/VideoForm.tsx`

## Implementation Steps
1. Add `Video` sidebar entry with an appropriate icon.
2. Register three new routes under protected layout.
3. Build `VideoList` from lesson/roleplay list pattern.
4. Wire create page navigation to `/video/:videoId` after save.
5. Wire detail page fetch through `lessonService.getById`.

## Todo List
- [ ] Add sidebar item
- [ ] Add router entries
- [ ] Create list page
- [ ] Create create/detail wrappers
- [ ] Confirm navigation and active menu state

## Success Criteria
- User can navigate from sidebar to list, create, and detail video screens.
- List only shows `LessonType.VIDEO` records.

## Risk Assessment
- Risk: route collisions or active-path highlight issues.
- Mitigation: follow existing lesson module naming exactly.

## Security Considerations
- No new permission surface beyond existing protected routes.

## Next Steps
- Hand off to Phase 03 for `VideoForm`.

## Unresolved Questions
- None.

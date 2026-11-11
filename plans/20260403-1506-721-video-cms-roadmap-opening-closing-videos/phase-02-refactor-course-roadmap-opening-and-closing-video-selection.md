# Phase 02: Refactor Course Roadmap Opening and Closing Video Selection

## Context Links
- PRD: [docs/721-video-cms-roadmap-opening-closing-videos.md](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/docs/721-video-cms-roadmap-opening-closing-videos.md)
- Main screen: [CourseDetail.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/courses/CourseDetail.tsx)
- Lesson service: [lessonService.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/services/lessonService.ts)
- Lesson enum: [lesson.enum.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/enum/lesson.enum.ts)

## Overview
- Priority: Highest
- Status: Pending
- Goal: replace roadmap node inline upload UI with opening/closing video selectors.

## Key Insights
- `CourseDetail.tsx` already has modal-driven selectors for roleplay, lessons, and output.
- Existing roadmap caching is grouped by field type and can be extended to video selectors.
- Save flow currently calls `handleSaveRoadmap` after modal completion; this can stay unchanged if payload mapping is corrected.

## Requirements
- Add selector/edit UX for `openingVideo` and `closingVideo`.
- Remove inline video upload, remove position dropdown, remove per-node video save action.
- Fetch/cache lesson type `VIDEO` lists by `courseId`.
- Update node render order and payload generation.

## Architecture
- Extend field-key modeling to include `openingVideo` and `closingVideo`.
- Add video cache separate from `roleplay`, `lessons`, and `output`.
- Reuse existing single-select modal pattern for both video positions.
- Save payload includes `openingVideoId` and `closingVideoId`, never raw video object.

## Related Code Files
- Modify: [CourseDetail.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/courses/CourseDetail.tsx)
- Modify: [course.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/course.interface.ts)
- Read only: [lessonService.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/services/lessonService.ts)

## Implementation Steps
1. Extend node editing field model to support opening/closing video.
2. Add lesson list cache and fetch helper for `LessonType.VIDEO`.
3. Replace roadmap render blocks:
   - remove old video node block
   - add opening video block above roleplay
   - add closing video block below output
4. Update modal labels, badge rendering, and navigation for video lessons.
5. Update `handleSaveRoadmap` payload mapping to send opening/closing IDs only.

## Todo List
- [ ] Add video field keys and cached list state
- [ ] Add selector modal support for video lessons
- [ ] Remove node inline upload UI
- [ ] Update roadmap node save payload
- [ ] Verify node reload maps opening/closing video objects correctly

## Success Criteria
- Node card shows opening and closing video sections in the required order.
- Selecting or clearing a video updates local state and backend payload correctly.
- No roadmap render path references `node.video`.

## Risk Assessment
- Risk: selector modal logic becomes brittle with more field types.
- Mitigation: keep field-type mapping centralized and explicit.
- Risk: old nodes returned by backend still include stale `video`.
- Mitigation: ignore/deprecate field on read and avoid writing it back.

## Security Considerations
- No direct file upload remains in roadmap flow, reducing accidental upload misuse there.

## Next Steps
- Move to Phase 03 for standalone video CMS screens.

## Unresolved Questions
- None.

# Phase 04: Refactor Course Roadmap Node Opening and Closing Video Selection

## Context Links
- PRD: [docs/721-video-lesson-admin-cms-and-roadmap-opening-closing-video.md](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/docs/721-video-lesson-admin-cms-and-roadmap-opening-closing-video.md)
- Roadmap editor: [CourseDetail.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/courses/CourseDetail.tsx)
- Lesson typing: [lesson.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/lesson.interface.ts)

## Overview
- Priority: Highest
- Status: Pending
- Goal: replace legacy inline node video block with opening/closing video selectors backed by `LessonType.VIDEO`.

## Key Insights
- Current modal selector logic already supports single and multi pick; it can be extended to a new field type for video selection.
- Existing caches cover roleplay, lessons, and output only; videos need their own cache and lookup flow.
- Save currently happens immediately after lesson selection completes; keep this behavior for video selection too.

## Requirements
- Add support for editing:
  - `openingVideo`
  - `closingVideo`
- Fetch selectable records from `lessonService.getList({ type: LessonType.VIDEO })`.
- Render video badges in the node card in the new order.
- Remove old upload/select-position controls.

## Architecture
- Extend field key union to include `openingVideo` and `closingVideo`.
- Add cached `videoLessons` list and cache-loaded flag.
- Reuse existing selector modal for single-select video assignment.
- Save payload maps selected brief object back to `openingVideoId` / `closingVideoId`.

## Related Code Files
- Modify: [CourseDetail.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/courses/CourseDetail.tsx)
- Modify if needed: [course.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/course.interface.ts)

## Implementation Steps
1. Extend field union and modal state to include video fields.
2. Add video lesson cache and fetch helper branch.
3. Update edit click flow for opening/closing video.
4. Update complete-selection flow to write `openingVideoId` / `closingVideoId`.
5. Remove inline upload/video-position block entirely.
6. Reorder node sections to opening video first and closing video last.
7. Update payload mapping and reload normalization.

## Todo List
- [ ] Add video selector field keys
- [ ] Add video cache and search flow
- [ ] Replace node inline video UI
- [ ] Reorder node section rendering
- [ ] Verify save/reload behavior

## Success Criteria
- Node shows opening and closing video independently.
- Save payload no longer includes legacy node video object.
- Editor can assign, change, and clear opening/closing videos.

## Risk Assessment
- Risk: selector modal state becomes brittle as more field variants are added.
- Mitigation: isolate field-to-lesson-type mapping in a helper.

## Security Considerations
- No auth impact.

## Next Steps
- Hand off to Phase 05 for validation and review.

## Unresolved Questions
- None.

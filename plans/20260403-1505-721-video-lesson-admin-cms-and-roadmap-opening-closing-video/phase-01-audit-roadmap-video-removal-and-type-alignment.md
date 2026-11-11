# Phase 01: Audit Roadmap Video Removal and Type Alignment

## Context Links
- PRD: [docs/721-video-lesson-admin-cms-and-roadmap-opening-closing-video.md](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/docs/721-video-lesson-admin-cms-and-roadmap-opening-closing-video.md)
- Roadmap types: [course.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/course.interface.ts)
- Roadmap UI: [CourseDetail.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/courses/CourseDetail.tsx)

## Overview
- Priority: Highest
- Status: Pending
- Goal: remove legacy roadmap node video model and align codebase with opening/closing video references.

## Key Insights
- `course.interface.ts` currently mixes both old and new models.
- `CourseDetail.tsx` still hardcodes `VideoPositionInNode` and inline upload UI.
- Backward compatibility depends on tolerating old API data during load while not sending old payload fields anymore.

## Requirements
- Remove `INodeVideo` usage from roadmap typing and save flow.
- Remove `VideoPositionInNode` usage from course roadmap UI.
- Keep `openingVideoId`, `closingVideoId`, `openingVideo`, `closingVideo` as roadmap source of truth.
- Preserve existing roleplay, lessons, and output behavior.

## Architecture
- Normalize roadmap fetch to hydrate:
  - `openingVideo`
  - `roleplay`
  - `lessons`
  - `output`
  - `closingVideo`
- Save pipeline emits node metadata plus lesson references only.
- No direct node video asset upload remains in roadmap editor.

## Related Code Files
- Modify: [course.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/course.interface.ts)
- Modify: [CourseDetail.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/courses/CourseDetail.tsx)
- Modify if needed: [course.enum.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/enum/course.enum.ts)

## Implementation Steps
1. Delete or stop exporting roadmap-only video typing that is no longer valid.
2. Remove `VideoPositionInNode` imports/usages from roadmap code.
3. Update node mapping and save payload to use only `openingVideoId` / `closingVideoId`.
4. Search repo for stale roadmap video references and clear them.

## Todo List
- [ ] Remove legacy roadmap video types
- [ ] Remove legacy roadmap video payload mapping
- [ ] Verify no `VideoPositionInNode` usage remains in roadmap flow
- [ ] Keep fetch normalization backward-safe

## Success Criteria
- Frontend roadmap code no longer references node inline video model.
- TypeScript shape for roadmap node matches current backend contract.

## Risk Assessment
- Risk: removing shared enum/type breaks unrelated code unexpectedly.
- Mitigation: limit cleanup to roadmap references first, then run build.

## Security Considerations
- No auth impact.

## Next Steps
- Hand off to Phase 02 for new video module shell.

## Unresolved Questions
- None.

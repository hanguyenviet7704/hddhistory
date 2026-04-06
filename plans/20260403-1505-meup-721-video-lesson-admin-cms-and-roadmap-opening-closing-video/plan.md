# MEUP-721 Plan

## Overview
- Task: replace roadmap node inline video logic with `openingVideo` / `closingVideo`, and add a dedicated video CMS module.
- Priority: High
- Status: Planned
- Plan dir: `plans/20260403-1505-meup-721-video-lesson-admin-cms-and-roadmap-opening-closing-video`

## Phase Status
- Phase 01: Pending - audit roadmap video removal and typing cleanup
- Phase 02: Pending - add video module routes, sidebar, and list page
- Phase 03: Pending - implement `VideoForm` with lesson + video-question data flow
- Phase 04: Pending - refactor roadmap node UI to opening/closing video selectors
- Phase 05: Pending - validate build, review, and doc sync

## Context Links
- PRD: [docs/MEUP-721-video-lesson-admin-cms-and-roadmap-opening-closing-video.md](/Users/macbook/Documents/eUp Group/admin-ai-tutor/docs/MEUP-721-video-lesson-admin-cms-and-roadmap-opening-closing-video.md)
- Phase 01: [phase-01-audit-roadmap-video-removal-and-type-alignment.md](/Users/macbook/Documents/eUp Group/admin-ai-tutor/plans/20260403-1505-meup-721-video-lesson-admin-cms-and-roadmap-opening-closing-video/phase-01-audit-roadmap-video-removal-and-type-alignment.md)
- Phase 02: [phase-02-add-video-module-routes-sidebar-and-list.md](/Users/macbook/Documents/eUp Group/admin-ai-tutor/plans/20260403-1505-meup-721-video-lesson-admin-cms-and-roadmap-opening-closing-video/phase-02-add-video-module-routes-sidebar-and-list.md)
- Phase 03: [phase-03-implement-video-form-and-video-question-editor.md](/Users/macbook/Documents/eUp Group/admin-ai-tutor/plans/20260403-1505-meup-721-video-lesson-admin-cms-and-roadmap-opening-closing-video/phase-03-implement-video-form-and-video-question-editor.md)
- Phase 04: [phase-04-refactor-course-roadmap-node-opening-and-closing-video-selection.md](/Users/macbook/Documents/eUp Group/admin-ai-tutor/plans/20260403-1505-meup-721-video-lesson-admin-cms-and-roadmap-opening-closing-video/phase-04-refactor-course-roadmap-node-opening-and-closing-video-selection.md)
- Phase 05: [phase-05-validate-build-review-and-doc-sync.md](/Users/macbook/Documents/eUp Group/admin-ai-tutor/plans/20260403-1505-meup-721-video-lesson-admin-cms-and-roadmap-opening-closing-video/phase-05-validate-build-review-and-doc-sync.md)

## Key Decisions
- Video is managed as a dedicated lesson type via a new `video` module in sidebar and routes.
- Roadmap node no longer stores uploaded video/url/position directly.
- Roadmap node section order is fixed: `openingVideo`, `roleplay`, `lessons`, `output`, `closingVideo`.
- `VideoForm` does not reuse lesson keypoint selection flow.
- `VideoForm` owns video-specific fields: HTML `summary`, `videoUrl`, `videoQuestions`.
- Frontend likely needs dual-entity save flow: lesson shell + linked learning item for `videoQuestions`.

## Dependencies
- Existing `LessonType.VIDEO`.
- Existing `summary` and `videoUrl` fields in lesson typing.
- Existing `videoQuestions` typing on learning item.
- Existing lesson and learning item services.

## Success Signal
- Video module works end to end for create/edit/list.
- Roadmap node can assign opening and closing videos only via video lessons.
- Legacy roadmap inline video logic is fully removed from frontend.
- `npm run build` passes.

## Unresolved Questions
- Whether `videoQuestions.exercise` should support all exercise variants or a constrained subset in this ticket.

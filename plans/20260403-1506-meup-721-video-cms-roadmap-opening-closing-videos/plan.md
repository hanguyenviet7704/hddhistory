# MEUP-721 Plan

## Overview
- Task: replace roadmap inline video with `openingVideo` / `closingVideo` selectors and add a dedicated video CMS module.
- Priority: High
- Status: Pending
- Plan dir: `plans/20260403-1506-meup-721-video-cms-roadmap-opening-closing-videos`

## Phase Status
- Phase 01: Pending - audit typings and persistence model
- Phase 02: Pending - refactor roadmap node video management
- Phase 03: Pending - build video sidebar, routes, list, and form
- Phase 04: Pending - validate compile, review, and docs sync

## Context Links
- PRD: [docs/MEUP-721-video-cms-roadmap-opening-closing-videos.md](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/docs/MEUP-721-video-cms-roadmap-opening-closing-videos.md)
- Phase 01: [phase-01-audit-video-roadmap-typing-and-save-flow.md](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/plans/20260403-1506-meup-721-video-cms-roadmap-opening-closing-videos/phase-01-audit-video-roadmap-typing-and-save-flow.md)
- Phase 02: [phase-02-refactor-course-roadmap-opening-and-closing-video-selection.md](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/plans/20260403-1506-meup-721-video-cms-roadmap-opening-closing-videos/phase-02-refactor-course-roadmap-opening-and-closing-video-selection.md)
- Phase 03: [phase-03-build-video-list-routes-and-video-form.md](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/plans/20260403-1506-meup-721-video-cms-roadmap-opening-closing-videos/phase-03-build-video-list-routes-and-video-form.md)
- Phase 04: [phase-04-validate-build-and-doc-sync.md](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/plans/20260403-1506-meup-721-video-cms-roadmap-opening-closing-videos/phase-04-validate-build-and-doc-sync.md)

## Key Decisions
- Roadmap node stops using `node.video` and `VideoPositionInNode`.
- Roadmap order is fixed as `openingVideo`, `roleplay`, `lessons`, `output`, `closingVideo`.
- Video CMS lives under a new `src/pages/video/` module and new sidebar entry `Video`.
- `VideoForm` is separate from `LessonForm`, not a toggle mode inside lesson pages.
- `VideoForm` follows the roleplay persistence pattern if `videoQuestions` remain on linked `ILearningItem`.

## Dependencies
- Existing `LessonType.VIDEO`.
- Existing lesson API in [lessonService.ts](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/services/lessonService.ts).
- Existing learning item API in [learningItemService.ts](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/services/learningItemService.ts).
- Existing HTML editor pattern in [OnboardingManagemant.tsx](/Users/macbook/Documents/eUp%20Group/admin-ai-tutor/src/pages/onboardings/OnboardingManagemant.tsx).

## Success Signal
- Roadmap saves and reloads only opening/closing video references.
- Video menu, routes, list, and detail form work end to end.
- Video lesson persists `summary`, `videoUrl`, and `videoQuestions`.
- `npm run build` passes.

## Unresolved Questions
- None. Implementation assumes `videoQuestions` stay on linked `ILearningItem`.

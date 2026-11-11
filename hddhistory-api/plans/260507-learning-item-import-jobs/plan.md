---
title: "Learning Item Excel Import Jobs"
status: approved
priority: P1
created: 2026-05-07
---

# Learning Item Excel Import Jobs

## Scope

- Keep keypoint Excel import synchronous because it is small and returns `id` workbook.
- Move theory/exercise workbook import to async job to avoid timeout.
- Do not store/upload Excel files in this job flow.
- Do not add `type`, `scopes`, or per-scope totals to the job collection.

## Backend

- Add `course_import_jobs` collection.
- Fields: `status`, `totalRows`, `processedRows`, `percent`, `errors`, timestamps, `lastError`, user metadata.
- Add APIs:
  - `POST /api/v1/course-import-jobs/learning-items`
  - `GET /api/v1/course-import-jobs/:jobId`
- POST receives Excel buffer, creates job, starts in-process worker with `setImmediate`, returns job.
- Worker parses workbook, detects sheets, validates, imports theory/exercise data, and updates job progress/errors.

## CMS

- Keypoint keeps upload -> download result flow.
- Theory and exercise use upload -> job id -> polling -> refresh list.
- Show concise progress and validation errors through existing notification surface.

## Validation

- Backend `npm run build`.
- CMS `npm run build`.

---
title: "Drive Import Upload Job"
description: "Implement Google Drive folder import jobs that upload files to Cloudflare R2 and expose progress in the admin CMS."
status: completed
priority: P2
effort: 18h
issue: #736
branch: develop
tags: [feature, backend, frontend, api, database]
created: 2026-05-05
---

# Drive Import Upload Job

## Overview

Build `Import File From Drive` for admin CMS. Admin submits a Google Drive folder URL. Backend reads direct files from optional `images`, `videos`, and `audios` child folders, uploads them to Cloudflare R2, stores progress, and lets CMS resume progress after tab close.

## Confirmed Decisions

- CMS display name: `Import File From Drive`
- Source is Drive folder URL, not local folder upload.
- Missing child folders are allowed and skipped.
- Store one active job per user for `queued` or `processing`.
- If active job exists, create API returns the active job for resume.
- Polling interval: 5s while page visible, slower or paused when hidden.
- Track uploaded file details and failed file details as objects.
- Add cancel support; already uploaded files stay in R2.

## Phases

| # | Phase | Status | Effort | Link |
|---|-------|--------|--------|------|
| 1 | Backend Job Persistence And API | Completed | 5h | [phase-01](./phase-01-backend-job-persistence-and-api.md) |
| 2 | Backend Drive Processing | Completed | 6h | [phase-02](./phase-02-backend-drive-processing.md) |
| 3 | Admin CMS Upload Page | Completed | 5h | [phase-03](./phase-03-admin-cms-upload-page.md) |
| 4 | Validation And Docs | Completed | 2h | [phase-04](./phase-04-validation-and-docs.md) |

## API Order

1. Page open: `GET /api/v1/cloudflares/drive-imports`
2. Start import: `POST /api/v1/cloudflares/drive-imports`
3. Progress detail: `GET /api/v1/cloudflares/drive-imports/:jobId`
4. Optional cancel: `POST /api/v1/cloudflares/drive-imports/:jobId/cancel`

## Dependencies

- Backend repo: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api`
- Admin CMS repo: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin`
- Existing backend package `googleapis`
- Existing Cloudflare R2 upload service
- MongoDB via existing Mongoose patterns

## Handoff

Implementation should start with phase 1 and keep backend/API contracts stable before CMS work.

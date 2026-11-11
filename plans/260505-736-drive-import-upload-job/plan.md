---
title: "#736 Import File From Drive CMS"
description: "Add the admin CMS page for starting and monitoring Drive import jobs."
status: completed
priority: P2
effort: 7h
issue: #736
branch: develop
tags: [feature, frontend, api]
created: 2026-05-05
---

# #736 Import File From Drive CMS

## Overview

Add `Import File From Drive` to the admin CMS. Header opens a new tab. The page submits a Drive folder URL, resumes active jobs, polls backend progress, shows uploaded/failed files, and supports cancel.

## Backend Dependency

Backend plan lives in:

`/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/plans/260505-736-drive-import-upload-job/`

Required backend APIs:

1. `GET /api/v1/cloudflares/drive-imports`
2. `POST /api/v1/cloudflares/drive-imports`
3. `GET /api/v1/cloudflares/drive-imports/:jobId`
4. `POST /api/v1/cloudflares/drive-imports/:jobId/cancel`

## Confirmed Decisions

- CMS display name: `Import File From Drive`
- FE does not read Drive files.
- FE does not upload binary files.
- FE only submits URL and displays job progress.
- Poll every 5s while visible.
- Poll slower or pause while hidden.
- Missing Drive child folders are handled by backend.

## Phases

| # | Phase | Status | Effort | Link |
|---|-------|--------|--------|------|
| 1 | Admin CMS Upload Page | Completed | 5h | [phase-01](./phase-01-admin-cms-upload-page.md) |
| 2 | Validation And Docs | Completed | 2h | [phase-02](./phase-02-validation-and-docs.md) |

## Handoff

Implement after backend API contract is stable, or use mocked responses locally only for UI shaping.

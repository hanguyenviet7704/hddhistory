---
title: "Task Report - Add estimateCompleTime to keypoints"
description: "Quarterly reporting format for request coverage with AI Agent participation."
status: in-review
priority: P2
effort: 2h
branch: feature/course
tags: [report, keypoint, quarterly-kpi]
created: 2026-01-21
quarter: 2026-Q1
ai_agent_involved: true
request_volume_unit: 1
---

## Task Summary
- Request: add `estimateCompleTime` for keypoints with minimal impact.
- Scope: interface, DTO, repository brief output, schema review.
- Delivery status: in review.

## Delivery Snapshot
- Done: interface update for optional field.
- Done: `CreateKeypointDto` supports `estimateCompleTime` with validation/metadata.
- Done: `UpdateKeypointDto` inherited field via `PartialType`.
- Done: repository brief output includes `estimateCompleTime`.
- Pending: schema prop final confirm/default strategy.

## KPI Contribution (Quarterly)
- KPI: process coverage by request volume with AI Agent participation.
- Formula: `(requests with AI Agent / total requests) x 100`.
- This task contribution in 2026-Q1: `1/1 = 100%`.
- KPI threshold check: pass (`100% >= 40%`).

## Files Referenced
- `src/modules/courses/src/modules/keypoint/interface/keypoint.interface.ts`
- `src/modules/courses/src/modules/keypoint/schema/keypoint.schema.ts`
- `src/modules/courses/src/modules/keypoint/dto/create-keypoint.dto.ts`
- `src/modules/courses/src/modules/keypoint/dto/update-keypoint.dto.ts`
- `src/modules/courses/src/modules/keypoint/repository/keypoint.repository.ts`

## Risks
- Unit for `estimateCompleTime` not finalized may cause inconsistent data usage.
- Existing records may require null/0 policy for stable response.

## Unresolved Questions
- Unit is minutes or seconds?
- Field required or optional for new keypoints?
- Need migration/backfill for existing data?

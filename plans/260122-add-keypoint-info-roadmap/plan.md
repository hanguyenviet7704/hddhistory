---
title: "Task Report - Add roadmap keypoint info for lesson nodes"
description: "Quarterly reporting format for request coverage with AI Agent participation."
status: in_progress
priority: P2
effort: 3h
branch: feature/course
tags: [report, course, roadmap, quarterly-kpi]
created: 2026-01-22
quarter: 2026-Q1
ai_agent_involved: true
request_volume_unit: 1
---

## Task Summary
- Request: expose keypoint metadata and score in `CourseService.findRoadmap` for `LESSON` lessons.
- Scope: lesson projection, keypoint brief lookup, DI wiring, roadmap enrichment.
- Delivery status: in progress (core wiring done, score mapping pending).

## Delivery Snapshot
- Done: lesson repository projection includes keypoint ids for roadmap pipeline.
- Done: keypoint repository has brief fetch helper with needed fields.
- Done: course module DI wiring supports keypoint repository usage in service.
- Done: roadmap flow collects lesson keypoints and maps keypoint brief data.
- Pending: averageScore mapping from `userProgress.lessonsResult.keypointsResult`.
- Pending: final response shape check (`id` mapping, lesson order, null-safe handling).

## KPI Contribution (Quarterly)
- KPI: process coverage by request volume with AI Agent participation.
- Formula: `(requests with AI Agent / total requests) x 100`.
- This task contribution in 2026-Q1: `1/1 = 100%`.
- Cumulative from 2 recent plan tasks in 2026-Q1: `2/2 = 100%`.
- KPI threshold check: pass (`100% >= 40%`).

## Files Referenced
- `src/modules/courses/src/modules/lesson/repository/lesson.repository.ts`
- `src/modules/courses/src/modules/keypoint/repository/keypoint.repository.ts`
- `src/modules/courses/src/modules/course/course.module.ts`
- `src/modules/courses/src/modules/course/course.service.ts`

## Risks
- Missing progress data can produce incorrect averageScore defaults.
- Response field mismatch (`id`/`_id`) may break client parsing if not aligned.

## Unresolved Questions
- When keypoint progress missing, return `0` or omit `averageScore`?

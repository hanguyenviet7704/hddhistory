# Phase 01 - Backend Singleton Branch Survey

## Overview

- Priority: High
- Status: Complete
- Replace per-emoji config API with singleton branch survey API.

## Implementation Steps

1. Update interfaces to `introQuestion`, `branches`, `closedQuestion`, `openQuestion`.
2. Update config schema to singleton document with `configKey`.
3. Update response schema to snapshot branch data without `configId`.
4. Replace DTOs for config upsert and response submit.
5. Replace repositories with singleton helpers.
6. Update service/controller route methods.
7. Verify build and lint.

## Success Criteria

- App can fetch one config.
- App submits `{ branchId, selectedOptionIds, feedback? }`.
- Backend validates branch/options and stores response history snapshot.

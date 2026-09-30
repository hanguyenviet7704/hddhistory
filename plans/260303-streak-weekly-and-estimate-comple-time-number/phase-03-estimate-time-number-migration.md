## Context Links
- `plans/2026-03-03-streak-weekly-and-estimate-comple-time-number/plan.md`

## Overview
- Priority: High
- Status: Pending
- Purpose: Move time calculation source to numeric minutes field.

## Requirements
- New field: `estimateCompleTimeNumber` (number, unit = minute).
- Existing `estimateCompleTime` text remains for UI display.
- Streak time calculation must only use numeric field.

## Migration Strategy
1. Add field in schema/interface/DTO.
2. Backfill existing records:
- Parse from `estimateCompleTime.en` or `.vi` if possible.
- Support patterns: `8 min`, `8 phút`, `8m`.
- On parse fail: set `0` and log.
3. Update create/update validation:
- Accept only non-negative numbers.

## Data Integrity Rules
- Never parse text dynamically in hot path after migration.
- Numeric field is single source for math.
- Keep text field optional and non-authoritative.

## Implementation Steps
1. Add migration script with dry-run mode.
2. Run dry-run and collect parse-fail list.
3. Run real backfill.
4. Update service logic to consume numeric field only.

## Success Criteria
- 100% records have numeric field (or explicit 0 fallback).
- No runtime regex parse in streak update path.

## Risks
- Locale-specific text can parse incorrectly if format is non-standard.

## Unresolved Questions
- Should zero-minute items count as valid completion time contribution?

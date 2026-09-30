## Context Links
- `plans/2026-03-03-streak-weekly-and-estimate-comple-time-number/plan.md`

## Overview
- Priority: Medium
- Status: Pending
- Purpose: Keep API contract clear and safe after streak/time updates.

## API Requirements
- `GET streak` returns:
- `currentStreak`
- `bestStreak`
- `studyTime` (week total)
- `weekStudy` (Mon..Sun)
- `weekStartDate`

## Validation Requirements
- `estimateCompleTimeNumber` must be numeric and `>= 0`.
- Reject malformed values early at DTO layer.
- Keep backward compatibility for clients still sending old text field.

## Documentation Requirements
- Swagger examples must include new numeric field.
- Add short inline docs on response fields and units.

## Implementation Steps
1. Update DTOs with numeric field and examples.
2. Update swagger decorators/descriptions.
3. Add comments in service response mapping for unit + day index.

## Success Criteria
- API consumers can understand units and mapping from docs only.
- Invalid time values are blocked before service layer.

## Risks
- Mixed old/new payloads from client versions may cause partial data.

## Unresolved Questions
- Need temporary compatibility window for old clients?

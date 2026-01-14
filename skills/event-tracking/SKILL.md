---
name: event-tracking
description: Implement module event tracking in this repo using the marketing sheet, update tracking services, and verify via run_app scripts.
---

# Event Tracking (Repo)

Use this skill when implementing or updating event tracking for any module in this repository.

## Quick start
- Read the shared workflow: `docs/event-tracking.md`.
- Use the marketing sheet for event names and parameters.
- Update `@raw_plan/event_tracking` after each module.

## Workflow (per module)
1. Remove legacy tracking for the module (keep base/common tracking services in `lib/config/services/tracking/`).
2. Add event keys to `lib/core/constants/manual/tracking_key.dart` (exact names from the sheet).
3. Add method signatures in `lib/config/services/tracking/i_tracking_service.dart`.
4. Implement methods in `lib/config/services/tracking/app_tracking_service.dart`.
5. Wire UI events in the module presentation layer.
6. Verify events on device and record results.

## Parameter rules
- Prefer backend values (e.g., `trackingLabel`) when provided.
- For language selection, use `languageAISupport` from `lib/src/common/presentation/blocs/setting/locale_cubit.dart`.
- Join multi-select values with commas.

## Verification
- Use run scripts:
  - macOS/Linux: `tools/<os>/build/run_app.sh`
  - Windows: `tools\windows\build\run_app.bat`
- Fallback: `adb logcat -d | rg "\[Tracking\]"`

## Notes
- Do not edit generated files (`*.g.dart`, `*.config.dart`, Retrofit outputs). Regenerate instead.
- If any mapping or requirement is unclear, pause and ask the user.

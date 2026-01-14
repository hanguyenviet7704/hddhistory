# Event Tracking

This document defines the shared workflow for implementing and verifying event tracking across modules.
It is intentionally module-agnostic; use the marketing sheet for event names and parameters.

## Core locations
- Tracking interfaces/implementations: `lib/config/services/tracking/`
- Event keys: `lib/core/constants/manual/tracking_key.dart`
- UI integration: feature modules under `lib/src/<feature>/presentation/`

## Standard workflow (per module)
1. Remove legacy tracking tied to the module (keep base/common tracking services).
2. Add event keys to `tracking_key.dart` using the exact names from the marketing sheet.
3. Add method signatures to `ITrackingService` and implementations in `AppTrackingService`.
4. Wire UI events to `AppService.instance.appTrackingService.<method>()`.
5. Map parameters exactly as defined in the sheet.
6. Verify events on device (see scripts below).
7. Record progress in `@raw_plan/event_tracking`.

## Parameter rules
- Use backend-provided labels when available (e.g., `trackingLabel` in option entities).
- For language selection, use `languageAISupport` from `lib/src/common/presentation/blocs/setting/locale_cubit.dart`.
- When multiple selections are possible, join values with `,` (comma) consistently.

## Do not edit
- Generated files (e.g., `*.g.dart`, `*.config.dart`, Retrofit outputs). Regenerate instead.

## Debugging and verification
Use the cross-platform tracking scripts to run and inspect logs.

### macOS/Linux
- Run app:
  - `./tools/macos/build/run_app.sh run <dev|stg|prod> [--device <id>]`
  - `./tools/linux/build/run_app.sh run <dev|stg|prod> [--device <id>]`
- View logs:
  - `./tools/macos/build/run_app.sh logs [--device <id>] [--follow]`
  - `./tools/linux/build/run_app.sh logs [--device <id>] [--follow]`

### Windows
- Run app:
  - `tools\windows\build\run_app.bat run <dev|stg|prod> [--device <id>]`
- View logs:
  - `tools\windows\build\run_app.bat logs [--device <id>] [--follow]`

### Manual fallback
- Android: `adb logcat -d | rg "\[Tracking\]"`
- iOS: use `flutter run` console output or Xcode logs.

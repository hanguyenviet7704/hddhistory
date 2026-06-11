---
date: 2026-06-11
topic: home widget native bridge implementation
plan: plans/260611-1406-meup-747-home-widget-generator-native-bridge/plan.md
---

# Home Widget Native Bridge Implementation

## Context
MEUP-747 needed native launcher widgets for in-progress course, weekly streak, and suggested course surfaces. The project already had `home_widget` runtime available, but the generator package conflicted with the current analyzer stack.

## What Happened
- Built the Flutter `home_widget` module around payload builders, local shared storage, API sync, native bridge calls, and Cubit/usecase seams.
- Added Android Glance widgets, receiver registrations, provider XML, local drawable resources, and string metadata.
- Added iOS WidgetKit extension target, App Group entitlements, WidgetKit Swift views, payload decoding, and bundled static resources.
- Wired auth success to best-effort widget sync and logout/reset to widget data clearing.
- Wired widget launch/click URIs into `DeeplinkCubit`, with validated home-widget target parsing and tracking keys.
- Synced evergreen docs, raw checklist, and plan status to reflect the native bridge as the real implementation path.

## Decisions
- Kept `home_widget: ^0.9.3` as the runtime dependency and did not keep `home_widget_cli` / `home_widget_generator` in `pubspec.yaml` because the generator requires an analyzer range incompatible with the app's current generator stack.
- Used custom WidgetKit/Glance code instead of generated widget files, keeping native code display-only and network-free.
- Treated static images as best-effort for sync so a first-run image write failure does not block a ready widget payload.

## Verification
- Full Flutter tests passed: 549 tests.
- `flutter analyze` passed.
- Android Kotlin compile and dev debug APK build passed.
- iOS dev debug no-codesign build passed.
- `git diff --check` passed.

## Next
- Run manual widget picker and tap QA on iOS and Android devices/simulators.
- Confirm Apple App Group configuration in developer portal before signed device/TestFlight builds.

## Unresolved Questions
- None for implementation. Manual platform QA remains as a listed validation task.

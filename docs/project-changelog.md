# Project Changelog

## 2026-06-18

### Added
- Added Remote Config paywall schema v2 parsing with sale-event, new-user impression, and default-user strategy resolution.
- Added strategy-driven BE/store product loading, inline paywall plan rendering, auto-open entry tracking, and session-scoped Home/Course auto-open orchestration.
- Added regression tests for parser fail-closed behavior, strategy selection, product mapping, auto-open arbitration, route cleanup, tracking, and paywall UI components.

### Changed
- Retired direct post-auth first-time paywall routing; auth now consumes legacy intent and routes to stable Course/Home before any eligible auto-open push.
- Replaced old all-package paywall bottom sheet references with inline product cards and stable close/purchase-success dismissal back to the source route.
- Avoided no-op home-widget debounce timers when widget sync cannot run, preventing pending-timer failures in learning-streak widget tests.

### Verification
- Passed `flutter analyze --no-pub`, focused monetization/auth/onboard/route regressions, broad Phase 5 focused suite, full `flutter test --no-pub`, static grep gates, and `git diff --check`.

## 2026-06-11

### Added
- Implemented native home widgets for in-progress course, weekly streak, and suggested course with Flutter sync, Android Glance, and iOS WidgetKit.
- Added display-only widget payloads, best-effort image caching, same-day suggested-course reuse, and logout/account reset clearing.
- Added home-widget tap deeplink routing and centralized placeholder tracking events.

### Verification
- Passed `flutter test` (549 tests), `flutter analyze`, Android Kotlin compile, Android dev debug APK build, iOS dev debug no-codesign build, and `git diff --check`.

## 2026-05-27

### Fixed
- Fixed daily warm-up first-day eligibility so onboarding completion/bypass date is persisted per user and warm-up can only open from the next local day.
- Fixed daily warm-up shown-date marking so the once-per-day gate is written when the entry route opens with an initial `entry` state.
- Copied and adapted lesson-style body layouts inside daily warm-up for drag/drop, arrange, cues, and stress questions, keeping lesson module untouched.
- Kept daily warm-up's local question state/evaluation while matching lesson instruction text, sentence containers, reorder proxy, and drag/drop sentence builder behavior.

### Verification
- Passed `flutter test test/unit/daily_warm_up`, focused auth/onboarding regression tests, `flutter analyze`, and `git diff --check`.

## 2026-05-26

### Fixed
- Updated daily warm-up Home entry gating so onboarding users and the first completed-onboarding app session skip the flow without API calls or shown-date writes; next cold launch can show warm-up per user.
- Reworked daily warm-up P1/P3 visual surfaces to better match Figma, including a centered P1 CTA and P3 Lottie congratulations background with reduced-motion fallback.
- Reused dependency-free lesson leaf widgets for daily warm-up P2 drag/drop, arrange, cues, and stress question bodies while keeping evaluation local-only.

### Verification
- Passed `flutter test test/unit/daily_warm_up`, `flutter analyze`, full `flutter test`, and the daily-warm-up no-lesson-cubit coupling grep.

## 2026-05-23

### Added
- Implemented the Home daily warm-up P1-P3 flow under `lib/src/daily_warm_up/`.
- Added once-per-local-day entry gating, local question filtering/evaluation, result sheets, suggested-course handoff, localized copy, and privacy-safe analytics events.
- Added focused data, cubit, evaluator, widget, and tracking tests for daily warm-up success, failure, unsupported questions, overflow, and duplicate-tap guards.

### Changed
- Home startup now checks daily warm-up before the in-app survey while preventing stacked modal/route prompts.
- Project docs now include the `daily_warm_up` module in module inventory, roadmap, and system architecture.

### Verification
- Passed route/code generation, localization pull and slang generation, analyzer, focused daily warm-up tests, full test suite, and diff hygiene checks.

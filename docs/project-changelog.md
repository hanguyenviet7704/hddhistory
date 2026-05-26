# Project Changelog

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

# Project Changelog

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

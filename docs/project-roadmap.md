# Project Roadmap

**Last Updated:** 2026-05-18
**Scope:** product and engineering roadmap tracked from current repository state

## 1. Current Status
Meup is in active Flutter mobile development with 20 feature modules under `lib/src`.

The current product surface includes first-time onboarding V2, disabled-onboarding course-entry gating, branching onboarding fallback, course roadmap entry, read/listen lessons, output-practice conversations, video lessons, roleplay, Home in-app survey feedback, learning streaks, progress, profile/settings, and monetization.

## 2. Roadmap Phases
| Phase | Status | Notes |
| --- | --- | --- |
| Foundation architecture | Complete | Clean Architecture, BLoC/Cubit, DI, typed routing, generated models, localization pipeline. |
| Core learning flows | In progress | Course roadmap, lesson runtime, read/listen branching, exercise completion, progress sync. |
| Onboarding and activation | In progress | Onboard V2 path/symptom/course picker, notification gate, disabled-onboarding course-entry gate, branching onboarding fallback. |
| Practice expansion | In progress | Output-practice socket conversation flow, roleplay feedback, video lesson player/notes/quiz states. |
| Monetization | In progress | Paywall, IAP package load, purchase verification, first-time paywall routing. |
| Operations and release | In progress | Cross-platform build scripts, GitHub/GitLab CI, localization tooling, symbol upload policy. |
| Test coverage and hardening | Needs focus | Unit tests exist under `test/unit`; broaden coverage for newer onboarding, output practice, video lesson, and survey-adjacent Home flows. |

## 3. Near-Term Priorities
1. Keep docs and module metrics synced whenever `lib/src/*`, route contracts, platform constraints, or build scripts change.
2. Stabilize newer course-shell flows: output practice, video lesson, and completed-level additional-content request.
3. Increase test coverage around socket retry, video timed questions, and progress/streak completion gates.
4. Maintain CI parity across macOS/Linux/Windows scripts, especially symbol-upload and `--ci` behavior.

## 4. Success Signals
- `flutter analyze` and `flutter test` pass before release branches.
- Generated code and localization output match source YAML/API model changes.
- Runtime constraints stay stable: Dart `>=3.11.0 <4.0.0`, iOS `15.0`, Android `flutter.minSdkVersion`.
- No undocumented changes to feature module count, route paths, build input mapping, or CI variable contract.

## 5. Open Questions
- Is Windows build-script `--ci` and `SKIP_SYMBOL_UPLOAD` parity required for the next release cycle?
- Which newer flows need priority test targets first: output practice, video lesson, or completed-level request?

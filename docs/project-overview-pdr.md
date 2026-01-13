# Project Overview & PDR

_Last updated: 2026-01-12_

## 1. Product Summary
Meup delivers interactive language-learning experiences that blend scripted lessons, AI-driven roleplay, and tracked progress. The Flutter app targets Android/iOS with a shared Clean Architecture core and heavy automation for builds, localization, and distribution.

## 2. Objectives
1. Provide immersive lesson experiences (audio/video/roleplay overlays) with responsive UI and offline resilience.
2. Maintain multi-flavor releases (dev/stg/prod) with automated tooling so QA and release managers can promote builds quickly.
3. Ensure high developer velocity through standardized architecture, TaskEither pipelines, and enforceable code standards.
4. Capture telemetry (Crashlytics, Sentry, Analytics) to guide product decisions and stability improvements.

## 3. Functional Requirements
| ID | Requirement | Acceptance Criteria |
| --- | --- | --- |
| FR-1 | Lesson consumption | Users can stream/download lessons with synchronized overlays; progress persisted per profile. 7 exercise types supported. |
| FR-2 | Roleplay exercises | Roleplay overlay handles question branching and multi-step prompts with state recovery after app pause. AI-driven conversations. |
| FR-3 | Course catalog | Browse courses, view roadmap with level indexing, track progress across lessons. |
| FR-4 | Auth & profile | Support email/password + Google + Apple + Anonymous login; profile updates sync across sessions. Firebase Auth integration. |
| FR-5 | Monetization | In-app purchases/subscriptions unlock premium content; entitlements refreshed on launch. |
| FR-6 | Progress tracking | Track user progress across lessons, exercises, achievements; HydratedCubit persistence. |
| FR-7 | Localization | Entire UI localizable (en/vi/zh); l10n strings pulled from Google Sheets and regenerated via `slang`. |
| FR-8 | Notifications | Push notifications delivered via Firebase Messaging with deep links routing into specific lessons. |
| FR-9 | Onboarding | Multi-step onboarding flow with data collection (9 steps). |
| FR-10 | Settings | Theme switching, locale selection, app preferences persisted via HydratedBloc. |

## 4. Non-Functional Requirements
| Category | Requirement |
| --- | --- |
| Performance | Cold start <3s on mid-tier Android/iOS devices; lesson playback latency <500ms after asset fetch. |
| Reliability | Crash-free sessions ≥ 99%; critical flows covered by automated tests. |
| Security | OAuth tokens stored securely (`flutter_secure_storage`); secrets never committed. |
| Maintainability | Feature modules capped at <200 LOC per file; TaskEither ensures consistent error handling. |
| Observability | Crashlytics + Sentry events triaged weekly; analytics funnels defined for onboarding, lesson completion, purchases. |

## 5. Constraints & Dependencies
- Flutter 3.x/Dart 3.10+ (per `pubspec.yaml` environment).
- Firebase services per flavor; environment variables supplied only via `--dart-define-from-file`.
- Build tooling relies on macOS/Linux/Windows parity scripts; iOS distribution limited to macOS.
- `.info/` directory must remain synchronized with tooling; missing config blocks builds/distribution.

## 6. Assumptions
- Backend APIs (REST/GraphQL) deliver all lesson, progress, and monetization data; app does not host business logic.
- QA and release managers can access Firebase tester groups configured via `.info/distribution/*.txt`.
- External services (payment gateways, Firebase) remain available with minimal downtime.

## 7. Success Metrics
- DAU retention across lesson cohorts improves ≥15% after roleplay overlay enhancements.
- Build pipeline throughput: <10 minutes for APK/AppBundle builds via automation.
- Crash-free rate ≥99% on latest release; top crashes triaged within 24h.
- Onboarding funnel completion ≥85% for new installs.

## 8. Implementation Guidance
- Scaffold new features with `mason make feature_clean` to enforce folder conventions.
- Register dependencies via `injectable` annotations; run `dart run build_runner build` after DI changes.
- Maintain TaskEither pipelines end-to-end; cubits fold results and emit typed states.
- Document environment-specific behaviors in `docs/system-architecture.md` and `docs/code-standards.md` when changed.

## 9. Version History
| Version | Date | Changes |
| --- | --- | --- |
| 0.3 | 2026-01-12 | Added all 13 feature modules, updated functional requirements, refined acceptance criteria with specific implementation details. |
| 0.2 | 2026-01-07 | Updated documentation timestamps and aligned requirements with current tooling/architecture. |

## 10. Risks & Mitigations
| Risk | Impact | Mitigation |
| --- | --- | --- |
| Tooling drift across OSes | Builds fail on Linux/Windows | Mirror macOS script changes into other platforms immediately; run `tools/smoke.sh`. |
| API contract changes | Runtime crashes | Formalize API docs, add pact tests, update feature modules with migration guides. |
| Localization lag | Users see stale strings | Enforce localization pull/slang run before release freeze; add CI check watching `assets/i18n`. |
| Store review blockers | Delayed releases | Keep `.info/key/` assets updated; run `build_ipa.sh`/`build_appbundle.sh` smoke builds ahead of deadlines. |

## 11. Backlog & Next Steps
1. Author API contract documentation per feature (Auth, Lesson, Roleplay).
2. Define onboarding troubleshooting FAQ for support teams.
3. Automate `.info/` validation inside CI to catch missing testers/keys.
4. Extend observability docs with dashboard links once analytics stable.

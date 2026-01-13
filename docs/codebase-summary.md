# Codebase Summary

_Last updated: 2026-01-12_

## Snapshot
- **Tech stack**: Flutter 3/Dart 3.10+, Clean Architecture, BLoC/HydratedBloc, Dio + Retrofit + GraphQL, get_it + injectable, TaskEither via `fpdart`.
- **Repo size**: ~728K total LOC (~139K in lib/), 13 feature modules, ~29K config/core, ~18K tooling.
- **CI workflows**: `.github/workflows/android-ci-cd.yml`, `.github/workflows/tools-smoke.yml`.

## Architectural Layout
- `lib/config/`: Application-level wiring (routes, DI bootstrap, theming, localization assets, services).
- `lib/core/`: Cross-cutting primitives (base classes, constants, helpers, UI utilities, generated assets under `core/constants/gen`).
- `lib/src/<feature>/`: Feature pods (auth, course, lesson, roleplay, monetization, onboarding, etc.) each respecting domain/data/presentation boundaries.
- `.info/`: Canonical configuration store for build metadata, Firebase apps, distribution lists, and credentials referenced by tooling.
- `tools/<os>/`: Parity scripts for macOS/Linux/Windows with shared command surface for builds, localization, distribution, and project bootstrap.

## Tooling & Automation
- `tools/macos|linux|windows` directories encapsulate build, config, localization, distribution, and smoke-test scripts. Inputs resolved from `.info/app/*.json` and `.info/distribution/*.txt`.
- Localization workflow: `tools/<os>/localization/localization.sh pull` → edit Google Sheets/YAML → `slang` + `slang_build_runner` regeneration.
- Build workflows: `build_apk.sh`, `build_appbundle.sh`, `build_ios.sh`, `build_ipa.sh` with flavor flags (`dev|stg|prod`). Distribution helpers upload artifacts and Crashlytics symbols automatically.
- Developer bootstrap: `tools/<os>/config/setup_project.sh` plus smoke tests (`tools/smoke.sh`, `tools/windows/smoke.bat`).

## Dependency Highlights (pubspec.yaml)
- **UI/UX**: `flutter_svg`, `flutter_animate`, `flutter_screenutil`, `lottie`, `fl_chart`, `cached_network_image`.
- **State/Data**: `flutter_bloc ^9.1.1`, `hydrated_bloc ^10.1.1`, `fpdart ^1.2.0`, `freezed`, `json_serializable`.
- **Networking**: `dio ^5.9.0`, `retrofit ^4.9.2`, `graphql_flutter`, `app_links`.
- **Platform services**: Firebase suite (`firebase_core`, `firebase_auth`, `firebase_remote_config`, `firebase_messaging`, `firebase_crashlytics`, `firebase_analytics`), `in_app_purchase ^3.2.3`, notifications, storage, audio/video, connectivity.
- **Tooling**: `build_runner`, `injectable_generator ^2.7.1`, `go_router_builder`, `flutter_gen_runner`, `slang_build_runner`, `graphql_codegen`, `flutter_launcher_icons`, `flutter_flavorizr`.

## Testing & Quality Gates
- Workflow: `dart run build_runner build`, `flutter analyze`, `flutter test` (or scoped suites), optional coverage runs.
- TaskEither adoption complete—repositories, use cases, and cubits interact via lazy `TaskEither<AppException, T>` pipelines.
- Mason bricks (e.g., `feature_clean`) scaffold feature modules; enforce consistent folder structures and test scaffolding.

## Deployment & Environment Strategy
- Three flavors: `dev`, `stg`, `prod` with dedicated entry points (`main_<flavor>.dart`) and `.env/.env.<flavor>` consumed through `--dart-define-from-file` only.
- `.info/app/build.json` governs Flutter version manager selection (puro/fvm/system), build arguments, and artifact destinations.
- `.info/distribution/*.txt` extends Firebase distribution lists with per-build overrides (testers, groups, release notes, devices, passwords).
- Scripts ensure Crashlytics symbol upload, Firebase app config sync, and parity across platforms except iOS-specific flows (macOS only).

## Active Feature Modules (lib/src/)
| Module | Files | LOC | Purpose |
| --- | --- | --- | --- |
| `common` | 43 | 28K | Shared utilities, error pages, common UI components |
| `lesson` | 120 | 22K | 7 exercise types, learning content delivery, synchronized overlays |
| `roleplay` | 66 | 10.5K | Conversation-based AI learning, dialogue scenarios |
| `course` | 63 | 9K | Course catalog, roadmap with level indexing, course browser |
| `progress` | 34 | 8K | User progress tracking, achievements, learning metrics |
| `auth` | 48 | 5.6K | Firebase Auth + SSO (Google/Apple/Anonymous), session management |
| `monetization` | 38 | 5.5K | In-app purchases, subscriptions, entitlement management |
| `onboard` | 37 | 5.5K | Multi-step onboarding flow, user journey |
| `profile` | 35 | 4.7K | User profile management (HydratedCubit), preferences |
| `data_collect` | 45 | 4K | 9-step data collection workflow |
| `home` | 22 | 2.6K | Home screen, skillset browser, navigation hub |
| `achievement` | 15 | 2.3K | Achievements system, gamification |
| `setting` | 14 | 1.4K | App settings (locale, theme), preferences UI |

## Observability & Security
- Crash reporting: `firebase_crashlytics`, `sentry_flutter`.
- Analytics: `firebase_analytics`.
- Permissions: `permission_handler`, `app_tracking_transparency`, platform dialogs orchestrated through shared helpers.
- Secrets: Sensitive signing/config files kept under `.info/key/` and excluded from version control + repomix outputs.

## Recommended Next Steps
1. Expand documentation coverage for API contracts per feature once domain models stabilize.
2. Wire automated validation that `.info/` mirrors `tools` expectations (currently manual via scripts).

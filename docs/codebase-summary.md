# Codebase Summary

_Last updated: 2025-12-24_

## Snapshot
- **Tech stack**: Flutter 3/Dart 3.10+, Clean Architecture, BLoC/HydratedBloc, Dio + Retrofit + GraphQL, get_it + injectable, TaskEither via `fpdart`.
- **Repo size (repomix 2025-12-24)**: 998 tracked files, ~3.4M characters (~809k tokens). Largest contributors are `pubspec.lock`, localization CLI scripts, and `lib/config/themes/theme_collection.dart`.
- **Security exclusions**: `.info/key/*.p8`, `.info/key/*.json`, and `.info/distribution/test_password.txt` flagged and omitted from packs.
- **Binary artifacts**: Mason hook `.dill` files excluded from compaction.
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
- **State/Data**: `bloc`, `flutter_bloc`, `hydrated_bloc`, `fpdart`, `freezed`, `json_serializable`.
- **Networking**: `dio`, `retrofit`, `graphql_flutter`, `app_links`.
- **Platform services**: Firebase suite (`firebase_core`, `firebase_auth`, `firebase_remote_config`, `firebase_messaging`, `firebase_crashlytics`, `firebase_analytics`), in-app purchases, notifications, storage, audio/video, connectivity.
- **Tooling**: `build_runner`, `injectable_generator`, `go_router_builder`, `flutter_gen_runner`, `slang_build_runner`, `graphql_codegen`, `flutter_launcher_icons`, `flutter_flavorizr`.

## Testing & Quality Gates
- Workflow documented in `TEST.md`: `dart run build_runner build`, `flutter analyze`, `flutter test` (or scoped suites), optional coverage runs.
- TaskEither adoption complete—repositories, use cases, and cubits interact via lazy `TaskEither<AppException, T>` pipelines.
- Mason bricks (e.g., `feature_clean`) scaffold feature modules; enforce consistent folder structures and test scaffolding.

## Deployment & Environment Strategy
- Three flavors: `dev`, `stg`, `prod` with dedicated entry points (`main_<flavor>.dart`) and `.env/.env.<flavor>` consumed through `--dart-define-from-file` only.
- `.info/app/build.json` governs Flutter version manager selection (puro/fvm/system), build arguments, and artifact destinations.
- `.info/distribution/*.txt` extends Firebase distribution lists with per-build overrides (testers, groups, release notes, devices, passwords).
- Scripts ensure Crashlytics symbol upload, Firebase app config sync, and parity across platforms except iOS-specific flows (macOS only).

## Active Feature Pods
| Feature | Notes |
| --- | --- |
| `auth` | Authentication flows, social login (Google/Apple) via Firebase + platform services |
| `lesson` | Exercise delivery, question overlays (recent commits), audio/video integrations |
| `roleplay` | Dialogue/roleplay scenarios with overlay management |
| `monetization` | In-app purchases, entitlements, subscription UX |
| `home`, `profile`, `progress`, `setting` | Core app surfaces for dashboards, account management, user prefs |
| `data_collect`, `onboard`, `course` | Acquisition funnels, onboarding sequences, course catalogs |

## Observability & Security
- Crash reporting: `firebase_crashlytics`, `sentry_flutter`.
- Analytics: `firebase_analytics`.
- Permissions: `permission_handler`, `app_tracking_transparency`, platform dialogs orchestrated through shared helpers.
- Secrets: Sensitive signing/config files kept under `.info/key/` and excluded from version control + repomix outputs.

## Recommended Next Steps
1. Keep repomix snapshot refreshed before major releases to detect large binary drift.
2. Expand documentation coverage for API contracts per feature once domain models stabilize.
3. Wire automated validation that `.info/` mirrors `tools` expectations (currently manual via scripts).

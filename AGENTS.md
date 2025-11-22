# Repository Guidelines

## Quick References
- Architecture overview: `CLAUDE.md`.
- Localization config: `.info/app/localization.json`, `slang.yaml`.
- Flavors: `flavorizr.yaml`, `main_<flavor>.dart`, `.env.dev/.stg/.prod`.

## Project Structure & Module Organization
- Features under `lib/src/<feature>/{data,domain,presentation}`; UI stays in `presentation`, business logic in `domain`, IO/adapters in `data`.
- App-wide config in `lib/config/` (DI, routes, l10n, themes); shared utilities in `lib/core/`.
- Shared widgets in `lib/src/presentation/widgets`; prefer reuse over feature-local clones.
- Localization YAML lives in `assets/i18n/<locale>/<module>.yaml`; generated l10n Dart in `lib/config/l10n/`.
- Tests mirror features in `test/unit/<feature>/`.

## Build, Test, and Development Commands
- Deps: `flutter pub get`.
- Codegen: `dart run build_runner build --delete-conflicting-outputs`; watch: `dart run build_runner watch --delete-conflicting-outputs`; clean: `dart run build_runner clean`.
- Analysis/format: `flutter analyze`; `dart format lib/ test/`.
- Tests: `flutter test` (all) or `flutter test test/unit/` (unit-only).
- Localization: macOS/Linux `tools/macos/localization/localization.sh ...` or `tools/linux/localization/localization.sh ...`; Windows `tools/windows/localization/localization.bat ...`; regenerate Dart with `flutter pub run slang`.
- Builds: `./tools/macos/build/build_apk.sh <flavor>` / `build_appbundle.sh`; iOS `./tools/macos/build/build_ios.sh <flavor>`. After flavor changes: `flutter clean && dart run flutter_flavorizr && flutter pub get`.

## Coding Style & Architecture
- Dart 2-space indent; files/dirs in `snake_case.dart`; types in `PascalCase`; Cubit/BLoC suffixed `Cubit`/`Bloc`.
- Enforce flow: Widget → Cubit/BLoC → UseCase → Repository interface → Data source; do not expose `dio`/`graphql` types beyond data layer.
- DI: annotate with `injectable` (`@LazySingleton`, `@factoryMethod`); resolve via `get_it`.
- Never edit generated files (`*.g.dart`, `*.config.dart`, Retrofit outputs); rerun generators instead.

## Testing Guidelines
- Name tests `<target>_test.dart`; colocate under `test/unit/<feature>/`.
- Add widget/golden tests when changing UI rendering; mock injected services and storage for `hydrated_bloc`.
- Aim to cover new logic paths; run `flutter test` before PR; cover success/error branches.

## Commit & Pull Request Guidelines
- Branches: `feature/MEUP-123-description` (or `fix/…`, `chore/…`).
- Commits: `type-MEUP-123: summary` (e.g., `feat-MEUP-123: add artwork cache`).
- PR checklist: summary + ticket; UI screenshots/GIFs; `flutter analyze`, `flutter test`; note if `build_runner`/`slang` ran; flag flavor/env touched.

## Flavor & Environment Tips
- Env mapping: dev → `.env.dev`/`main_dev.dart`; stg → `.env.stg`/`main_stg.dart`; prod → `.env.prod`/`main_prod.dart`.
- Keep real secrets out of VCS; copy sample values locally. Re-run `flutter_flavorizr` when flavor settings change.

## Security & Configuration
- Do not commit `google-services.json`, `GoogleService-Info.plist`, keystores, Apple provisioning, or localization SA JSON; use `LOCALIZATION_SA_PATH`/`LOCALIZATION_SA_JSON` for pushes.
- Release builds expect `--obfuscate --split-debug-info`; store symbols in `.obfuscation/` and upload to Crashlytics with releases.

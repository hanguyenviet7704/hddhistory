# Codex Agent Playbook

## Purpose
- Give the Codex agent the minimum viable context to work confidently inside the Meup Flutter repository.
- Highlight guardrails that keep the clean architecture, generated code, and multi-flavor setup intact.
- Point to the highest-leverage commands and scripts so the agent can validate changes quickly.

## Project Snapshot
- **App**: Meup, an art-education Flutter app built with Clean Architecture.
- **Key themes**: feature-based folders under `lib/src`, strong separation of data/domain/presentation, heavy use of code generation, and flavor-specific bootstrapping.
- **State management**: `flutter_bloc` + `hydrated_bloc`.
- **Dependency injection**: `get_it` orchestrated by `injectable`.
- **Networking**: `dio` + `retrofit`, plus GraphQL via `graphql_flutter`.

## Repo Layout Cues
- `lib/config/`: app-wide configuration (DI, routes, l10n, services, themes, shared utilities).
- `lib/core/`: constants and reusable utils that cross features.
- `lib/src/`: feature source with clean architecture layers (`data`, `domain`, `presentation`).
- `tools/macos/`: build, config, and distribution scripts (invoked from repo root).
- `.env/`: flavor-specific environment files (`.env.dev`, `.env.stg`, `.env.prod`).

## High-Value Commands
```bash
# Dependencies
flutter pub get

# Code generation (run after touching models, DI, routes, Retrofit clients, etc.)
dart run build_runner build --delete-conflicting-outputs

# Cleaning build_runner artifacts
dart run build_runner clean

# Tests
flutter test                # whole suite
flutter test test/unit/     # unit tests only

# Static analysis & formatting
flutter analyze
dart format lib/ test/
```

## Localization (slang + Sheets)
- Active sheet is defined in `.info/app/localization.json` (`googleSheets.active.sheetId/tabs`). Module comes from the tab name; no “Module” column is required. Config also sets paths/columns/locales.
- Optional `UpdatedAt` column is supported; pushes auto-stamp new/changed rows.
- Commands (per platform wrappers, same flags):  
  - Linux/macOS: `tools/<platform>/localization/localization.sh pull|push|migrate|validate`  
  - Windows: `tools/windows/localization/localization.bat pull|push|migrate|validate`
- Creds for push: set `LOCALIZATION_SA_PATH` (or `LOCALIZATION_SA_JSON`); defaults read from `.info/app/localization.json`.
- Outputs: YAML per locale/module under `assets/i18n/<locale>/<module>.yaml`, generated Dart under `lib/config/l10n/l10n*.dart` (`output_file_name: l10n.g.dart`). Regenerate with `flutter pub run slang` (slang_build_runner also enabled).
- Migration helpers: `migrate --source sheet` (legacy sheet id) or `--source arb`; zh gaps fall back to en. Template lives at `.info/templates/sample_localization.csv`.
- Usage in code: wrap app with `TranslationProvider` (see `lib/main.dart`) and access via `context.text.<module>.<key>(params)`. Avoid old `gen-l10n` ARB workflow.

## Development Guardrails
- Respect clean architecture boundaries: route all business logic through `domain` use cases, keep UI-specific logic inside `presentation`.
- Do not hand-edit generated files; rerun the relevant generator instead.
- Add or update Cubits/BLoCs within their feature scope; consider hydrated storage when state persistence matters.
- Touch flavor-specific bootstrapping (`main_dev.dart`, etc.) only when environment differences demand it.
- Keep commit messages aligned with `type-TICKET-ID: description` if you need to draft examples.

## Testing & QA
- Prefer targeted unit/widget tests inside `test/unit/` following existing patterns.
- Use `flutter test --coverage` for coverage checks when the task warrants it.
- Run `flutter analyze` before concluding significant refactors.
- Note that widget rendering can depend on injected services; mock via existing testing utilities where possible.

## Build & Distribution Notes
- Android builds: `./tools/macos/build/build_apk.sh <flavor>` or `build_appbundle.sh`.
- iOS/TestFlight: `./tools/macos/build/build_ios.sh <flavor>` and `build_ipa.sh`.
- Release builds expect `--obfuscate` and `--split-debug-info`; Crashlytics symbols live in `.obfuscation/`.

## Troubleshooting Cheatsheet
- **build_runner conflicts**: `dart run build_runner clean` then rebuild with `--delete-conflicting-outputs`.
- **Pod issues**: from `ios/`, run `pod install --repo-update`.
- **Gradle hiccups**: `cd android && ./gradlew clean` followed by `flutter clean && flutter pub get`.
- **Flavor regeneration**: `flutter clean && dart run flutter_flavorizr && flutter pub get`.

## When In Doubt
- Check `CLAUDE.md` for the longer-form architecture overview.
- Look at `.cursorrules` for commit and review etiquette.
- Favor reusable widgets under `lib/src/presentation/widgets` before creating new ones.
- Keep an eye on Dio interceptors and BLoC logging when debugging network/state issues.

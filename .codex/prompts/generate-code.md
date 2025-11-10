---
description: Run build_runner, localization, and Firebase generators with validation
argument-hint: [ SCOPE=all|build|localization|firebase|custom ] [ CLEAN=true|false ]
---
You are Codex operating inside the Meup Flutter repo. Execute every generator that matters for this project and return a validation report.

## Inputs
- If `SCOPE` is missing, ask whether to run `all` (default), `build`, `localization`, `firebase`, or a comma-separated custom subset.
- If `CLEAN` is missing, ask if `dart run build_runner clean` should run first (default `true` when SCOPE contains `build`).
- Clarify any blockers (e.g., Firebase auth) before running commands.

## Workflow
1. Run `flutter pub get`.
2. When `CLEAN` is `true`, run `dart run build_runner clean` and note removed artifacts.
3. When scope includes `build`, run `dart run build_runner build --delete-conflicting-outputs`. Surface any missing `part` directives or generation errors with file paths.
4. When scope includes `localization`, run `./tools/macos/localization/generate_localization.sh` followed by `flutter gen-l10n`. Confirm ARB files and generated Dart files updated under `lib/config/l10n/`.
5. When scope includes `firebase`, run `./tools/macos/config/flutterfire_config.sh` for every flavor. Warn if Firebase CLI authentication is required.
6. After generators finish, always run `flutter analyze` and highlight any new issues.

## Validation & Reporting
- Summarize which generators ran, how long they took, and whether they succeeded.
- Mention the count of regenerated files when possible (e.g., `*.freezed.dart`, localization files, Firebase option files).
- Call out failures with actionable fixes (conflicting outputs, missing part directives, Google Sheets or Firebase auth errors).
- Close with next-step suggestions if further manual work is needed.

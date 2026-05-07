# Deployment Guide

**Last Updated:** 2026-05-07
**Scope:** local builds, CI builds, distribution readiness

## 1. Runtime and Platform Baseline
- Flavors: `dev`, `stg`, `prod`.
- Entry points: `lib/main_dev.dart`, `lib/main_stg.dart`, `lib/main_prod.dart`.
- Flavor builds use `--dart-define-from-file`; keep real values in local/CI secret sources.
- Dart SDK: `>=3.11.0 <4.0.0`.
- iOS minimum target: `15.0`.

## 2. Local Setup
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Setup helpers:
```bash
# macOS
tools/macos/config/setup_project.sh

# Linux
tools/linux/config/setup_project.sh

# Windows
tools\\windows\\config\\setup_project.bat
```

Smoke checks:
```bash
# macOS/Linux
tools/smoke.sh

# Windows
tools\\windows\\smoke.bat
```

## 3. Build Commands by Platform
### Android (macOS)
```bash
tools/macos/build/build_apk.sh <dev|stg|prod>
tools/macos/build/build_appbundle.sh <dev|stg|prod>
```

### Android (Linux)
```bash
tools/linux/build/build_apk.sh <dev|stg|prod>
tools/linux/build/build_appbundle.sh <dev|stg|prod>
```

### Android (Windows)
```bat
tools\windows\build\build_apk.bat <dev|stg|prod>
tools\windows\build\build_appbundle.bat <dev|stg|prod>
```

### iOS (macOS only)
```bash
tools/macos/build/build_ios.sh <dev|stg|prod>
tools/macos/build/build_ipa.sh <dev|stg|prod>
```

## 4. CI-Safe Build Flags and Symbol Upload Behavior
### `--ci` support
- Supported: macOS/Linux Android build scripts (`build_apk.sh`, `build_appbundle.sh`).
- Not supported: Windows `.bat` Android build scripts.

`--ci` behavior:
- hides env file content in logs,
- skips automatic output-folder open.

### `SKIP_SYMBOL_UPLOAD` behavior
- Supported on macOS/Linux Android scripts (`build_apk.sh`, `build_appbundle.sh`).
- When truthy, Crashlytics symbol upload is skipped.
- Not currently supported on Windows Android build scripts (they always attempt symbol upload).

### iOS symbol behavior
- `build_ipa.sh` documents automatic Crashlytics symbol upload via Xcode build phase.
- `build_ios.sh` attempts Crashlytics upload through setup script.

## 5. Localization Deployment Workflow
### Command parity
```bash
# macOS
tools/macos/localization/localization.sh <pull|push|validate|slang|cache-gids>

# Linux
tools/linux/localization/localization.sh <pull|push|validate|slang|cache-gids>

# Windows
tools\\windows\\localization\\localization.bat <pull|push|validate|slang|cache-gids>
```

### Recommended flow
1. `pull`
2. Edit localization data
3. `push --apply`
4. `pull`
5. `slang`
6. Optional cache refresh: `cache-gids --ensure-readme`

## 6. CI/CD Overview
### GitHub Actions
- Entry workflow: `.github/workflows/flutter-ci.yml`.
- Delegates to reusable macOS or Linux pipeline based on `ENABLE_LINUX_PIPELINE`.
- Main stages: prepare generated artifacts -> analyze/test -> conditional build/distribution.

### GitLab CI
- Top-level file: `.gitlab/ci/pipeline.yml`.
- Current top-level includes are macOS templates.
- Linux templates exist under `.gitlab/ci/linux/` for reusable/parallel adoption.

## 7. CI Variable Contract
### Build and stage toggles
- `ENABLE_BUILD_DEV`
- `ENABLE_BUILD_STG`
- `ENABLE_BUILD_PROD`
- `ENABLE_DISTRIBUTE_DEV`
- `ENABLE_DISTRIBUTE_STG`
- `ENABLE_DISTRIBUTE_PROD`
- `ENABLE_FASTLANE`
- `ENABLE_LINUX_PIPELINE` (GitHub selection)

### Runtime bootstrap inputs (`.gitlab/scripts/bootstrap-secrets.sh`)
Environment files (either file variable or inline content):
- `ENV_DEV_FILE` or `ENV_DEV_CONTENT`
- `ENV_STG_FILE` or `ENV_STG_CONTENT`
- `ENV_PROD_FILE` or `ENV_PROD_CONTENT`

Localization:
- `LOCALIZATION_SA_PATH` or `LOCALIZATION_SA_JSON`

Android fastlane contract:
- `PLAYSTORE_JSON_FILE` or `PLAYSTORE_JSON`

iOS fastlane contract:
- `APPSTORE_P8_FILE` or `APPSTORE_P8`
- `APPSTORE_ISSUER_ID`
- `APPSTORE_KEY_ID`

Distribution:
- `FIREBASE_TOKEN` (required for Firebase distribution jobs)

Pipeline behavior:
- CI jobs export `CI=true` and `SKIP_SYMBOL_UPLOAD=true` before Android builds.

## 8. Distribution Paths
### Android Firebase distribution
- macOS/Linux CI distribution jobs call `tools/macos/distribution/distribute_android.sh`.
- Local script-driven distribution is available via build script `--distribute` on macOS/Linux/Windows APK scripts.

### iOS distribution
- Use `tools/macos/distribution/distribute_ios.sh` for Firebase/TestFlight paths.
- Fastlane skeleton checks verify contract readiness, lanes, and credentials.

## 9. Release Checklist
1. Confirm env files and keys are supplied through CI variables or secure files.
2. Confirm localization pull/slang generation is clean.
3. Confirm `flutter analyze` and `flutter test` pass.
4. Confirm build toggles match target flavor release intent.
5. Confirm symbol-upload policy (`SKIP_SYMBOL_UPLOAD`) matches build purpose.

## 10. Troubleshooting
### Build prints env content in logs
- Use `--ci` on macOS/Linux build scripts.
- On Windows, no `--ci` switch exists currently.

### Symbol upload should be skipped but still runs
- On macOS/Linux set `SKIP_SYMBOL_UPLOAD=true`.
- On Windows this variable is not currently honored by build scripts.

### GitLab/Linux jobs not running from top-level pipeline
- Check `.gitlab/ci/pipeline.yml` include targets.
- Linux templates exist, but current top-level include points to macOS set.

### Localization failures in CI
- Confirm `LOCALIZATION_SA_PATH` or `LOCALIZATION_SA_JSON` is provided.
- Re-run `pull` then `slang` to validate generation path.

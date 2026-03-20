# GitLab CI/CD Setup Guide

**Last Updated:** 2026-02-27  
**Scope:** `.gitlab/ci/*` pipelines and required variable contracts

## 1. Pipeline Topology
Top-level pipeline file:
- `.gitlab/ci/pipeline.yml`

Current top-level includes target macOS templates:
- `.gitlab/ci/macos/00-workflow.yml`
- `.gitlab/ci/macos/10-prepare.yml`
- `.gitlab/ci/macos/20-quality.yml`
- `.gitlab/ci/macos/30-build.yml`
- `.gitlab/ci/macos/40-release-skeleton.yml`
- `.gitlab/ci/macos/45-firebase-distribution.yml`

Linux template files also exist under `.gitlab/ci/linux/` and can be used for alternative include strategy.

## 2. Pipeline Stages
Defined stages:
1. `prepare`
2. `quality`
3. `build`
4. `release_skeleton`

Typical flow:
- prepare generated artifacts -> analyze/test -> conditional build jobs -> optional release skeleton/distribution jobs.

## 3. Trigger Rules
Workflow rules run on:
- merge requests
- `develop` branch
- `main` branch
- tags matching `v*`

## 4. Bootstrap and Secret Injection
Bootstrap script:
- `.gitlab/scripts/bootstrap-secrets.sh`

Script responsibilities:
1. Creates `.env/.env.dev|stg|prod` from CI vars if provided.
2. Writes optional key files under `.info/key/`.
3. Generates `build/ci/runtime.env` with exported runtime values.
4. Falls back to `.info/app/firebase.json` token when `FIREBASE_TOKEN` is not set.

## 5. CI Variable Contract
### 5.1 Build/distribution toggles
- `ENABLE_BUILD_DEV`
- `ENABLE_BUILD_STG`
- `ENABLE_BUILD_PROD`
- `ENABLE_DISTRIBUTE_DEV`
- `ENABLE_DISTRIBUTE_STG`
- `ENABLE_DISTRIBUTE_PROD`
- `ENABLE_FASTLANE`

### 5.2 Environment payloads (one of each pair)
- `ENV_DEV_FILE` or `ENV_DEV_CONTENT`
- `ENV_STG_FILE` or `ENV_STG_CONTENT`
- `ENV_PROD_FILE` or `ENV_PROD_CONTENT`

### 5.3 Localization credentials
- `LOCALIZATION_SA_PATH` or `LOCALIZATION_SA_JSON`

### 5.4 Release skeleton credentials
Android:
- `PLAYSTORE_JSON_FILE` or `PLAYSTORE_JSON`

iOS:
- `APPSTORE_P8_FILE` or `APPSTORE_P8`
- `APPSTORE_ISSUER_ID`
- `APPSTORE_KEY_ID`

### 5.5 Distribution
- `FIREBASE_TOKEN` (required by Firebase distribution jobs)

## 6. CI Build Flags and Behavior
In build jobs, CI explicitly sets:
- `CI=true`
- `SKIP_SYMBOL_UPLOAD=true`

Then runs Android build scripts with `--ci` (macOS/Linux templates):
```bash
bash tools/<os>/build/build_apk.sh "$FLAVOR" --ci
bash tools/<os>/build/build_appbundle.sh prod --ci
```

## 7. `SKIP_SYMBOL_UPLOAD` Behavior
- macOS/Linux Android build scripts honor `SKIP_SYMBOL_UPLOAD=true` and skip Crashlytics symbol upload.
- Windows Android build scripts do not currently expose this skip behavior.

## 8. Script Parity Notes
- macOS/Linux: `.sh` wrappers support `--ci` in APK/AAB build scripts.
- Windows: `.bat` wrappers do not currently support `--ci`.
- Localization wrapper naming differs by platform:
  - macOS/Linux: `localization.sh`
  - Windows: `localization.bat`

## 9. Artifacts and Outputs
Common artifact expectations in build jobs:
- APK outputs under `build/app/outputs/flutter-apk/`
- AAB output under `build/app/outputs/bundle/prodRelease/`
- `.obfuscation/` split-debug-info artifacts

## 10. First-Time Setup Checklist
1. Add build/distribution toggle variables.
2. Add env payload variables for all flavors.
3. Add localization credential variable(s).
4. Add Firebase token for distribution jobs.
5. Add fastlane credential variables if release skeleton jobs are enabled.
6. Trigger pipeline on `develop` (build/test validation) and verify stage progression.

## 11. Quick Troubleshooting
### Build job is not created
- Verify branch/tag and corresponding `ENABLE_BUILD_*` switches.

### Distribution job fails early
- Verify `FIREBASE_TOKEN` is present.

### Localization fails in prepare stage
- Verify `LOCALIZATION_SA_PATH`/`LOCALIZATION_SA_JSON` and retry pull/slang commands.

### Runtime env is missing in job
- Check whether `build/ci/runtime.env` was generated and sourced in `before_script`.

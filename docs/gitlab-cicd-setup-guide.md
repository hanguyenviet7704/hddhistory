# GitLab CI/CD Setup Guide (Meup)

**Last Updated:** Feb 24, 2026  
**Scope:** GitLab CI V1 (Android build-first, fastlane skeleton only)

## 1. Why this pipeline exists
Think of CI/CD as a factory:
- `prepare`: prepare raw materials
- `quality`: quality gate
- `build`: package products
- `release_skeleton`: verify release desk is ready (manual)

This keeps mistakes caught early and build outputs consistent across branches.

## 2. What runs on each trigger
| Trigger | What runs |
|---|---|
| Merge Request | `prepare + quality` (quality runs only when relevant code/build files change) |
| Push `develop` | Build APK for enabled flavors (`ENABLE_BUILD_DEV/STG=1`) + optional Firebase Distribution |
| Push `main` | `prepare + quality +` build APK/AAB for enabled flavors (`ENABLE_BUILD_DEV/STG/PROD=1`) + optional Firebase Distribution (`prod`) |
| Tag `v*` | Same as `main` |

## 3. Pipeline files
- `.gitlab-ci.yml` (entry)
- `ci/templates/00-workflow.yml` (workflow, defaults, cache)
- `ci/templates/10-prepare.yml`
- `ci/templates/20-quality.yml`
- `ci/templates/30-build.yml`
- `ci/templates/40-release-skeleton.yml`
- `ci/templates/45-firebase-distribution.yml`
- `ci/scripts/bootstrap-secrets.sh`

## 4. Runtime requirements
For Linux runner jobs:
- `flutter`, `dart`
- `jq`, `python3`, `python3-venv`, `python3-pip`

The pipeline installs missing runtime deps in job `before_script` only when needed.  
If you use a custom image that already has tools, set:
- `CI_IMAGE=<your-image>`
- `CI_SKIP_SYSTEM_SETUP=1`

## 5. CI variable contract
### Required for portable mode
- `ENV_DEV_FILE` or `ENV_DEV_CONTENT`
- `ENV_STG_FILE` or `ENV_STG_CONTENT`
- `ENV_PROD_FILE` or `ENV_PROD_CONTENT`

### Recommended
- `LOCALIZATION_SA_JSON` (for localization pull in CI)

### Optional (phase-2 release)
- `ENABLE_FASTLANE=1`
- `PLAYSTORE_JSON`
- `APPSTORE_P8`
- `APPSTORE_ISSUER_ID`
- `APPSTORE_KEY_ID`

### Optional (Firebase distribution)
- `ENABLE_BUILD_DEV=1`
- `ENABLE_BUILD_STG=1`
- `ENABLE_BUILD_PROD=1`
- `ENABLE_DISTRIBUTE_DEV=1`
- `ENABLE_DISTRIBUTE_STG=1`
- `ENABLE_DISTRIBUTE_PROD=1`
- `FIREBASE_TOKEN`

## 6. How bootstrap works
`ci/scripts/bootstrap-secrets.sh` does this:
1. Creates `build/ci/runtime.env`
2. Maps `ENV_*` variables to `.env/.env.dev|stg|prod`
3. Writes localization SA file when provided
4. Writes optional fastlane credential files
5. Never prints secret values

Jobs then source `build/ci/runtime.env`.

## 7. Why CI mode matters
Build scripts now support `--ci` (or `CI=true`):
- hide `.env` content from logs
- skip opening output folders (`open`, `xdg-open`)
- keep behavior deterministic in non-interactive runners

And if `SKIP_SYMBOL_UPLOAD=true`, symbol upload is skipped (useful in V1 build-only).

## 8. Artifacts policy
Retention: **14 days**

Produced artifacts:
- Generated sources from `prepare`
- APKs from matrix build
- AAB for `prod`
- `.obfuscation` symbols for crash debugging

## 9. Release skeleton jobs
Manual only, gated by `ENABLE_FASTLANE=1`:
- `release:android:fastlane:skeleton`
- `release:ios:fastlane:skeleton` (requires macOS runner tag)

These jobs validate release contracts and lane readiness only. They do not publish apps in V1.

## 9.1 Firebase Distribution jobs
When `ENABLE_DISTRIBUTE_DEV=1` and `ENABLE_BUILD_DEV=1` on `develop`, pipeline runs:
- `release:android:firebase:distribution:dev`

When `ENABLE_DISTRIBUTE_STG=1` and `ENABLE_BUILD_STG=1` on `develop`, pipeline runs:
- `release:android:firebase:distribution:stg`

When `ENABLE_DISTRIBUTE_PROD=1` and `ENABLE_BUILD_PROD=1` on `main` or tag `v*`, pipeline runs:
- `release:android:firebase:distribution:prod`

These jobs use:
- `tools/macos/distribution/distribute_android.sh apk dev`
- `tools/macos/distribution/distribute_android.sh apk stg`
- `tools/macos/distribution/distribute_android.sh apk prod`

These jobs reuse APK artifacts via `needs`, so they do not rebuild APK.

## 10. First-time setup checklist
1. Add `.gitlab-ci.yml` and all `ci/templates/*`
2. Add `ci/scripts/bootstrap-secrets.sh`
3. Configure GitLab runner (Linux)
4. Add required CI variables in GitLab CI/CD settings
5. Push MR and verify `prepare` + conditional `quality`
6. Merge to `develop` and verify only enabled build flavors (`ENABLE_BUILD_DEV/STG`)
7. Merge to `main` and verify only enabled build flavors (`ENABLE_BUILD_DEV/STG/PROD`) + optional `prod` AAB
8. Push tag `v1.x.x` and verify same full matrix behavior

## 11. Quick debug playbook
### Localization pull fails
- Verify `LOCALIZATION_SA_JSON`
- Verify sheet permissions for service account
- Retry job after checking network

### Build fails due env file
- Check `ENV_*` variables
- Open job log and verify bootstrap summary (no secret values)
- Confirm `.env/.env.<flavor>` exists in workspace

### No build job appears on branch
- Check `workflow:rules` and job `rules`
- Confirm branch/tag matches policy (`develop`, `main`, `v*`)

## 12. Migration to another project
To reuse this architecture:
1. Copy `.gitlab-ci.yml`, `ci/templates/*`, `ci/scripts/bootstrap-secrets.sh`
2. Keep script interface unchanged (`tools/linux/build/*.sh`, localization script)
3. Update `.info/app/*.json` for new app/flavors/paths
4. Provide project-specific CI variables matching the same contract

## 13. Security note
Current repo still tracks sensitive files. CI masking is only minimum protection. Long-term safe state:
- remove secrets from git history
- move all credentials to protected CI variables/secrets manager

## Unresolved Questions
- None.

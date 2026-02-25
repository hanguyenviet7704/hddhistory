# Deployment Guide

**Last Updated:** Feb 10, 2026
**Status:** Production Ready

---

## 1. Environment Setup

### Prerequisites
- **macOS/Linux/Windows** with cross-platform build tools
- **Flutter SDK:** 3.41.2 (pinned for CI/CD; use `fvm` or `puro` locally if needed)
- **Dart SDK:** 3.10.0+ (comes with Flutter)
- **Java:** JDK 17+ (for Android builds)
- **Xcode:** 16.0+ (macOS for iOS builds)
- **Android Studio:** Latest (for Android SDK)

### Initial Setup

```bash
# Clone repository
git clone <repo-url>
cd meup

# Install dependencies
flutter pub get

# Generate code (required)
dart run build_runner build --delete-conflicting-outputs

# Verify setup
flutter doctor
flutter analyze
```

### Multi-Environment Configuration

```bash
# Create environment files (git-ignored)
mkdir -p .env

# Dev environment
cat > .env/.env.dev << EOF
API_BASE_URL=https://dev-api.meup.com
FIREBASE_PROJECT_ID=meup-dev-12345
SENTRY_DSN=https://key@sentry.io/project
EOF

# Staging environment
cat > .env/.env.stg << EOF
API_BASE_URL=https://stg-api.meup.com
FIREBASE_PROJECT_ID=meup-stg-12345
SENTRY_DSN=https://key@sentry.io/project
EOF

# Production environment
cat > .env/.env.prod << EOF
API_BASE_URL=https://api.meup.com
FIREBASE_PROJECT_ID=meup-prod-12345
SENTRY_DSN=https://key@sentry.io/project
EOF
```

---

## 2. Local Development Build

### Build for Development (Dev Flavor)

#### Android
```bash
# APK (for testing on device/emulator)
flutter build apk \
  --flavor dev \
  --dart-define-from-file=.env/.env.dev \
  -t lib/main_dev.dart

# Install on device
adb install build/app/outputs/flutter-apk/app-dev-release.apk

# Or using build script
./tools/macos/build/build_apk.sh dev
```

#### iOS (macOS only)
```bash
# Build app archive
flutter build ios \
  --flavor dev \
  --dart-define-from-file=.env/.env.dev \
  -t lib/main_dev.dart \
  --release

# Or using build script
./tools/macos/build/build_ios.sh dev
```

### Run Development Flavor

```bash
# Install and run on connected device
flutter run \
  --flavor dev \
  --dart-define-from-file=.env/.env.dev \
  -t lib/main_dev.dart

# Hot reload enabled for development
```

---

## 3. Build Variants & Flavors

### Three Flavors: Dev → Stg → Prod

| Flavor | Entry Point | Environment | Distribution |
|--------|------------|-------------|--------------|
| **dev** | `lib/main_dev.dart` | `.env/.env.dev` | Local/Firebase App Dist |
| **stg** | `lib/main_stg.dart` | `.env/.env.stg` | Firebase App Dist (QA) |
| **prod** | `lib/main_prod.dart` | `.env/.env.prod` | Google Play Store |

### Flavor Configuration (`.info/app/app.json`)

```json
{
  "flavors": {
    "dev": {
      "displayName": "Meup Dev",
      "packageName": "com.eup.meup.dev",
      "bundleId": "com.eup.meup.dev"
    },
    "stg": {
      "displayName": "Meup Staging",
      "packageName": "com.eup.meup.stg",
      "bundleId": "com.eup.meup.stg"
    },
    "prod": {
      "displayName": "Meup",
      "packageName": "com.eup.meup",
      "bundleId": "com.eup.meup"
    }
  }
}
```

---

## 4. CI/CD Pipeline Overview

### GitLab CI Workflow (`.gitlab-ci.yml`)

Pipeline definition is modular and lives in:
- `.gitlab-ci.yml`
- `ci/templates/00-workflow.yml`
- `ci/templates/10-prepare.yml`
- `ci/templates/20-quality.yml`
- `ci/templates/30-build.yml`
- `ci/templates/40-release-skeleton.yml`
- `ci/templates/45-firebase-distribution.yml`

#### Triggers
| Trigger | Environment | Target |
|---------|-----------|--------|
| `merge_request_event` | Validation | `prepare` + `quality` (quality chạy khi có thay đổi Dart/build config liên quan) |
| Push to `develop` | Dev/Staging | Build APK theo từng flavor được bật (`ENABLE_FIREBASE_DISTRIBUTION_DEV/STG=1`) + optional Firebase Distribution |
| Push to `main` | Full matrix | Build APK/AAB theo flavor được bật (`DEV/STG/PROD`) + optional Firebase Distribution (`prod`) |
| Git tag `v*` | Release candidate | Same as `main` full matrix |

#### Pipeline Stages

```
1. PREPARE
   ├─ bootstrap secrets/runtime files (`ci/scripts/bootstrap-secrets.sh`)
   ├─ localization pull (Google Sheets -> YAML)
   ├─ slang generation
   └─ build_runner generation

2. QUALITY
   ├─ flutter analyze
   └─ flutter test
   (MR: chỉ chạy khi thay đổi các file liên quan code/build như `lib/**`, `test/**`, `pubspec.yaml`, `build.yaml`, ...)

3. BUILD
   ├─ APK matrix by branch policy
   ├─ AAB prod on `main`/`v*`
   ├─ obfuscation symbols artifact
   └─ CI-safe mode (no raw env output in logs)

4. RELEASE_SKELETON
   ├─ Android Firebase Distribution (`dev`, `stg`) on `develop` (auto, gated by variable)
   ├─ Android Firebase Distribution (`prod`) on `main`/`v*` (auto, gated by variable)
   ├─ Android fastlane contract check (manual)
   └─ iOS fastlane contract check (manual, macOS runner)
```

### Access Requirements
- **GitLab Runner:** Linux for build pipeline, optional macOS runner for iOS fastlane skeleton.
- **GitLab CI/CD Variables:**
  - `CI_IMAGE` (optional override custom CI image)
  - `CI_SKIP_SYSTEM_SETUP=1` (optional, bật khi custom image đã preinstall jq/python/pip để bỏ bước `apt-get`)
  - `ENABLE_FIREBASE_DISTRIBUTION_DEV=1` (optional, bật auto upload APK `dev` lên Firebase App Distribution khi push `develop`)
  - `ENABLE_FIREBASE_DISTRIBUTION_STG=1` (optional, bật auto upload APK `stg` lên Firebase App Distribution khi push `develop`)
  - `ENABLE_FIREBASE_DISTRIBUTION_PROD=1` (optional, bật auto upload APK `prod` lên Firebase App Distribution khi push `main` hoặc tag `v*`)
  - `FIREBASE_TOKEN` (required nếu bật Firebase Distribution)
  - `ENV_DEV_FILE` / `ENV_DEV_CONTENT`
  - `ENV_STG_FILE` / `ENV_STG_CONTENT`
  - `ENV_PROD_FILE` / `ENV_PROD_CONTENT`
  - `LOCALIZATION_SA_JSON` (recommended when pulling l10n in CI)
  - `ENABLE_FASTLANE=1` (to enable manual skeleton jobs)
- **Optional phase-2 variables (fastlane release):**
  - `PLAYSTORE_JSON`
  - `APPSTORE_P8`, `APPSTORE_ISSUER_ID`, `APPSTORE_KEY_ID`

---

## 5. Release Process

### Pre-Release Checklist

```markdown
- [ ] All tests passing (flutter test)
- [ ] No analyzer warnings (flutter analyze)
- [ ] Code review approved
- [ ] Version bumped in pubspec.yaml
- [ ] Changelog updated (docs/project-changelog.md)
- [ ] Release notes prepared (.info/distribution/release_note.txt)
- [ ] Firebase project configured for new version
- [ ] Staging build verified on Firebase App Distribution
```

### Release Steps

#### 1. Staging Release (Firebase App Distribution)
```bash
# Push to main branch (triggers GitLab CI full build matrix)
git checkout main
git pull origin main

# Verify build in GitLab pipeline
# Check Firebase App Distribution for staging build
# QA team tests in Firebase

# Once QA approved: proceed to production
```

#### 2. Production Release (Google Play Store)

```bash
# Tag release (triggers production build)
git tag v1.0.0
git push origin v1.0.0

# GitLab CI automatically:
# 1. Builds APK + App Bundle (prod flavor)
# 2. Publishes build artifacts + obfuscation symbols
# 3. Phase-2 release jobs remain manual (fastlane skeleton gated)

# Monitor rollout in Google Play Console
# - Check crash rate
# - Check ANRs
# - Monitor user reviews
# - Gradually increase rollout to 100%
```

#### 3. iOS Release (via Xcode / App Store Connect)
```bash
# Build iOS archive
./tools/macos/build/build_ios.sh prod

# Or manual build
flutter build ios \
  --flavor prod \
  --dart-define-from-file=.env/.env.prod \
  -t lib/main_prod.dart \
  --release

# Generate IPA for App Store
./tools/macos/build/build_ipa.sh prod

# Upload to App Store Connect
# (Manual via Xcode organizer or Transporter CLI)
```

---

## 6. Build Commands Reference

### Development Commands

```bash
# Clean build artifacts
flutter clean
dart run build_runner clean

# Regenerate code (required after model changes)
dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate on changes)
dart run build_runner watch --delete-conflicting-outputs

# Format code
dart format lib/ test/

# Analyze code
flutter analyze

# Run tests
flutter test
flutter test test/unit/auth/  # Specific directory

# Run specific test file
flutter test test/unit/auth/auth_bloc_test.dart
```

### Build Commands (All Platforms)

```bash
# Android APK (dev)
flutter build apk \
  --flavor dev \
  --dart-define-from-file=.env/.env.dev \
  -t lib/main_dev.dart

# Android App Bundle (prod)
flutter build appbundle \
  --flavor prod \
  --dart-define-from-file=.env/.env.prod \
  -t lib/main_prod.dart

# iOS app (macOS)
flutter build ios \
  --flavor prod \
  --dart-define-from-file=.env/.env.prod \
  -t lib/main_prod.dart \
  --release

# iOS IPA (macOS)
flutter build ipa \
  --flavor prod \
  --dart-define-from-file=.env/.env.prod \
  -t lib/main_prod.dart \
  --export-options-plist=ios/ExportOptions.plist

# Or use build scripts
./tools/macos/build/build_apk.sh dev
./tools/macos/build/build_appbundle.sh prod
./tools/macos/build/build_ios.sh prod
./tools/macos/build/build_ipa.sh prod
```

---

## 7. Localization Workflow

### Pull Translations from Google Sheets

```bash
# macOS/Linux
tools/macos/localization/localization.sh pull

# Windows
tools\windows\localization\localization.bat pull
```

### Regenerate Dart Code

```bash
# After pulling YAML translations
tools/<os>/localization/localization.sh slang
```

### Push Translations Back

```bash
# Dry-run (check changes)
tools/macos/localization/localization.sh push

# Apply changes to Google Sheets
tools/macos/localization/localization.sh push --apply
```

### Workflow Summary
```
1. Developers/translators update Google Sheets
2. Pull YAML to assets/i18n/
3. Push YAML updates back with `tools/<os>/localization/localization.sh push --apply`
4. Pull YAML again to refresh
5. Run `tools/<os>/localization/localization.sh slang` to generate Dart code
6. Commit both YAML + generated code
7. UI uses context.text.module.keyName (auto-generated)
```

---

## 8. Signing & Certificates

### Android Signing (Production)

#### Create Keystore (First-time)
```bash
keytool -genkey -v -keystore meup.jks \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias meup-key \
  -storepass <password> \
  -keypass <password>

# Store in .info/key/ (git-ignored)
mv meup.jks .info/key/

# Add keystore/passwords to GitLab protected variables
```

#### Sign Release Build
```bash
# Automatic via GitLab CI (uses CI variables and scripts)
# Or manual:
jarsigner -verbose \
  -sigalg SHA1withRSA \
  -digestalg SHA1 \
  -keystore .info/key/meup.jks \
  build/app/outputs/bundle/prodRelease/app-prod-release.aab \
  meup-key
```

### iOS Signing (Production)

#### Setup Certificates
1. **Create Certificate in Apple Developer Program**
2. **Download Distribution Certificate (.cer)**
3. **Create Provisioning Profile**
4. **Export in Xcode:**
   ```
   Xcode → Preferences → Accounts → Manage Certificates
   Right-click → Export...
   Save as .p12 → .info/key/Certificates.p12
   ```

#### Build with Code Signing
```bash
# Automatic via Xcode build script
flutter build ios --release --flavor prod

# Or manual via Xcode
xcodebuild \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -signingIdentity "iPhone Distribution" \
  -archivePath build/ios/archive.xcarchive \
  archive
```

---

## 9. Performance & Optimization

### Release Build Optimization

All builds include:
- **Obfuscation:** `--obfuscate` (code name mangling)
- **Debug Symbols:** `--split-debug-info=.obfuscation` (for stack traces)
- **Tree Shaking:** Icon optimization enabled
- **Resource Shrinking:** Unused resources removed

### Monitoring Deployments

#### Google Play Console
1. Navigate to: **Release** → **Staging/Production**
2. Monitor: Crash rate, ANR %, startup time, reviews
3. Rollout Strategy:
   - Start: 10%
   - Monitor: 2-3 hours
   - Increase: 25% → 50% → 100%
   - Rollback: If crash rate > 2%

#### Firebase Crashlytics
```bash
# View crashes in Firebase Console
# - Crash-free session rate
# - Top crashes
# - Stack traces (unobfuscated via debug symbols)
```

#### Sentry (Optional)
```bash
# Monitor custom errors & performance
# - Error tracking
# - Performance monitoring
# - Release tracking
```

---

## 10. Troubleshooting

### Common Build Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| `build_runner` hangs | Large codebase, slow machine | Run with `--delete-conflicting-outputs` |
| APK size > 100MB | Unoptimized assets | Enable tree shaking, compress images |
| Code signing fails | Invalid keystore password | Verify in GitLab protected variables |
| Flavor not found | pubspec.yaml out of sync | Run `flutter clean && flutter pub get` |
| 401 Unauthorized (API) | Expired refresh token | Clear app data, re-authenticate |

### Debug Steps

```bash
# 1. Check Flutter setup
flutter doctor -v

# 2. Clean build artifacts
flutter clean
dart run build_runner clean

# 3. Regenerate code
dart run build_runner build --delete-conflicting-outputs

# 4. Check environment file
cat .env/.env.{flavor}

# 5. Run tests
flutter test

# 6. Analyze code
flutter analyze

# 7. Rebuild
flutter build apk --flavor {flavor} --dart-define-from-file=.env/.env.{flavor}
```

---

## 11. Deployment Checklist

### Pre-Deployment
- [ ] `flutter test` passes (100% tests)
- [ ] `flutter analyze` shows no errors
- [ ] Version bumped in `pubspec.yaml`
- [ ] `CHANGELOG.md` updated
- [ ] Feature branch code reviewed & approved
- [ ] All dependent PRs merged
- [ ] Staging build tested by QA

### During Deployment
- [ ] GitLab pipeline completed successfully
- [ ] APK/IPA built without errors
- [ ] Signing verified (no certificate errors)
- [ ] Debug symbols uploaded to Crashlytics
- [ ] App Distribution build received

### Post-Deployment (24 Hours)
- [ ] Monitor crash rate in Firebase Crashlytics
- [ ] Monitor user reviews in Play Store
- [ ] Check for ANRs (Application Not Responding)
- [ ] Verify API endpoints responding normally
- [ ] Validate Firebase Remote Config fetched successfully (app version, course, paywall configs)
- [ ] No critical bugs reported
- [ ] Analytics events flowing correctly (check FirebaseAnalytics console)
- [ ] Logs aggregated in Sentry (if applicable)
- [ ] Deep links resolving correctly to intended pages

### Rollback Plan
- [ ] Have previous version APK/IPA ready
- [ ] Document rollback steps
- [ ] Notify team of rollback
- [ ] Re-deploy previous version to stores
- [ ] Post-mortem analysis

---

## 12. Maintenance & Monitoring

### Daily Monitoring
```bash
# Check crash-free session rate
# Target: > 99%

# Check top crashes
# Review and prioritize fixes

# Monitor API performance
# Check response times, errors
```

### Weekly Tasks
```bash
# Review user feedback
# Update roadmap based on issues

# Verify CI/CD pipeline health
# Check for flaky tests

# Monitor dependency updates
# Review flutter/dart releases
```

### Monthly Tasks
```bash
# Dependency audit: flutter pub outdated
# Security review: check CVEs
# Performance profiling: Dev tools analysis
# Infrastructure review: costs, capacity
```

---

## 13. Rollback Procedure

### If Critical Bug Detected (Post-Release)

```bash
# 1. STOP ROLLOUT (immediately)
# Google Play Console → Release → Pause rollout

# 2. COMMUNICATE
# Notify stakeholders, team, support

# 3. CREATE HOTFIX
git checkout -b hotfix/MEUP-xxx
# Fix bug
git push origin hotfix/MEUP-xxx
# Create PR, review, merge

# 4. BUILD HOTFIX
git tag v1.0.1
git push origin v1.0.1
# GitLab CI builds artifacts for redeploy

# 5. RESUME ROLLOUT
# Google Play Console → Resume with new version
```

---

## 14. Environment-Specific Configuration

### Dev (Development)
- API: `https://dev-api.meup.com`
- Firebase: meup-dev project
- Error reporting: Sentry (sampled)
- App icon: Dev badge (blue)
- Release cadence: Continuous

### Stg (Staging)
- API: `https://stg-api.meup.com`
- Firebase: meup-stg project
- Error reporting: Sentry (high sampling)
- App icon: Staging badge (orange)
- Release cadence: Pre-production (weekly)

### Prod (Production)
- API: `https://api.meup.com`
- Firebase: meup-prod project
- Error reporting: Sentry (production)
- App icon: Production (no badge)
- Release cadence: Monthly

---

**Document Maintained By:** DevOps Team
**Last Review:** Jan 22, 2026
**Next Review:** Mar 22, 2026

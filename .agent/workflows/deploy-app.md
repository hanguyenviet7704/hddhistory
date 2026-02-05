---
trigger: model_decision
description: Workflow for /deploy-app (Deploy App)
---

# Deploy App

## Invocation
Use only when the user explicitly requests `/deploy-app` or asks to run this workflow.
Ask the listed questions first, then execute the steps.

## Overview
Deploy the Meup Flutter application to various distribution channels including Google Play Store, Apple App Store, Firebase App Distribution, and internal testing environments.

## Deployment Channels

### 1. **Internal Testing (Firebase App Distribution)**

#### Deploy to Testers:
```bash
# Build and deploy dev version to internal testers
./tools/macos/build/build_apk.sh dev
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-dev-release.apk \
  --app 1:123456789:android:dev_app_id \
  --groups "internal-testers" \
  --release-notes "Internal dev build"

# Deploy staging version
./tools/macos/build/build_apk.sh stg  
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-stg-release.apk \
  --app 1:123456789:android:stg_app_id \
  --groups "beta-testers" \
  --release-notes "Staging build for testing"
```

### 2. **Google Play Store**

#### Internal Testing Track:
```bash
# Build production app bundle
./tools/macos/build/build_appbundle.sh prod

# Upload to Play Console (manual process)
# 1. Go to Google Play Console
# 2. Select your app
# 3. Go to Release > Testing > Internal testing
# 4. Upload the AAB file: build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

#### Production Track:
```bash
# Build production app bundle
./tools/macos/build/build_appbundle.sh prod

# Upload to Play Console production track
# 1. Complete internal testing
# 2. Go to Release > Production
# 3. Create new release
# 4. Upload AAB file
# 5. Add release notes
# 6. Review and publish
```

### 3. **Apple App Store**

#### TestFlight (Beta Testing):
```bash
# Build iOS app for TestFlight
./tools/macos/build/build_ipa.sh stg

# Upload using Xcode or altool
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/meup_stg.ipa \
  --username "your-apple-id@email.com" \
  --password "app-specific-password"

# Or use Xcode Organizer:
# 1. Open Xcode
# 2. Window > Organizer
# 3. Select your archive
# 4. Click "Distribute App"
# 5. Choose "App Store Connect"
```

#### App Store Production:
```bash
# Build production iOS app
./tools/macos/build/build_ipa.sh prod

# Submit through App Store Connect
# 1. Upload IPA through Xcode or altool
# 2. Go to App Store Connect
# 3. Select your app
# 4. Create new version
# 5. Add metadata and screenshots
# 6. Submit for review
```

## Pre-Deployment Checklist

### Code Quality:
- [ ] All tests pass (`flutter test`)
- [ ] Code analysis clean (`flutter analyze`)
- [ ] No debug code in production
- [ ] Performance testing completed
- [ ] Security review completed

### Build Verification:
- [ ] Version number updated in `pubspec.yaml`
- [ ] Build number incremented
- [ ] Changelog updated
- [ ] Environment configurations verified
- [ ] Code obfuscation enabled for production

### App Store Requirements:

#### Google Play:
- [ ] App bundle (AAB) format used
- [ ] Target API level meets requirements
- [ ] Privacy policy updated
- [ ] App permissions justified
- [ ] Content ratings assigned

#### Apple App Store:
- [ ] IPA file properly signed
- [ ] iOS deployment target meets requirements
- [ ] App icons in all required sizes
- [ ] Launch screens configured
- [ ] Privacy policy updated
- [ ] App Transport Security configured

## Deployment Scripts

### Automated Deployment (GitHub Actions):

#### Android Deployment:
```yaml
# .github/workflows/deploy-android.yml
deploy-android:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
    - name: Build Android
      run: |
        flutter pub get
        dart run build_runner build --delete-conflicting-outputs
        ./tools/macos/build/build_appbundle.sh prod
    
    - name: Deploy to Firebase App Distribution
      uses: wzieba/Firebase-Distribution-Github-Action@v1
      with:
        appId: ${{ secrets.FIREBASE_APP_ID_ANDROID }}
        token: ${{ secrets.FIREBASE_TOKEN }}
        groups: internal-testers
        file: build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

#### iOS Deployment:
```yaml
# .github/workflows/deploy-ios.yml
deploy-ios:
  runs-on: macos-latest
  steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
    - name: Build iOS
      run: |
        flutter pub get
        dart run build_runner build --delete-conflicting-outputs
        ./tools/macos/build/build_ipa.sh prod
    
    - name: Deploy to TestFlight
      uses: apple-actions/upload-testflight-build@v1
      with:
        app-path: build/ios/ipa/meup_prod.ipa
        issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
        api-key-id: ${{ secrets.APPSTORE_API_KEY_ID }}
        api-private-key: ${{ secrets.APPSTORE_API_PRIVATE_KEY }}
```

## Environment-Specific Deployment

### Development Environment:
```bash
# Deploy to development testers
./tools/macos/build/build_apk.sh dev
# Deploy via Firebase App Distribution to dev group
```

### Staging Environment:
```bash
# Deploy to staging testers
./tools/macos/build/build_appbundle.sh stg
# Deploy to Play Console internal testing
# Deploy to TestFlight for iOS
```

### Production Environment:
```bash
# Deploy to production
./tools/macos/build/build_appbundle.sh prod
# Deploy to Play Store
# Deploy to App Store
```

## Release Management

### Version Management:
```yaml
# pubspec.yaml
version: 1.2.3+45
# 1.2.3 = version name (semantic versioning)
# 45 = build number (must increment for each release)
```

### Release Notes Template:
```
## Version 1.2.3

### New Features
- Added user profile management
- Implemented dark mode support

### Improvements  
- Enhanced app performance
- Updated UI components

### Bug Fixes
- Fixed login issues
- Resolved crash on startup

### Technical Updates
- Updated dependencies
- Improved error handling
```

## Monitoring and Rollback

### Post-Deployment Monitoring:
```bash
# Monitor crash reports
# Check Firebase Crashlytics dashboard

# Monitor performance
# Review Firebase Performance dashboard

# Check user feedback
# Monitor app store reviews and ratings
```

### Rollback Strategy:

#### Google Play Store:
1. Go to Play Console > Release management > App releases
2. Select the track (Internal/Alpha/Beta/Production)
3. Click "Manage release"
4. Choose "Rollback" option

#### Apple App Store:
1. Go to App Store Connect
2. Select your app
3. Go to "App Store" tab
4. Click "Remove from Sale" or submit previous version

#### Firebase App Distribution:
```bash
# Deploy previous known good build
firebase appdistribution:distribute path/to/previous-build.apk \
  --app $FIREBASE_APP_ID \
  --groups "testers"
```

## Security Considerations

### Code Protection:
- [ ] Code obfuscation enabled
- [ ] Debug symbols separated
- [ ] API keys properly secured
- [ ] Certificate pinning implemented

### Distribution Security:
- [ ] App signing certificates secured
- [ ] CI/CD secrets protected
- [ ] Access controls properly configured
- [ ] Build artifacts verified

## Distribution Channels Summary

### Internal Testing:
- **Firebase App Distribution**: Quick deployment to testers
- **Development builds**: Direct APK/IPA sharing

### Beta Testing:
- **Google Play Internal Testing**: App bundle testing
- **Apple TestFlight**: iOS beta distribution

### Production:
- **Google Play Store**: Android production distribution
- **Apple App Store**: iOS production distribution

## Troubleshooting Deployment

### Common Issues:

#### Google Play Upload:
```
Upload failed: APK specifies a version code that has already been used
```
**Solution**: Increment build number in `pubspec.yaml`

#### Apple App Store:
```
Invalid Bundle. The bundle does not support the minimum OS Version
```
**Solution**: Update iOS deployment target in `ios/Podfile` and Xcode

#### Firebase App Distribution:
```
App with the given app ID could not be found
```
**Solution**: Verify Firebase app ID and ensure proper authentication

### Build Failures:
1. Check build logs for specific errors
2. Verify all dependencies are up to date
3. Ensure code obfuscation isn't breaking functionality
4. Test build on clean environment

## Deployment Best Practices

1. **Always test in staging before production**
2. **Use semantic versioning**
3. **Maintain detailed release notes**
4. **Monitor post-deployment metrics**
5. **Have rollback strategy ready**
6. **Automate deployment pipeline**
7. **Secure all credentials and certificates**
8. **Test on multiple devices and OS versions**

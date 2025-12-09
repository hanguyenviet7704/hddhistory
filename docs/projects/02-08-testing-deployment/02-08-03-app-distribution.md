# App Distribution

This document outlines the app distribution strategy and processes for DCore Flutter application across different environments and platforms.

## Overview

The DCore project uses a multi-tiered distribution approach supporting different environments (dev, stg, prod) with automated build processes and distribution channels for both Android and iOS platforms.

## Distribution Channels

### Android Distribution

#### Google Play Store
- **Production Releases**: Main distribution channel for end users
- **Internal Testing**: Team and stakeholder testing
- **Closed Alpha/Beta**: Limited user testing
- **Open Beta**: Public testing before full release

#### Direct APK Distribution
- **Development Builds**: Internal development and testing
- **Staging Builds**: Pre-production validation
- **Enterprise Distribution**: Direct APK distribution for specific clients

### iOS Distribution

#### App Store
- **Production Releases**: Main distribution channel
- **TestFlight**: Beta testing platform
- **App Store Review**: Apple's review process

#### Enterprise Distribution
- **Ad Hoc Distribution**: Limited device testing
- **Enterprise Certificate**: Internal company distribution

## Build and Distribution Scripts

### Android Distribution

#### APK Distribution Script
```bash
# Build and distribute APK (match platform)
sh tools/macos/build/build_apk.sh [flavor]      # macOS
sh tools/linux/build/build_apk.sh [flavor]      # Linux
tools\\windows\\build\\build_apk.bat [flavor]   # Windows

# Output location
build/app/outputs/flutter-apk/
├── app-dev-release.apk      # Development build
├── app-stg-release.apk      # Staging build
└── app-prod-release.apk     # Production build
```

#### App Bundle Distribution Script
```bash
# Build App Bundle for Play Store (match platform)
sh tools/macos/build/build_appbundle.sh [flavor]
sh tools/linux/build/build_appbundle.sh [flavor]
tools\\windows\\build\\build_appbundle.bat [flavor]

# Output location
build/app/outputs/bundle/
├── devRelease/app-dev-release.aab
├── stgRelease/app-stg-release.aab
└── prodRelease/app-prod-release.aab
```

### iOS Distribution

#### iOS Build and Distribution
```bash
# Build iOS app
sh tools/macos/build/build_ios.sh [dev|stg|prod]

# Upload to App Store Connect
sh tools/macos/distribution/upload_appstore.sh [dev|stg|prod]
```

## Distribution Workflows

### Development Distribution

#### Purpose
- Internal development testing
- Feature validation
- Integration testing
- Debug and troubleshooting

#### Process
```bash
# 1. Build development version
sh tools/macos/build/build_apk.sh dev   # or tools/linux/... on Linux
tools\\windows\\build\\build_apk.bat dev   # Windows

# 2. Distribute via internal channels
# - Email/Slack sharing
# - Internal file sharing systems
# - Development device installation

# 3. Install for testing
adb install build/app/outputs/flutter-apk/app-dev-release.apk
```

#### Characteristics
- **Debug Features**: Enabled debug menu and logging
- **Development APIs**: Connected to development backend
- **Flexible Updates**: Frequent updates and iterations
- **Internal Distribution**: Team members and close stakeholders

### Staging Distribution

#### Purpose
- Pre-production validation
- User acceptance testing
- Performance testing
- Final quality assurance

#### Process
```bash
# 1. Build staging version
sh tools/macos/build/build_appbundle.sh stg   # or tools/linux/... on Linux
tools\\windows\\build\\build_appbundle.bat stg   # Windows

# 2. Upload to internal testing tracks
# Google Play Console - Internal Testing
# TestFlight - Internal Testing

# 3. Distribute to test users
# Email invitations
# Test group management
```

#### Characteristics
- **Production-like Environment**: Mirrors production setup
- **Limited Debug Features**: Reduced debugging capabilities
- **Staging APIs**: Connected to staging backend
- **Controlled Distribution**: Selected test users

### Production Distribution

#### Purpose
- End-user releases
- Public availability
- Commercial distribution
- Official app store presence

#### Google Play Store Process
```bash
# 1. Build production App Bundle
sh tools/macos/build/build_appbundle.sh prod   # or tools/linux/... on Linux
tools\\windows\\build\\build_appbundle.bat prod   # Windows

# 2. Upload to Google Play Console
# Manual upload or API-based upload

# 3. Configure release
# - Release notes
# - Staged rollout percentage
# - Target audience

# 4. Submit for review (if required)
# 5. Publish to production
```

#### App Store Process
```bash
# 1. Build production iOS app
sh tools/macos/build/build_ios.sh prod

# 2. Upload to App Store Connect
sh tools/macos/distribution/upload_appstore.sh prod

# 3. Configure app metadata
# - App description
# - Screenshots
# - Keywords
# - App categories

# 4. Submit for review
# 5. Release after approval
```

## Distribution Automation

### CI/CD Integration

The DCore project uses GitHub Actions for comprehensive CI/CD automation with environment-specific builds and distributions.

#### Complete GitHub Actions Workflow
Create `.github/workflows/build-and-distribute.yml`:

```yaml
name: DCore Build and Distribution

on:
  push:
    branches: [develop, main]
    tags: ['v*']
  pull_request:
    branches: [develop, main]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to build'
        required: true
        default: 'dev'
        type: choice
        options:
        - dev
        - stg
        - prod
      build_type:
        description: 'Build type'
        required: true
        default: 'apk'
        type: choice
        options:
        - apk
        - appbundle
        - ios

env:
  FLUTTER_VERSION: "3.16.0"
  JAVA_VERSION: "17"

jobs:
  # Quality checks and testing
  quality_check:
    name: Code Quality & Tests
    runs-on: ubuntu-latest
    steps:
      - name: 📚 Git Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: 🐦 Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true

      - name: ☕ Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: ${{ env.JAVA_VERSION }}

      - name: 📦 Get Dependencies
        run: flutter pub get

      - name: 🔍 Analyze Code
        run: flutter analyze

      - name: 🧪 Run Tests
        run: flutter test --coverage

      - name: 📊 Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info

  # Android Development Build
  build_android_dev:
    name: Android Dev Build
    needs: quality_check
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop' || (github.event_name == 'workflow_dispatch' && github.event.inputs.environment == 'dev')
    steps:
      - name: 📚 Git Checkout
        uses: actions/checkout@v4

      - name: 🐦 Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true

      - name: ☕ Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: ${{ env.JAVA_VERSION }}

      - name: 📦 Get Dependencies
        run: flutter pub get

      - name: 🔨 Generate Code
        run: dart run build_runner build --delete-conflicting-outputs

      - name: 📱 Build Development APK
        run: |
          chmod +x tools/linux/build/build_apk.sh
          ./tools/linux/build/build_apk.sh dev

      - name: 📤 Upload Development APK
        uses: actions/upload-artifact@v4
        with:
          name: meup-dev-apk
          path: build/app/outputs/flutter-apk/app-dev-release.apk
          retention-days: 30

      - name: 💬 Notify Slack (Dev Build)
        if: success()
        uses: 8398a7/action-slack@v3
        with:
          status: success
          text: "🎉 DCore Dev build completed successfully! APK available in artifacts."
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}

  # Android Staging Build
  build_android_staging:
    name: Android Staging Build
    needs: quality_check
    runs-on: ubuntu-latest
    if: contains(github.ref, 'refs/tags/') || (github.event_name == 'workflow_dispatch' && github.event.inputs.environment == 'stg')
    steps:
      - name: 📚 Git Checkout
        uses: actions/checkout@v4

      - name: 🐦 Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true

      - name: ☕ Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: ${{ env.JAVA_VERSION }}

      - name: 📦 Get Dependencies
        run: flutter pub get

      - name: 🔨 Generate Code
        run: dart run build_runner build --delete-conflicting-outputs

      - name: 🔐 Setup Android Signing
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore.jks
          echo "storeFile=keystore.jks" >> android/key.properties
          echo "keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}" >> android/key.properties
          echo "storePassword=${{ secrets.ANDROID_STORE_PASSWORD }}" >> android/key.properties
          echo "keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}" >> android/key.properties

      - name: 📱 Build Staging App Bundle
        run: |
          chmod +x tools/linux/build/build_appbundle.sh
          ./tools/linux/build/build_appbundle.sh stg

      - name: 🚀 Deploy to Internal Testing
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT }}
          packageName: com.eup.meup.stg
          releaseFiles: build/app/outputs/bundle/stgRelease/app-stg-release.aab
          track: internal
          status: completed

      - name: 📤 Upload Staging Bundle
        uses: actions/upload-artifact@v4
        with:
          name: meup-staging-bundle
          path: build/app/outputs/bundle/stgRelease/app-stg-release.aab
          retention-days: 90

  # Android Production Build
  build_android_production:
    name: Android Production Build
    needs: quality_check
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' || (github.event_name == 'workflow_dispatch' && github.event.inputs.environment == 'prod')
    environment: production
    steps:
      - name: 📚 Git Checkout
        uses: actions/checkout@v4

      - name: 🐦 Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true

      - name: ☕ Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: ${{ env.JAVA_VERSION }}

      - name: 📦 Get Dependencies
        run: flutter pub get

      - name: 🔨 Generate Code
        run: dart run build_runner build --delete-conflicting-outputs

      - name: 🔐 Setup Android Signing
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore.jks
          echo "storeFile=keystore.jks" >> android/key.properties
          echo "keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}" >> android/key.properties
          echo "storePassword=${{ secrets.ANDROID_STORE_PASSWORD }}" >> android/key.properties
          echo "keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}" >> android/key.properties

      - name: 📱 Build Production App Bundle
        run: |
          chmod +x tools/linux/build/build_appbundle.sh
          ./tools/linux/build/build_appbundle.sh prod

      - name: 🚀 Deploy to Play Store (10% Rollout)
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_SERVICE_ACCOUNT }}
          packageName: com.eup.meup
          releaseFiles: build/app/outputs/bundle/prodRelease/app-prod-release.aab
          track: production
          status: inProgress
          userFraction: 0.1
          whatsNewDirectory: metadata/android
          mappingFile: build/app/outputs/mapping/prodRelease/mapping.txt

      - name: 📤 Upload Production Bundle
        uses: actions/upload-artifact@v4
        with:
          name: meup-production-bundle
          path: |
            build/app/outputs/bundle/prodRelease/app-prod-release.aab
            build/app/outputs/mapping/prodRelease/mapping.txt
          retention-days: 365

      - name: 🏷️ Create GitHub Release
        if: contains(github.ref, 'refs/tags/')
        uses: softprops/action-gh-release@v1
        with:
          files: build/app/outputs/bundle/prodRelease/app-prod-release.aab
          generate_release_notes: true

  # iOS Builds
  build_ios:
    name: iOS Build
    needs: quality_check
    runs-on: macos-latest
    if: github.event_name == 'workflow_dispatch' && github.event.inputs.build_type == 'ios'
    strategy:
      matrix:
        environment: [dev, stg, prod]
    steps:
      - name: 📚 Git Checkout
        uses: actions/checkout@v4

      - name: 🐦 Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          cache: true

      - name: 📦 Get Dependencies
        run: flutter pub get

      - name: 🔨 Generate Code
        run: dart run build_runner build --delete-conflicting-outputs

      - name: 🍎 Setup iOS Signing
        uses: apple-actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.IOS_CERTIFICATES_P12 }}
          p12-password: ${{ secrets.IOS_CERTIFICATES_PASSWORD }}

      - name: 🔧 Install Provisioning Profile
        uses: apple-actions/download-provisioning-profiles@v1
        with:
          bundle-id: com.eup.meup.${{ matrix.environment == 'prod' && '' || matrix.environment }}
          profile-type: 'IOS_APP_STORE'
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}

      - name: 📱 Build iOS
        run: |
          chmod +x tools/macos/build/build_ipa.sh
          ./tools/macos/build/build_ipa.sh ${{ matrix.environment }}

      - name: 🚀 Upload to TestFlight
        uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: build/ios/ipa/meup-${{ matrix.environment }}.ipa
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}

      - name: 📤 Upload iOS Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: meup-ios-${{ matrix.environment }}
          path: build/ios/ipa/meup-${{ matrix.environment }}.ipa
          retention-days: 90

  # Notification job
  notify:
    name: Notification
    needs: [build_android_dev, build_android_staging, build_android_production, build_ios]
    runs-on: ubuntu-latest
    if: always()
    steps:
      - name: 💬 Notify Teams
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          fields: repo,message,commit,author,action,eventName,ref,workflow
          text: |
            🚀 DCore Build Pipeline Completed
            
            Results:
            - Quality Check: ${{ needs.quality_check.result }}
            - Android Dev: ${{ needs.build_android_dev.result }}
            - Android Staging: ${{ needs.build_android_staging.result }}
            - Android Production: ${{ needs.build_android_production.result }}
            - iOS Build: ${{ needs.build_ios.result }}
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

#### Required GitHub Secrets

To set up the CI/CD pipeline, configure these secrets in GitHub repository settings:

##### Android Secrets
```bash
# Android Keystore (base64 encoded)
ANDROID_KEYSTORE_BASE64=<base64_encoded_keystore>
ANDROID_KEY_ALIAS=<key_alias>
ANDROID_STORE_PASSWORD=<keystore_password>
ANDROID_KEY_PASSWORD=<key_password>

# Google Play Store
PLAY_STORE_SERVICE_ACCOUNT=<service_account_json>
```

##### iOS Secrets
```bash
# iOS Certificates (base64 encoded P12 file)
IOS_CERTIFICATES_P12=<base64_encoded_certificates>
IOS_CERTIFICATES_PASSWORD=<certificate_password>

# App Store Connect API
APPSTORE_ISSUER_ID=<issuer_id>
APPSTORE_KEY_ID=<api_key_id>
APPSTORE_PRIVATE_KEY=<private_key>
```

##### Notification Secrets
```bash
# Slack Integration
SLACK_WEBHOOK_URL=<slack_webhook_url>

# Code Coverage
CODECOV_TOKEN=<codecov_token>
```

#### Setting Up Android Keystore

1. **Generate Keystore** (if not exists):
```bash
keytool -genkey -v -keystore android/app/keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias meup-key
```

2. **Convert to Base64**:
```bash
base64 -i android/app/keystore.jks -o keystore_base64.txt
```

3. **Add to GitHub Secrets**:
   - Go to Repository Settings → Secrets and variables → Actions
   - Add `ANDROID_KEYSTORE_BASE64` with the base64 content

#### Setting Up iOS Certificates

1. **Export P12 Certificate** from Keychain Access
2. **Convert to Base64**:
```bash
base64 -i certificates.p12 -o certificates_base64.txt
```
3. **Add to GitHub Secrets** as `IOS_CERTIFICATES_P12`

#### Environment Protection Rules

Set up environment protection rules in GitHub:

1. **Production Environment**:
   - Required reviewers: Team leads
   - Wait timer: 5 minutes
   - Restrict pushes to main branch only

2. **Staging Environment**:
   - Required reviewers: Any team member
   - Wait timer: 1 minute

#### GitLab CI Example
```yaml
stages:
  - build
  - distribute

variables:
  FLUTTER_VERSION: "3.16.0"

build_apk:
  stage: build
  image: cirrusci/flutter:$FLUTTER_VERSION
  script:
    - sh tools/linux/build/build_apk.sh dev
  artifacts:
    paths:
      - build/app/outputs/flutter-apk/
    expire_in: 1 week
  only:
    - develop

distribute_staging:
  stage: distribute
  script:
    - sh tools/linux/build/build_appbundle.sh stg
    # Upload to internal testing
  only:
    - staging

distribute_production:
  stage: distribute
  script:
    - sh tools/linux/build/build_appbundle.sh prod
    # Upload to production
  only:
    - main
  when: manual
```

### Automated Distribution Tools

#### Fastlane Integration
```ruby
# fastlane/Fastfile
default_platform(:android)

platform :android do
  desc "Deploy to internal testing"
  lane :internal do
    gradle(task: "bundleStgRelease")
    upload_to_play_store(
      track: 'internal',
      aab: 'build/app/outputs/bundle/stgRelease/app-stg-release.aab'
    )
  end

  desc "Deploy to production"
  lane :production do
    gradle(task: "bundleProdRelease")
    upload_to_play_store(
      track: 'production',
      rollout: '0.1', # 10% rollout
      aab: 'build/app/outputs/bundle/prodRelease/app-prod-release.aab'
    )
  end
end

platform :ios do
  desc "Deploy to TestFlight"
  lane :beta do
    build_app(
      scheme: "Runner",
      configuration: "Release-stg",
      export_method: "app-store"
    )
    upload_to_testflight
  end

  desc "Deploy to App Store"
  lane :release do
    build_app(
      scheme: "Runner", 
      configuration: "Release-prod",
      export_method: "app-store"
    )
    upload_to_app_store
  end
end
```

## Distribution Configuration

### Environment-Specific Configuration

#### DCore Distribution Configuration

Using the Flavor system from `lib/flavors.dart`:

```dart
// lib/config/distribution/distribution_config.dart
import '../flavors.dart';

class DistributionConfig {
  static String get environment => F.appFlavor?.name ?? 'unknown';
  
  static bool get enableDebugFeatures => F.appFlavor == Flavor.dev;
  
  static bool get enableAnalytics => F.appFlavor != Flavor.dev;
  
  static bool get enableCrashReporting => F.appFlavor != null;
  
  static String get updateCheckUrl {
    return switch (F.appFlavor) {
      Flavor.dev => 'https://dev-updates.meup.com',
      Flavor.stg => 'https://stg-updates.meup.com', 
      Flavor.prod => 'https://updates.meup.com',
      _ => 'https://updates.meup.com',
    };
  }
  
  static String get distributionChannel {
    return switch (F.appFlavor) {
      Flavor.dev => 'development',
      Flavor.stg => 'internal_testing',
      Flavor.prod => 'production',
      _ => 'unknown',
    };
  }
  
  static Map<String, dynamic> get buildInfo => {
    'flavor': F.appFlavor?.name,
    'app_name': F.title,
    'firebase_project': F.firebaseOptions.projectId,
    'distribution_channel': distributionChannel,
    'enable_debug': enableDebugFeatures,
  };
}
```

### App Store Metadata

#### Google Play Store
Create `metadata/android/en-US/` structure for automated uploads:

```yaml
# metadata/android/en-US/title.txt
DCore - Art Education Platform

# metadata/android/en-US/short_description.txt
Interactive art learning with picture studies, quizzes, and roadmaps

# metadata/android/en-US/full_description.txt
DCore is a comprehensive art education platform that provides interactive learning experiences for art enthusiasts and students.

Features:
• Picture Studies - Analyze famous artworks with guided learning
• Interactive Quizzes - Test knowledge with engaging art quizzes  
• Learning Roadmaps - Structured paths for art education progression
• User Profiles - Track progress and achievements
• Modern Interface - Intuitive and engaging user experience
• Multi-language Support - Accessible to global learners

Perfect for art students, educators, and anyone passionate about learning art history and appreciation.

# Directory structure:
metadata/android/en-US/
├── title.txt
├── short_description.txt
├── full_description.txt
├── video.txt              # YouTube video URL (optional)
└── changelogs/
    ├── 100190.txt         # Version 1.0.19 changelog
    ├── 100180.txt         # Version 1.0.18 changelog
    └── 100170.txt         # Version 1.0.17 changelog

# Example changelog (metadata/android/en-US/changelogs/100190.txt):
• New picture study categories added
• Improved quiz performance and scoring
• Enhanced user profile management
• Bug fixes and stability improvements
• Updated art database with new collections
```

#### App Store Connect
Create `metadata/ios/en-US/` structure:

```yaml
# metadata/ios/en-US/name.txt
DCore

# metadata/ios/en-US/subtitle.txt
Art Education & Learning

# metadata/ios/en-US/description.txt
DCore transforms art education through interactive learning experiences. Dive deep into art history, analyze masterpieces, and track your learning journey.

Key Features:
• Picture Studies - Interactive analysis of famous artworks
• Knowledge Quizzes - Engaging tests to reinforce learning
• Learning Roadmaps - Structured educational paths
• Progress Tracking - Monitor achievements and growth
• Curated Content - Expert-selected art collections
• User-Friendly Design - Intuitive learning interface

Whether you're an art student, teacher, or enthusiast, DCore provides the tools and content to deepen your understanding and appreciation of art.

# metadata/ios/en-US/keywords.txt
art,education,learning,quiz,study,artwork,history,museum,gallery,culture

# metadata/ios/en-US/marketing_url.txt
https://meup.com

# metadata/ios/en-US/support_url.txt
https://support.meup.com

# metadata/ios/en-US/privacy_url.txt
https://meup.com/privacy

# App categories in App Store Connect:
categories:
  primary: "Education"
  secondary: "Reference"
```

## Distribution Monitoring

### Analytics and Tracking

#### DCore Distribution Analytics

```dart
// lib/config/analytics/distribution_analytics.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../flavors.dart';
import '../distribution/distribution_config.dart';

class ArtlexisDistributionAnalytics {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  /// Initialize distribution tracking
  static Future<void> initialize() async {
    final packageInfo = await PackageInfo.fromPlatform();
    
    // Set user properties for distribution tracking
    await _analytics.setUserProperty(
      name: 'flavor',
      value: F.appFlavor?.name,
    );
    
    await _analytics.setUserProperty(
      name: 'distribution_channel', 
      value: DistributionConfig.distributionChannel,
    );
    
    await _analytics.setUserProperty(
      name: 'app_version',
      value: packageInfo.version,
    );
    
    await _analytics.setUserProperty(
      name: 'build_number',
      value: packageInfo.buildNumber,
    );
  }
  
  /// Track app launch with distribution context
  static Future<void> trackAppLaunch() async {
    final packageInfo = await PackageInfo.fromPlatform();
    
    await _analytics.logEvent(
      name: 'app_launch',
      parameters: {
        'flavor': F.appFlavor?.name,
        'app_title': F.title,
        'distribution_channel': DistributionConfig.distributionChannel,
        'firebase_project': F.firebaseOptions.projectId,
        'version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
        'debug_enabled': DistributionConfig.enableDebugFeatures,
        'launch_timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  /// Track installation source and first launch
  static Future<void> trackInstallSource(String source) async {
    await _analytics.setUserProperty(
      name: 'install_source',
      value: source,
    );
    
    await _analytics.logEvent(
      name: 'app_install',
      parameters: {
        'install_source': source,
        'flavor': F.appFlavor?.name,
        'distribution_channel': DistributionConfig.distributionChannel,
        'install_timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  /// Track update availability and user actions
  static Future<void> trackUpdateCheck({
    required bool updateAvailable,
    String? availableVersion,
    String? currentVersion,
  }) async {
    await _analytics.logEvent(
      name: 'update_check',
      parameters: {
        'update_available': updateAvailable,
        'current_version': currentVersion,
        'available_version': availableVersion,
        'distribution_channel': DistributionConfig.distributionChannel,
        'check_timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  /// Track distribution-specific feature usage
  static Future<void> trackFeatureUsage(String feature) async {
    await _analytics.logEvent(
      name: 'feature_usage',
      parameters: {
        'feature_name': feature,
        'flavor': F.appFlavor?.name,
        'debug_mode': DistributionConfig.enableDebugFeatures,
        'usage_timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
  
  /// Track build-specific metrics for development
  static Future<void> trackBuildMetrics() async {
    if (!DistributionConfig.enableDebugFeatures) return;
    
    await _analytics.logEvent(
      name: 'build_metrics',
      parameters: {
        'build_info': DistributionConfig.buildInfo,
        'flavor': F.appFlavor?.name,
        'metrics_timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
}
```

#### DCore Crash Reporting

```dart
// lib/config/crash_reporting/artlexis_crash_reporting.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../flavors.dart';
import '../distribution/distribution_config.dart';

class ArtlexisCrashReporting {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  
  /// Initialize crash reporting with distribution context
  static Future<void> initialize() async {
    final packageInfo = await PackageInfo.fromPlatform();
    
    // Configure crash reporting based on environment
    if (DistributionConfig.enableCrashReporting) {
      // Set distribution-specific custom keys
      await _crashlytics.setCustomKey('flavor', F.appFlavor?.name ?? 'unknown');
      await _crashlytics.setCustomKey('app_title', F.title);
      await _crashlytics.setCustomKey('distribution_channel', DistributionConfig.distributionChannel);
      await _crashlytics.setCustomKey('firebase_project', F.firebaseOptions.projectId);
      await _crashlytics.setCustomKey('app_version', packageInfo.version);
      await _crashlytics.setCustomKey('build_number', packageInfo.buildNumber);
      await _crashlytics.setCustomKey('debug_enabled', DistributionConfig.enableDebugFeatures);
      await _crashlytics.setCustomKey('platform', kIsWeb ? 'web' : 'mobile');
      
      // Enable crash collection
      await _crashlytics.setCrashlyticsCollectionEnabled(true);
      
      // Set up Flutter error handling
      FlutterError.onError = (FlutterErrorDetails details) {
        _crashlytics.recordFlutterFatalError(details);
      };
      
      // Set up async error handling
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
      
      // Log successful initialization
      _crashlytics.log('DCore crash reporting initialized for ${F.appFlavor?.name}');
    }
  }
  
  /// Record custom error with distribution context
  static Future<void> recordError(
    dynamic exception,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!DistributionConfig.enableCrashReporting) return;
    
    // Add distribution context to additional data
    final contextData = {
      'flavor': F.appFlavor?.name,
      'distribution_channel': DistributionConfig.distributionChannel,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };
    
    await _crashlytics.recordError(
      exception,
      stackTrace,
      reason: reason,
      fatal: fatal,
      information: contextData.entries.map((e) => DiagnosticsProperty(e.key, e.value)).toList(),
    );
  }
  
  /// Log distribution-specific events
  static void logDistributionEvent(String message, {Map<String, dynamic>? data}) {
    if (!DistributionConfig.enableCrashReporting) return;
    
    final logMessage = 'Distribution Event: $message';
    if (data != null) {
      _crashlytics.log('$logMessage - Data: ${data.toString()}');
    } else {
      _crashlytics.log(logMessage);
    }
  }
  
  /// Set user identifier for crash tracking
  static Future<void> setUserIdentifier(String userId) async {
    if (!DistributionConfig.enableCrashReporting) return;
    
    await _crashlytics.setUserIdentifier(userId);
    logDistributionEvent('User identified', {'user_id': userId});
  }
}
```

### Performance Monitoring
```dart
class DistributionPerformanceMonitoring {
  static void trackAppStartTime() {
    final appStartTrace = FirebasePerformance.instance.newTrace('app_start');
    appStartTrace.start();
    
    // Track distribution-specific performance metrics
    appStartTrace.setMetric('environment', EnvironmentConfig.environment);
    appStartTrace.setMetric('build_number', AppInfo.buildNumber);
  }
  
  static void trackDistributionSpecificMetrics() {
    FirebasePerformance.instance.newTrace('distribution_metrics')
      ..putAttribute('distribution_type', _getDistributionType())
      ..putAttribute('update_method', _getUpdateMethod());
  }
}
```

## Version Management

### Version Numbering Strategy
```yaml
# pubspec.yaml version format
version: 1.0.19+20
# Format: MAJOR.MINOR.PATCH+BUILD_NUMBER

# Version increment rules:
# MAJOR: Breaking changes or major feature releases
# MINOR: New features, backward compatible
# PATCH: Bug fixes, minor improvements
# BUILD_NUMBER: Unique build identifier, auto-incremented
```

### Release Notes Management
```dart
class ReleaseNotesManager {
  static const Map<String, String> releaseNotes = {
    '1.0.19': '''
    • New collaborative workspace features
    • Improved performance and stability
    • Bug fixes and user interface improvements
    • Enhanced export options
    ''',
    '1.0.18': '''
    • Advanced drawing tools
    • Cloud synchronization improvements
    • New template categories
    • Security enhancements
    ''',
  };
  
  static String? getReleaseNotes(String version) {
    return releaseNotes[version];
  }
}
```

### Update Mechanisms
```dart
class UpdateChecker {
  static Future<UpdateInfo?> checkForUpdates() async {
    final currentVersion = AppInfo.version;
    final response = await http.get(
      Uri.parse('${DistributionConfig.updateCheckUrl}/version-check'),
      headers: {
        'current-version': currentVersion,
        'platform': Platform.operatingSystem,
        'environment': EnvironmentConfig.environment,
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UpdateInfo.fromJson(data);
    }
    
    return null;
  }
  
  static void showUpdateDialog(BuildContext context, UpdateInfo updateInfo) {
    showDialog(
      context: context,
      builder: (context) => UpdateDialog(updateInfo: updateInfo),
    );
  }
}
```

## Security Considerations

### Distribution Security
- **Code Signing**: Ensure all builds are properly signed
- **Certificate Management**: Secure storage of signing certificates
- **Access Control**: Limit distribution access to authorized personnel
- **Integrity Verification**: Implement checksums and verification

### Build Security
```bash
# Secure build environment
export KEYSTORE_PASSWORD="$SECURE_KEYSTORE_PASSWORD"
export KEY_PASSWORD="$SECURE_KEY_PASSWORD"

# Verify build integrity
sha256sum build/app/outputs/bundle/prodRelease/app-prod-release.aab

# Upload with verification
firebase deploy --only hosting --project production-project
```

## Troubleshooting Distribution

### Common Issues

#### Play Store Upload Issues
```bash
# Check bundle validity
java -jar bundletool.jar validate --bundle=app-prod-release.aab

# Check signing
jarsigner -verify -verbose -certs app-prod-release.aab

# Upload with Play Console API
curl -X POST \
  "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/$PACKAGE_NAME/edits" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

#### TestFlight Upload Issues
```bash
# Check iOS build
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release-prod \
  -showBuildSettings

# Upload to TestFlight
xcrun altool --upload-app \
  -f "build/ios/iphoneos/Runner.app" \
  -u "developer@example.com" \
  -p "@keychain:Application Loader: developer@example.com"
```

#### Build Script Issues
```bash
# Debug build script
bash -x tools/linux/build/build_appbundle.sh prod   # or tools/macos/... on macOS

# Check environment files
cat .env/.env.prod

# Verify Flutter installation
flutter doctor -v
```

## CI/CD Setup Guide

### Step-by-Step Setup

#### 1. Repository Preparation
```bash
# Create workflow directory
mkdir -p .github/workflows

# Copy the workflow file
cp docs/examples/build-and-distribute.yml .github/workflows/

# Create metadata directories
mkdir -p metadata/android/en-US/changelogs
mkdir -p metadata/ios/en-US

# Create required metadata files
touch metadata/android/en-US/{title.txt,short_description.txt,full_description.txt}
touch metadata/ios/en-US/{name.txt,subtitle.txt,description.txt,keywords.txt}
```

#### 2. Android Setup
```bash
# Generate release keystore
keytool -genkey -v -keystore android/app/release-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias meup-release-key

# Convert keystore to base64
base64 -i android/app/release-keystore.jks | pbcopy

# Create key.properties template
echo "storeFile=release-keystore.jks" >> android/key.properties.template
echo "keyAlias=meup-release-key" >> android/key.properties.template
echo "storePassword=STORE_PASSWORD_HERE" >> android/key.properties.template  
echo "keyPassword=KEY_PASSWORD_HERE" >> android/key.properties.template
```

#### 3. GitHub Secrets Configuration
Navigate to Repository Settings → Secrets and variables → Actions, then add:

```bash
# Android secrets
ANDROID_KEYSTORE_BASE64=<paste_base64_keystore>
ANDROID_KEY_ALIAS=meup-release-key
ANDROID_STORE_PASSWORD=<keystore_password>
ANDROID_KEY_PASSWORD=<key_password>

# Google Play Console
PLAY_STORE_SERVICE_ACCOUNT=<service_account_json>

# iOS secrets (if applicable)
IOS_CERTIFICATES_P12=<base64_p12_certificate>
IOS_CERTIFICATES_PASSWORD=<certificate_password>
APPSTORE_ISSUER_ID=<issuer_id>
APPSTORE_KEY_ID=<api_key_id>
APPSTORE_PRIVATE_KEY=<private_key>

# Notifications
SLACK_WEBHOOK_URL=<slack_webhook_url>
CODECOV_TOKEN=<codecov_token>
```

#### 4. Environment Protection
1. Go to Repository Settings → Environments
2. Create "production" environment
3. Add protection rules:
   - Required reviewers: Select team leads
   - Wait timer: 5 minutes minimum
   - Deployment branches: Restrict to main branch

#### 5. Google Play Console Setup
1. Create service account in Google Cloud Console
2. Enable Google Play Developer API
3. Grant permissions in Play Console:
   - Release apps to testing tracks
   - Release apps to production
   - View app information and download bulk reports

#### 6. Test the Pipeline
```bash
# Test development build
git checkout -b test/ci-cd-setup
git add .github/workflows/build-and-distribute.yml
git commit -m "feat: Add CI/CD pipeline for app distribution"
git push origin test/ci-cd-setup

# Create PR to develop branch
gh pr create --title "Add CI/CD Pipeline" --body "Testing automated build and distribution"

# Monitor workflow execution in GitHub Actions tab
```

## Troubleshooting CI/CD

### Common Issues and Solutions

#### Build Failures
```bash
# Flutter version mismatch
# Solution: Update FLUTTER_VERSION in workflow

# Dependency conflicts
# Solution: Run flutter pub deps to check dependencies
flutter pub deps

# Code generation issues
# Solution: Ensure build_runner is in dev_dependencies
dart run build_runner build --delete-conflicting-outputs
```

#### Android Build Issues
```bash
# Keystore problems
# Check keystore validity
keytool -list -v -keystore android/app/release-keystore.jks

# Gradle issues
cd android && ./gradlew clean
flutter clean && flutter pub get

# Signing configuration
# Verify android/key.properties contains correct paths and passwords
```

#### Play Store Upload Failures
```bash
# Service account permissions
# Ensure service account has proper roles in Play Console

# Bundle validation
java -jar bundletool.jar validate --bundle=app-release.aab

# Version code conflicts
# Check if version code already exists in Play Console
```

#### iOS Build Issues (if applicable)
```bash
# Certificate issues
# Verify certificate is valid and not expired
security find-identity -v -p codesigning

# Provisioning profile
# Ensure provisioning profile matches bundle ID and certificates

# Xcode build settings
# Check build settings in ios/Runner.xcworkspace
```

### Monitoring and Alerts

#### Build Status Dashboard
Create a dashboard to monitor:
- Build success rates by environment
- Deployment frequency
- Build duration trends
- Test coverage metrics

#### Slack Notifications Template
```yaml
# Add to workflow for custom notifications
- name: Custom Slack Notification
  uses: 8398a7/action-slack@v3
  with:
    status: custom
    custom_payload: |
      {
        "channel": "#deployments",
        "username": "DCore CI/CD",
        "icon_emoji": ":rocket:",
        "attachments": [
          {
            "color": "${{ job.status == 'success' && 'good' || 'danger' }}",
            "fields": [
              {
                "title": "Environment",
                "value": "${{ github.ref_name }}",
                "short": true
              },
              {
                "title": "Status",
                "value": "${{ job.status }}",
                "short": true
              }
            ]
          }
        ]
      }
```

## Best Practices

### Distribution Strategy
- **Environment Progression**: dev → staging → production
- **Gradual Rollouts**: Start with 10% production rollout, increase gradually
- **Feature Flags**: Use feature flags for safe production releases
- **Monitoring**: Monitor distribution metrics and user feedback continuously

### Quality Assurance
- **Automated Testing**: Minimum 80% code coverage before distribution
- **Manual Testing**: Test on representative devices for each flavor
- **Performance Testing**: Verify app launch time < 3 seconds
- **Security Testing**: Regular security audits using automated tools

### Deployment Workflow
- **Branch Strategy**: Follow GitFlow with protected main branch
- **Code Review**: Require reviews before merging to main
- **Rollback Strategy**: Maintain ability to rollback within 15 minutes
- **Release Documentation**: Document every production release

### Monitoring and Analytics
- **Real-time Monitoring**: Set up alerts for crash rates > 1%
- **Performance Tracking**: Monitor ANR rates, startup time
- **Distribution Analytics**: Track installation sources and conversion rates
- **User Feedback**: Monitor app store reviews and ratings

### Security and Compliance
- **Secret Management**: Rotate secrets quarterly
- **Access Control**: Limit production deployment access
- **Audit Trail**: Log all deployment activities
- **Compliance**: Ensure GDPR/privacy compliance for all distributions

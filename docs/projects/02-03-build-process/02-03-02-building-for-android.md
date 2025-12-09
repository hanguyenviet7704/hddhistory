# Building for Android

This document provides detailed instructions for building Android applications in Dcore projects.

## Build Scripts for Android

Use the platform-matched scripts (interface is the same):

### APK Build Script
**File**: `tools/<os>/build/build_apk.(sh|bat)` (`macos` / `linux` / `windows`)
**Purpose**: Generate Android APK files for testing and distribution

### App Bundle Build Script  
**File**: `tools/<os>/build/build_appbundle.(sh|bat)`
**Purpose**: Generate Android App Bundles for Google Play Store distribution

## Building APKs

### Basic Usage
```bash
# macOS / Linux
sh tools/macos/build/build_apk.sh dev   # or tools/linux/... for Linux

# Windows
tools\\windows\\build\\build_apk.bat dev
```

### Advanced Options
```bash
# Build with tree shaking disabled for icons
sh tools/macos/build/build_apk.sh dev --no-tree-shake-icons

# View help information
sh tools/macos/build/build_apk.sh --help
```

### Build Process Details

#### Environment Mapping
The script automatically maps flavors to environment files:

| Flavor | Environment File | Purpose |
|--------|------------------|---------|
| `dev` | `.env/.env.dev` | Development testing |
| `stg` | `.env/.env.stg` | Staging/pre-production |
| `prod` | `.env/.env.prod` | Production release |

#### Build Command
The script executes:
```bash
fvm flutter build apk \
    --release \
    --obfuscate \
    --split-debug-info=".obfuscation" \
    --flavor "$FLAVOR" \
    --dart-define-from-file="$ENV_FILE" \
    -t "lib/main_$FLAVOR.dart"
```

#### Build Features
- **Release Mode**: Optimized for production
- **Code Obfuscation**: Protects source code
- **Debug Symbols**: Separated for crash analysis
- **Environment Variables**: Loaded from `.env` files
- **Flavor Support**: Multi-environment builds

### Output Location
APK files are generated in:
```
build/app/outputs/flutter-apk/
├── app-dev-release.apk
├── app-stg-release.apk
└── app-prod-release.apk
```

## Building App Bundles

### Basic Usage
```bash
# macOS / Linux
sh tools/macos/build/build_appbundle.sh dev   # or tools/linux/... for Linux

# Windows
tools\\windows\\build\\build_appbundle.bat dev
```

### App Bundle Benefits
- **Smaller Downloads**: Google Play delivers optimized APKs
- **Dynamic Delivery**: Features delivered on-demand
- **Multiple APK Support**: Different architectures and densities
- **Play Store Required**: Mandatory for new apps on Google Play

### Build Process
Similar to APK builds but generates App Bundles:
```bash
fvm flutter build appbundle \
    --release \
    --obfuscate \
    --split-debug-info=".obfuscation" \
    --flavor "$FLAVOR" \
    --dart-define-from-file="$ENV_FILE" \
    -t "lib/main_$FLAVOR.dart"
```

### Output Location
App Bundle files are generated in:
```
build/app/outputs/bundle/
├── devRelease/
│   └── app-dev-release.aab
├── stgRelease/
│   └── app-stg-release.aab
└── prodRelease/
    └── app-prod-release.aab
```

## Manual Build Commands

If you prefer raw Flutter commands (for debugging CI or investigating build issues):

### APK Build
```bash
# Development
flutter build apk --flavor dev --dart-define-from-file=.env/.env.dev -t lib/main_dev.dart --release --obfuscate --split-debug-info=.obfuscation

# Staging
flutter build apk --flavor stg --dart-define-from-file=.env/.env.stg -t lib/main_stg.dart --release --obfuscate --split-debug-info=.obfuscation

# Production
flutter build apk --flavor prod --dart-define-from-file=.env/.env.prod -t lib/main_prod.dart --release --obfuscate --split-debug-info=.obfuscation
```

### App Bundle Build
```bash
# Development
flutter build appbundle --flavor dev --dart-define-from-file=.env/.env.dev -t lib/main_dev.dart --release --obfuscate --split-debug-info=.obfuscation

# Staging  
flutter build appbundle --flavor stg --dart-define-from-file=.env/.env.stg -t lib/main_stg.dart --release --obfuscate --split-debug-info=.obfuscation

# Production
flutter build appbundle --flavor prod --dart-define-from-file=.env/.env.prod -t lib/main_prod.dart --release --obfuscate --split-debug-info=.obfuscation
```

## Android-Specific Configuration

### Flavor Configuration
Android flavors are configured in `android/app/build.gradle`:

```gradle
android {
    flavorDimensions "environment"
    productFlavors {
        dev {
            dimension "environment"
            applicationIdSuffix ".dev"
            versionNameSuffix "-dev"
            manifestPlaceholders = [appName: "Dcore Dev"]
        }
        stg {
            dimension "environment"
            applicationIdSuffix ".stg"
            versionNameSuffix "-stg"
            manifestPlaceholders = [appName: "Dcore Staging"]
        }
        prod {
            dimension "environment"
            manifestPlaceholders = [appName: "Dcore"]
        }
    }
}
```

### Signing Configuration
Production builds require proper signing:

```gradle
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### App Icons and Resources
Each flavor can have different icons and resources:

```
android/app/src/
├── dev/
│   ├── res/
│   │   └── mipmap-*/
│   │       └── ic_launcher.png
│   └── AndroidManifest.xml
├── stg/
│   ├── res/
│   │   └── mipmap-*/
│   │       └── ic_launcher.png
│   └── AndroidManifest.xml
└── prod/
    ├── res/
    │   └── mipmap-*/
    │       └── ic_launcher.png
    └── AndroidManifest.xml
```

## Firebase Integration

### Automatic Crashlytics Upload
Build scripts automatically upload debug symbols to Firebase Crashlytics:

```bash
echo "🔥 Uploading debug symbols to Firebase Crashlytics..."
FIREBASE_SETUP_SCRIPT="tools/macos/config/firebase_setup.sh"

if [[ -f "$FIREBASE_SETUP_SCRIPT" ]]; then
    "$FIREBASE_SETUP_SCRIPT" "$FLAVOR" "android"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Debug symbols uploaded successfully!"
    else
        echo "⚠️  Debug symbols upload failed, but APK build was successful."
    fi
fi
```

### Firebase Configuration Files
Each flavor uses its own Firebase configuration:

```
android/app/src/
├── dev/
│   └── google-services.json
├── stg/
│   └── google-services.json
└── prod/
    └── google-services.json
```

## Build Optimization

### ProGuard Configuration
Android builds use ProGuard for code optimization:

```proguard
# android/app/proguard-rules.pro
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Project specific rules
-keep class com.eup.meup.** { *; }
```

### Build Performance
Optimize build performance:

```gradle
android {
    compileSdkVersion 34
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    
    kotlinOptions {
        jvmTarget = '1.8'
    }
    
    buildTypes {
        release {
            shrinkResources true
            minifyEnabled true
        }
    }
}
```

## Testing and Distribution

### Local Testing
Test APKs locally:

```bash
# Install development APK
adb install build/app/outputs/flutter-apk/app-dev-release.apk

# Check installed app
adb shell pm list packages com.eup.meup
```

### Internal Testing
Use App Bundles for internal testing:
1. Upload `.aab` file to Google Play Console
2. Create internal testing track
3. Add test users
4. Distribute via Play Store

### Production Release
For production releases:
1. Build production App Bundle: `sh tools/macos/build/build_appbundle.sh prod`
2. Test thoroughly in staging environment
3. Upload to Google Play Console production track
4. Configure rollout percentage
5. Monitor crash reports and user feedback

## Troubleshooting

### Common Build Issues

#### Gradle Build Failures
```bash
# Clean Gradle cache
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

#### Signing Issues
```bash
# Verify keystore
keytool -list -v -keystore android/app/upload-keystore.jks
```

#### Flavor Configuration Issues
```bash
# Verify flavors
cd android
./gradlew tasks --all | grep assemble
```

### Debug Symbol Issues
If Crashlytics upload fails:
```bash
# Manual upload
firebase crashlytics:symbols:upload \
  --app=1:your-project-id:android:app-id \
  .obfuscation/
```

### Version Conflicts
Update version in `pubspec.yaml`:
```yaml
version: 1.0.19+20  # version+buildNumber
```

### Build Size Optimization
Analyze APK size:
```bash
# Use bundletool
java -jar bundletool.jar build-apks \
  --bundle=build/app/outputs/bundle/prodRelease/app-prod-release.aab \
  --output=meup.apks

# Analyze size
java -jar bundletool.jar get-size total \
  --apks=meup.apks
```

## Best Practices

### Build Process
- Always test builds on physical devices
- Use App Bundles for Play Store distribution
- Keep debug symbols for crash analysis
- Validate environment configurations before building

### Security
- Protect signing keys and passwords
- Use different package IDs for different flavors
- Enable ProGuard for release builds
- Regular security audits

### Performance
- Monitor APK/AAB size regularly
- Optimize images and assets
- Use appropriate compression
- Profile app performance

### Quality Assurance
- Test all flavors before release
- Verify Firebase integration
- Check crash-free users percentage
- Monitor performance metrics

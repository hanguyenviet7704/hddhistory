# App Bundle Generation

This document provides detailed instructions for building Android App Bundles in Dcore projects.

## Overview

Android App Bundle (AAB) is the recommended publishing format for Android apps on Google Play Store. App Bundles enable Dynamic Delivery, allowing Google Play to generate optimized APKs for each user's device configuration.

## App Bundle Build Script

### Primary Build Tool
**File**: `tools/macos/build/build_appbundle.sh`
**Purpose**: Generate Android App Bundles for Google Play Store distribution

### Basic Usage
```bash
# Build development App Bundle
sh tools/macos/build/build_appbundle.sh dev

# Build staging App Bundle
sh tools/macos/build/build_appbundle.sh stg

# Build production App Bundle
sh tools/macos/build/build_appbundle.sh prod
```

### Advanced Options
```bash
# Build with tree shaking disabled for icons
sh tools/macos/build/build_appbundle.sh dev --no-tree-shake-icons

# View help information
sh tools/macos/build/build_appbundle.sh --help
```

## Build Process Details

### Environment Mapping
The script automatically maps flavors to environment files:

| Flavor | Environment File | Target File | Purpose |
|--------|------------------|-------------|---------|
| `dev` | `.env/.env.dev` | `lib/main_dev.dart` | Development testing |
| `stg` | `.env/.env.stg` | `lib/main_stg.dart` | Staging/pre-production |
| `prod` | `.env/.env.prod` | `lib/main_prod.dart` | Production release |

### Build Command
The script executes:
```bash
fvm flutter build appbundle \
    --release \
    --obfuscate \
    --split-debug-info=".obfuscation" \
    --flavor "$FLAVOR" \
    --dart-define-from-file="$ENV_FILE" \
    -t "lib/main_$FLAVOR.dart"
```

### Build Features
- **Release Mode**: Optimized for production distribution
- **Code Obfuscation**: Protects intellectual property
- **Debug Symbols**: Separated for crash analysis
- **Environment Variables**: Loaded from `.env` files
- **Flavor Support**: Multi-environment builds
- **Dynamic Delivery**: Optimized app delivery

## Output Structure

### Generated Files Location
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

### Debug Symbols
Debug symbols are stored separately:
```
.obfuscation/
├── app.android-arm.symbols
├── app.android-arm64.symbols
├── app.android-x64.symbols
└── mapping.txt                    # ProGuard/R8 mapping file
```

## App Bundle Benefits

### Dynamic Delivery
- **Smaller Downloads**: Users download only what they need
- **Modular Features**: Features delivered on-demand
- **Asset Packs**: Large assets delivered separately
- **Configuration APKs**: Device-specific optimizations

### Google Play Optimization
- **Automatic APK Generation**: Play Store creates optimized APKs
- **Device Targeting**: Different APKs for different devices
- **Architecture Split**: Separate APKs for ARM, ARM64, x86
- **Language Split**: Users get only their selected languages

### Storage Efficiency
- **Reduced App Size**: Up to 15% smaller than universal APKs
- **On-Demand Resources**: Download resources as needed
- **Unused Code Removal**: R8 removes unused code paths
- **Asset Optimization**: Compress and optimize assets

## Manual Build Commands

For building without scripts or on other platforms:

### App Bundle Build Commands
```bash
# Development App Bundle
flutter build appbundle \
    --flavor dev \
    --dart-define-from-file=.env/.env.dev \
    -t lib/main_dev.dart \
    --release \
    --obfuscate \
    --split-debug-info=.obfuscation

# Staging App Bundle
flutter build appbundle \
    --flavor stg \
    --dart-define-from-file=.env/.env.stg \
    -t lib/main_stg.dart \
    --release \
    --obfuscate \
    --split-debug-info=.obfuscation

# Production App Bundle
flutter build appbundle \
    --flavor prod \
    --dart-define-from-file=.env/.env.prod \
    -t lib/main_prod.dart \
    --release \
    --obfuscate \
    --split-debug-info=.obfuscation
```

### Build Options
```bash
# Without obfuscation (for debugging)
flutter build appbundle --flavor dev --dart-define-from-file=.env/.env.dev -t lib/main_dev.dart --release

# With specific target SDK
flutter build appbundle --flavor prod --target-platform android-arm64 --dart-define-from-file=.env/.env.prod -t lib/main_prod.dart --release

# Analyze bundle size
flutter build appbundle --analyze-size --flavor prod --dart-define-from-file=.env/.env.prod -t lib/main_prod.dart --release
```

## App Bundle Configuration

### Android Configuration
App Bundle configuration in `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34

    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }

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

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### Dynamic Feature Modules
Configure dynamic features (if applicable):

```gradle
// In feature module build.gradle
apply plugin: 'com.android.dynamic-feature'

android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
    }
}

dependencies {
    implementation project(':app')
}
```

### Asset Pack Configuration
For large assets that should be delivered separately:

```gradle
// android/asset_packs/large_assets/build.gradle
apply plugin: 'com.android.asset-pack'

assetPack {
    packName = "large_assets"
    dynamicDelivery {
        deliveryType = "on-demand"
    }
}
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
        echo "⚠️  Debug symbols upload failed, but App Bundle build was successful."
        echo "You can manually upload later with: $FIREBASE_SETUP_SCRIPT $FLAVOR android"
    fi
fi
```

### Manual Symbol Upload
If automatic upload fails:

```bash
# Set Firebase project
firebase use meup-prod

# Upload symbols and mapping files
firebase crashlytics:symbols:upload \
  --app=1:your-project-id:android:your-app-id \
  .obfuscation/

# Verify upload
firebase crashlytics:symbols:list --app=1:your-project-id:android:your-app-id
```

## Testing App Bundles

### Local Testing with bundletool

#### Install bundletool
```bash
# Download bundletool
curl -L -o bundletool.jar \
  https://github.com/google/bundletool/releases/latest/download/bundletool-all-1.15.4.jar
```

#### Generate APK Set from Bundle
```bash
# Generate APK set for testing
java -jar bundletool.jar build-apks \
  --bundle=build/app/outputs/bundle/prodRelease/app-prod-release.aab \
  --output=meup-prod.apks \
  --ks=android/app/upload-keystore.jks \
  --ks-pass=pass:your-keystore-password \
  --ks-key-alias=upload \
  --key-pass=pass:your-key-password
```

#### Install on Device
```bash
# Install APK set on connected device
java -jar bundletool.jar install-apks --apks=meup-prod.apks

# Install for specific device
java -jar bundletool.jar install-apks \
  --apks=meup-prod.apks \
  --device-id=device-serial-number
```

#### Extract APKs for Analysis
```bash
# Extract APKs to directory
java -jar bundletool.jar extract-apks \
  --apks=meup-prod.apks \
  --output-dir=extracted-apks/
```

### Size Analysis

#### Analyze Bundle Size
```bash
# Get bundle size breakdown
java -jar bundletool.jar get-size total \
  --apks=meup-prod.apks

# Get size by device configuration
java -jar bundletool.jar get-size total \
  --apks=meup-prod.apks \
  --device-spec=device-spec.json

# Analyze by dimensions
java -jar bundletool.jar get-size breakdown \
  --apks=meup-prod.apks
```

#### Device Configuration Testing
```bash
# Generate device spec file
java -jar bundletool.jar get-device-spec \
  --output=device-spec.json

# Build APKs for specific device
java -jar bundletool.jar build-apks \
  --bundle=build/app/outputs/bundle/prodRelease/app-prod-release.aab \
  --output=meup-device-specific.apks \
  --device-spec=device-spec.json
```

## Google Play Store Integration

### Upload Process
1. **Build Production Bundle**: Use production build script
2. **Test Locally**: Use bundletool for local testing
3. **Upload to Play Console**: Upload AAB file to Google Play Console
4. **Internal Testing**: Create internal testing track
5. **Staged Rollout**: Release to percentage of users
6. **Full Release**: Release to all users after validation

### Play Console Configuration
```bash
# Upload App Bundle to Google Play Console
# This is typically done through the web interface or Play Console API

# Using Play Console Upload API (if configured)
curl -X POST \
  "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/your-package-name/edits/edit-id/bundles" \
  -H "Authorization: Bearer access-token" \
  -F "bundle=@build/app/outputs/bundle/prodRelease/app-prod-release.aab"
```

### Release Management
- **Internal Testing**: Test with team members
- **Closed Alpha**: Limited external testing
- **Open Beta**: Broader testing audience
- **Production**: Full release to all users

## Optimization Strategies

### Bundle Size Optimization
```gradle
android {
    buildTypes {
        release {
            // Enable resource shrinking
            shrinkResources true
            minifyEnabled true
            
            // Use ProGuard/R8 optimization
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            
            // Enable PNG crunching
            cruncherEnabled = true
            
            // Optimize PNGs
            cruncherProcesses = 0
        }
    }
}
```

### Asset Optimization
- **Image Compression**: Use WebP format for images
- **Vector Graphics**: Use SVG instead of multiple PNG sizes
- **Font Subsetting**: Include only used characters
- **Resource Removal**: Remove unused resources

### Code Optimization
- **Dead Code Elimination**: R8 removes unused code
- **Method Inlining**: Optimize method calls
- **Class Merging**: Reduce class count
- **String Optimization**: Optimize string resources

## Troubleshooting

### Common Build Issues

#### Bundle Build Failures
```bash
# Clean and rebuild
flutter clean
flutter pub get
sh tools/macos/build/build_appbundle.sh prod
```

#### Signing Issues
```bash
# Verify keystore
keytool -list -v -keystore android/app/upload-keystore.jks

# Check signing configuration
./gradlew :app:signingReport
```

#### Size Issues
```bash
# Analyze what's taking up space
flutter build appbundle --analyze-size --flavor prod

# Use bundletool for detailed analysis
java -jar bundletool.jar get-size breakdown --apks=meup-prod.apks
```

### Debug Commands
```bash
# Verbose build output
flutter build appbundle --verbose --flavor prod --dart-define-from-file=.env/.env.prod -t lib/main_prod.dart

# Check Gradle tasks
cd android
./gradlew tasks --all | grep bundle

# Validate bundle
java -jar bundletool.jar validate --bundle=build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

### Firebase Symbol Upload Issues
```bash
# Check Firebase CLI
firebase --version
firebase projects:list

# Manual upload with verbose output
firebase crashlytics:symbols:upload .obfuscation/ --verbose

# Check uploaded symbols
firebase crashlytics:symbols:list
```

## Best Practices

### Build Process
- Always test App Bundles before uploading to Play Store
- Use staging builds for pre-production testing
- Verify symbol upload for crash reporting
- Monitor bundle size regularly

### Optimization
- Enable resource shrinking and code minification
- Use appropriate image formats and compression
- Remove unused dependencies and resources
- Profile app startup and runtime performance

### Testing
- Test on multiple device configurations
- Use bundletool for local testing
- Verify dynamic delivery features work correctly
- Test with different network conditions

### Release Management
- Use staged rollouts for production releases
- Monitor crash reports and user feedback
- Keep debug symbols for crash analysis
- Maintain release notes and version tracking

### Security
- Protect signing keys and passwords
- Use upload keys instead of app signing keys
- Enable Google Play App Signing
- Regular security audits and updates